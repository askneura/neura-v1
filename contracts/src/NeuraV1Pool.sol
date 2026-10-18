// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20Minimal, INeuraV1Callee, INeuraV1Factory} from "./interfaces/INeuraV1.sol";
import {NeuraMath} from "./libraries/NeuraMath.sol";

/// @title Neura V1 Hybrid Pool
/// @notice One pool contract, two curves:
///         - Volatile: x * y >= k               (any token pair)
///         - Stable:   x^3*y + x*y^3 >= k       (correlated pairs, e.g. USDC/USDT)
///         plus a fee tier chosen at creation and a same-block "surge" fee that
///         charges later swaps in a block; this is not guaranteed MEV protection.
/// @dev    UNAUDITED. Not deployed. Reference implementation for the Neura docs.
contract NeuraV1Pool {
    // ---------------------------------------------------------------- LP token
    string public constant name = "Neura V1 LP";
    string public constant symbol = "NEURA-V1-LP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ---------------------------------------------------------------- config
    uint256 public constant MINIMUM_LIQUIDITY = 1_000;
    uint256 public constant FEE_DENOMINATOR = 1_000_000; // fees in pips (1e-6)
    uint256 public constant MAX_TOTAL_FEE = 10_000;      // 1.00% hard cap
    uint256 public constant MAX_NORMALIZED_RESERVE = 1e28;
    uint256 public constant MIN_STABLE_NORMALIZED_RESERVE = 1e15;

    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    bool public immutable stable;
    uint24 public immutable baseFee;   // e.g. 100 = 0.01%, 3000 = 0.30%
    uint24 public immutable surgeFee;  // extra fee for 2nd+ swap in the same block
    uint256 internal immutable decimals0;
    uint256 internal immutable decimals1;

    // ---------------------------------------------------------------- state
    uint112 public reserve0;
    uint112 public reserve1;
    uint32 public blockTimestampLast;
    uint256 public price0CumulativeLast; // TWAP oracle (UQ112x112 style, scaled 1e18)
    uint256 public price1CumulativeLast;
    uint256 public lastSwapBlock;
    uint256 private unlocked = 1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, uint256 feePips, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    error Locked();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutput();
    error InsufficientInput();
    error InsufficientLiquidity();
    error InvalidTo();
    error KInvariant();
    error Overflow();
    error TransferFailed();
    error UnsupportedDecimals();

    modifier lock() {
        if (unlocked != 1) revert Locked();
        unlocked = 2;
        _;
        unlocked = 1;
    }

    constructor() {
        (address t0, address t1, bool s, uint24 f, uint24 surge) = INeuraV1Factory(msg.sender).parameters();
        require(f + surge <= MAX_TOTAL_FEE, "fee");
        factory = msg.sender;
        (token0, token1, stable, baseFee, surgeFee) = (t0, t1, s, f, surge);
        uint8 d0 = IERC20Minimal(t0).decimals();
        uint8 d1 = IERC20Minimal(t1).decimals();
        if (d0 > 18 || d1 > 18) revert UnsupportedDecimals();
        decimals0 = 10 ** d0;
        decimals1 = 10 ** d1;
    }

    // ---------------------------------------------------------------- views
    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    /// @notice Fee (in pips) the next swap in this block will pay.
    function currentFee() public view returns (uint256) {
        return lastSwapBlock == block.number ? uint256(baseFee) + surgeFee : baseFee;
    }

    /// @notice Quote for routers / the Neura interface.
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256) {
        require(tokenIn == token0 || tokenIn == token1, "token");
        (uint256 r0, uint256 r1) = (reserve0, reserve1);
        if (amountIn == 0 || r0 == 0 || r1 == 0) return 0;
        if (amountIn > type(uint112).max) revert Overflow();
        amountIn -= (amountIn * currentFee()) / FEE_DENOMINATOR;
        return _amountOut(amountIn, tokenIn, r0, r1);
    }

    // ---------------------------------------------------------------- liquidity
    function mint(address to) external lock returns (uint256 liquidity) {
        if (to == address(0) || to == address(this)) revert InvalidTo();
        (uint256 r0, uint256 r1) = (reserve0, reserve1);
        uint256 b0 = IERC20Minimal(token0).balanceOf(address(this));
        uint256 b1 = IERC20Minimal(token1).balanceOf(address(this));
        _checkBalances(b0, b1);
        uint256 a0 = b0 - r0;
        uint256 a1 = b1 - r1;
        uint256 supply = totalSupply;
        if (supply == 0) {
            uint256 initial = NeuraMath.sqrt(a0 * a1);
            uint256 lockedLiquidity = MINIMUM_LIQUIDITY;
            if (stable) {
                // first deposit must be balanced in normalized units, otherwise the
                // stable invariant can be skewed by a dust first depositor.
                require((a0 * 1e18) / decimals0 == (a1 * 1e18) / decimals1, "stable: unbalanced init");
                require(_k(a0, a1) > MINIMUM_LIQUIDITY, "stable: k");
                // Keep the locked tail above the integer stable-invariant dust domain.
                lockedLiquidity = NeuraMath.sqrt(decimals0 * decimals1) * MIN_STABLE_NORMALIZED_RESERVE / 1e18;
                if (lockedLiquidity < MINIMUM_LIQUIDITY) lockedLiquidity = MINIMUM_LIQUIDITY;
            }
            if (initial <= lockedLiquidity) revert InsufficientLiquidityMinted();
            liquidity = initial - lockedLiquidity;
            _mint(address(0xdead), lockedLiquidity);
        } else {
            liquidity = NeuraMath.min((a0 * supply) / r0, (a1 * supply) / r1);
        }
        if (liquidity == 0) revert InsufficientLiquidityMinted();
        _mint(to, liquidity);
        _update(b0, b1, r0, r1);
        emit Mint(msg.sender, a0, a1, to);
    }

    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        if (to == address(0) || to == address(this) || to == token0 || to == token1) revert InvalidTo();
        (uint256 r0, uint256 r1) = (reserve0, reserve1);
        uint256 b0 = IERC20Minimal(token0).balanceOf(address(this));
        uint256 b1 = IERC20Minimal(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        uint256 supply = totalSupply;
        amount0 = (liquidity * b0) / supply;
        amount1 = (liquidity * b1) / supply;
        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
        _burn(address(this), liquidity);
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        b0 = IERC20Minimal(token0).balanceOf(address(this));
        b1 = IERC20Minimal(token1).balanceOf(address(this));
        _update(b0, b1, r0, r1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // ---------------------------------------------------------------- swap
    /// @notice Low-level swap. Optimistically sends outputs, optionally calls
    ///         back `to` (flash swap), then enforces the invariant after fees.
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutput();
        (uint256 r0, uint256 r1) = (reserve0, reserve1);
        if (amount0Out >= r0 || amount1Out >= r1) revert InsufficientLiquidity();
        if (to == address(0) || to == address(this) || to == token0 || to == token1) revert InvalidTo();

        uint256 feePips = currentFee();
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        if (data.length > 0) INeuraV1Callee(to).neuraV1Call(msg.sender, amount0Out, amount1Out, data);

        uint256 b0 = IERC20Minimal(token0).balanceOf(address(this));
        uint256 b1 = IERC20Minimal(token1).balanceOf(address(this));
        uint256 in0 = b0 > r0 - amount0Out ? b0 - (r0 - amount0Out) : 0;
        uint256 in1 = b1 > r1 - amount1Out ? b1 - (r1 - amount1Out) : 0;
        _checkBalances(b0, b1);
        if (in0 == 0 && in1 == 0) revert InsufficientInput();

        // invariant is checked on balances minus the fee taken from the input side
        uint256 adj0 = b0 - (in0 * feePips) / FEE_DENOMINATOR;
        uint256 adj1 = b1 - (in1 * feePips) / FEE_DENOMINATOR;
        if (_k(adj0, adj1) < _k(r0, r1)) revert KInvariant();

        lastSwapBlock = block.number;
        _update(b0, b1, r0, r1);
        emit Swap(msg.sender, in0, in1, amount0Out, amount1Out, feePips, to);
    }

    /// @notice Send donated / excess tokens out so balances match reserves.
    function skim(address to) external lock {
        _safeTransfer(token0, to, IERC20Minimal(token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(token1, to, IERC20Minimal(token1).balanceOf(address(this)) - reserve1);
    }

    /// @notice Force reserves to match balances.
    function sync() external lock {
        _update(IERC20Minimal(token0).balanceOf(address(this)), IERC20Minimal(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // ---------------------------------------------------------------- math
    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        if (!stable) return x * y;
        uint256 _x = (x * 1e18) / decimals0;
        uint256 _y = (y * 1e18) / decimals1;
        return NeuraMath.stableK(_x, _y);
    }

    function _amountOut(uint256 amountIn, address tokenIn, uint256 r0, uint256 r1) internal view returns (uint256) {
        bool zeroForOne = tokenIn == token0;
        require(zeroForOne || tokenIn == token1, "token");
        if (!stable) {
            (uint256 vIn, uint256 vOut) = zeroForOne ? (r0, r1) : (r1, r0);
            return (amountIn * vOut) / (vIn + amountIn);
        }
        uint256 xy = _k(r0, r1);
        uint256 n0 = (r0 * 1e18) / decimals0;
        uint256 n1 = (r1 * 1e18) / decimals1;
        (uint256 rIn, uint256 rOut, uint256 dIn, uint256 dOut) = zeroForOne ? (n0, n1, decimals0, decimals1) : (n1, n0, decimals1, decimals0);
        uint256 x = rIn + (amountIn * 1e18) / dIn;
        if (x > MAX_NORMALIZED_RESERVE) revert Overflow();
        uint256 y = rOut - NeuraMath.stableGetY(x, xy, rOut);
        return (y * dOut) / 1e18;
    }

    function _update(uint256 b0, uint256 b1, uint256 r0, uint256 r1) private {
        _checkBalances(b0, b1);
        if (stable && totalSupply > 0 && _k(b0, b1) <= MINIMUM_LIQUIDITY) revert KInvariant();
        uint32 ts = uint32(block.timestamp);
        unchecked {
            uint32 elapsed = ts - blockTimestampLast;
            // Stable reserve ratios are not the curve's marginal prices. Do not
            // expose them as an oracle: stable cumulative fields remain zero.
            if (!stable && elapsed > 0 && r0 != 0 && r1 != 0) {
                price0CumulativeLast += ((r1 * 1e18) / r0) * elapsed;
                price1CumulativeLast += ((r0 * 1e18) / r1) * elapsed;
            }
        }
        reserve0 = uint112(b0);
        reserve1 = uint112(b1);
        blockTimestampLast = ts;
        emit Sync(reserve0, reserve1);
    }

    function _checkBalances(uint256 b0, uint256 b1) private view {
        if (b0 > type(uint112).max || b1 > type(uint112).max) revert Overflow();
        if (stable && ((b0 * 1e18) / decimals0 > MAX_NORMALIZED_RESERVE || (b1 * 1e18) / decimals1 > MAX_NORMALIZED_RESERVE)) revert Overflow();
    }

    // ---------------------------------------------------------------- ERC20
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        if (a != type(uint256).max) allowance[from][msg.sender] = a - value;
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        if (to == address(0) || from == address(0xdead)) revert InvalidTo();
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) private {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) private {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool ok, bytes memory ret) = token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        if (!ok || (ret.length != 0 && !abi.decode(ret, (bool)))) revert TransferFailed();
    }
}
