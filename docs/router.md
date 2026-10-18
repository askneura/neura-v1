# NeuraV1Router

Full source of the user-facing router.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Adds/removes liquidity at the optimal ratio and executes multi-hop exact-input swaps with deadlines and real-balance slippage checks.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20Minimal, INeuraV1Factory, INeuraV1Pool} from "./interfaces/INeuraV1.sol";
import {NeuraMath} from "./libraries/NeuraMath.sol";

/// @title Neura V1 Router
/// @notice User-facing entry point: add/remove liquidity and multi-hop swaps
///         with slippage limits and deadlines. Holds no funds between calls.
/// @dev    UNAUDITED. Not deployed.
contract NeuraV1Router {
    struct Route { address from; address to; bool stable; uint24 fee; }

    address public immutable factory;

    error Expired();
    error Slippage();
    error NoPool();

    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) revert Expired();
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function poolFor(Route memory r) public view returns (address p) {
        p = INeuraV1Factory(factory).getPool(r.from, r.to, r.stable, r.fee);
        if (p == address(0)) revert NoPool();
    }

    // ------------------------------------------------------------ liquidity
    function addLiquidity(
        address tokenA, address tokenB, bool stable, uint24 fee,
        uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin,
        address to, uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        address pool = poolFor(Route(tokenA, tokenB, stable, fee));
        (uint256 rA, uint256 rB) = _reserves(pool, tokenA);
        if (rA == 0 && rB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 bOptimal = (amountADesired * rB) / rA;
            if (bOptimal <= amountBDesired) {
                if (bOptimal < amountBMin) revert Slippage();
                (amountA, amountB) = (amountADesired, bOptimal);
            } else {
                uint256 aOptimal = (amountBDesired * rA) / rB;
                if (aOptimal < amountAMin) revert Slippage();
                (amountA, amountB) = (aOptimal, amountBDesired);
            }
        }
        _pull(tokenA, pool, amountA);
        _pull(tokenB, pool, amountB);
        liquidity = INeuraV1Pool(pool).mint(to);
    }

    function removeLiquidity(
        address tokenA, address tokenB, bool stable, uint24 fee,
        uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pool = poolFor(Route(tokenA, tokenB, stable, fee));
        INeuraV1Pool(pool).transferFrom(msg.sender, pool, liquidity);
        (uint256 a0, uint256 a1) = INeuraV1Pool(pool).burn(to);
        (amountA, amountB) = tokenA == INeuraV1Pool(pool).token0() ? (a0, a1) : (a1, a0);
        if (amountA < amountAMin || amountB < amountBMin) revert Slippage();
    }

    // ------------------------------------------------------------ swaps
    function getAmountsOut(uint256 amountIn, Route[] calldata routes) public view returns (uint256[] memory amounts) {
        amounts = new uint256[](routes.length + 1);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < routes.length; i++) {
            amounts[i + 1] = INeuraV1Pool(poolFor(routes[i])).getAmountOut(amounts[i], routes[i].from);
        }
    }

    /// @notice Exact-in swap. Measures the recipient's real balance change, so
    ///         fee-on-transfer tokens are handled and `amountOutMin` is honest.
    function swapExactTokensForTokens(
        uint256 amountIn, uint256 amountOutMin, Route[] calldata routes, address to, uint256 deadline
    ) external ensure(deadline) returns (uint256 received) {
        address last = routes[routes.length - 1].to;
        uint256 before = IERC20Minimal(last).balanceOf(to);
        _pull(routes[0].from, poolFor(routes[0]), amountIn);
        for (uint256 i = 0; i < routes.length; i++) {
            address pool = poolFor(routes[i]);
            (uint256 rIn,) = _reserves(pool, routes[i].from);
            uint256 actualIn = IERC20Minimal(routes[i].from).balanceOf(pool) - rIn;
            uint256 out = INeuraV1Pool(pool).getAmountOut(actualIn, routes[i].from);
            (uint256 o0, uint256 o1) = routes[i].from == INeuraV1Pool(pool).token0() ? (uint256(0), out) : (out, uint256(0));
            address next = i < routes.length - 1 ? poolFor(routes[i + 1]) : to;
            INeuraV1Pool(pool).swap(o0, o1, next, new bytes(0));
        }
        received = IERC20Minimal(last).balanceOf(to) - before;
        if (received < amountOutMin) revert Slippage();
    }

    // ------------------------------------------------------------ helpers
    function _reserves(address pool, address tokenA) internal view returns (uint256 rA, uint256 rB) {
        (uint112 r0, uint112 r1,) = INeuraV1Pool(pool).getReserves();
        (rA, rB) = tokenA == INeuraV1Pool(pool).token0() ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
    }

    function _pull(address token, address to, uint256 value) internal {
        (bool ok, bytes memory ret) = token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, msg.sender, to, value));
        require(ok && (ret.length == 0 || abi.decode(ret, (bool))), "transferFrom");
    }

    // silence unused import warning in some compilers
    function _min(uint256 a, uint256 b) internal pure returns (uint256) { return NeuraMath.min(a, b); }
}
```
