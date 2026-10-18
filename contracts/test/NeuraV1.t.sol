// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {NeuraV1Factory} from "../src/NeuraV1Factory.sol";
import {NeuraV1Pool} from "../src/NeuraV1Pool.sol";
import {NeuraV1Router} from "../src/NeuraV1Router.sol";
import {NeuraMath} from "../src/libraries/NeuraMath.sol";

interface Vm {
    function expectRevert(bytes4) external;
    function expectRevert() external;
    function roll(uint256) external;
    function warp(uint256) external;
    function prank(address) external;
}

contract MockToken {
    uint8 public immutable decimals;
    uint256 public tax;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    constructor(uint8 d) { decimals = d; }
    function mint(address to, uint256 n) external { balanceOf[to] += n; }
    function setTax(uint256 n) external { tax = n; }
    function approve(address to, uint256 n) external returns (bool) { allowance[msg.sender][to] = n; return true; }
    function transfer(address to, uint256 n) external returns (bool) { _move(msg.sender, to, n); return true; }
    function transferFrom(address from, address to, uint256 n) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) allowance[from][msg.sender] -= n;
        _move(from, to, n); return true;
    }
    function _move(address from, address to, uint256 n) internal {
        balanceOf[from] -= n; balanceOf[to] += n - n * tax / 10_000;
    }
}

contract FlashBorrower {
    NeuraV1Pool public pool;
    bool public reentryBlocked;
    bool public repay;
    constructor(NeuraV1Pool p) { pool = p; }
    function run(uint256 amount, bool pay) external { repay = pay; pool.swap(amount, 0, address(this), hex"01"); }
    function neuraV1Call(address, uint256 amount, uint256, bytes calldata) external {
        require(msg.sender == address(pool), "caller");
        (bool ok,) = address(pool).call(abi.encodeCall(pool.sync, ()));
        reentryBlocked = !ok;
        if (repay) {
            uint256 total = (amount * 1_000_000 + (1_000_000 - pool.currentFee()) - 1) / (1_000_000 - pool.currentFee());
            MockToken(pool.token0()).transfer(address(pool), total);
        }
    }
}

contract NeuraV1Test {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    NeuraV1Factory factory;
    NeuraV1Router router;
    MockToken a;
    MockToken b;
    NeuraV1Pool pool;

    function setUp() public {
        factory = new NeuraV1Factory(); router = new NeuraV1Router(address(factory));
        a = new MockToken(18); b = new MockToken(18);
        a.mint(address(this), 1e30); b.mint(address(this), 1e30);
        a.approve(address(router), type(uint256).max); b.approve(address(router), type(uint256).max);
        pool = NeuraV1Pool(factory.createPool(address(a), address(b), false, 3000));
        router.addLiquidity(address(a), address(b), false, 3000, 100e18, 100e18, 100e18, 100e18, address(this), block.timestamp);
    }
    function route() internal view returns (NeuraV1Router.Route[] memory r) {
        r = new NeuraV1Router.Route[](1); r[0] = NeuraV1Router.Route(address(a), address(b), false, 3000);
    }
    function testFactorySortsAndRejectsDuplicates() public {
        require(factory.getPool(address(b), address(a), false, 3000) == address(pool));
        vm.expectRevert(); factory.createPool(address(b), address(a), false, 3000);
    }
    function testAllFeeTiersAreFixedAndCapped() public view {
        require(factory.feeEnabled(100) && factory.surgeForFee(100) == 400);
        require(factory.feeEnabled(500) && factory.surgeForFee(500) == 1000);
        require(factory.feeEnabled(3000) && factory.surgeForFee(3000) == 2500);
        require(factory.feeEnabled(10000) && factory.surgeForFee(10000) == 0);
        require(!factory.feeEnabled(200));
    }
    function testRejectsTokenWithoutCodeAndUnsupportedDecimals() public {
        vm.expectRevert(); factory.createPool(address(a), address(42), false, 100);
        MockToken high = new MockToken(19);
        vm.expectRevert(NeuraV1Pool.UnsupportedDecimals.selector); factory.createPool(address(a), address(high), true, 100);
    }
    function testExactInputQuoteAndReserveInvariant() public {
        uint256 quote = pool.getAmountOut(1e18, address(a));
        require(quote == (uint256(997e15) * 100e18) / (100e18 + 997e15));
        uint256 before = b.balanceOf(address(this));
        uint256 received = router.swapExactTokensForTokens(1e18, quote, route(), address(this), block.timestamp);
        require(received == quote && b.balanceOf(address(this)) - before == quote);
        require(uint256(pool.reserve0()) * pool.reserve1() >= 100e18 * 100e18);
    }
    function testSurgeAppliesToEveryLaterSwapAndResets() public {
        require(pool.currentFee() == 3000);
        router.swapExactTokensForTokens(1e18, 0, route(), address(this), block.timestamp);
        require(pool.currentFee() == 5500);
        router.swapExactTokensForTokens(1e18, 0, route(), address(this), block.timestamp);
        require(pool.currentFee() == 5500);
        vm.roll(block.number + 1); require(pool.currentFee() == 3000);
    }
    function testSwapMinimumAndDeadlineRevertAtomically() public {
        uint256 before = a.balanceOf(address(this));
        vm.expectRevert(NeuraV1Router.Slippage.selector);
        router.swapExactTokensForTokens(1e18, 2e18, route(), address(this), block.timestamp);
        require(a.balanceOf(address(this)) == before);
        vm.warp(100);
        vm.expectRevert(NeuraV1Router.Expired.selector);
        router.swapExactTokensForTokens(1e18, 0, route(), address(this), 99);
    }
    function testLiquidityMinimumBothBranchesAndEmptyPool() public {
        vm.expectRevert(NeuraV1Router.Slippage.selector);
        router.addLiquidity(address(a), address(b), false, 3000, 1e18, 1e18, 2e18, 0, address(this), block.timestamp);
        vm.expectRevert(NeuraV1Router.Slippage.selector);
        router.addLiquidity(address(a), address(b), false, 3000, 2e18, 1e18, 0, 2e18, address(this), block.timestamp);
        factory.createPool(address(a), address(b), false, 500);
        vm.expectRevert(NeuraV1Router.Slippage.selector);
        router.addLiquidity(address(a), address(b), false, 500, 1e18, 1e18, 2e18, 0, address(this), block.timestamp);
    }
    function testEmptyDiscontinuousAndRepeatedRoutesRejected() public {
        NeuraV1Router.Route[] memory empty = new NeuraV1Router.Route[](0);
        vm.expectRevert(NeuraV1Router.InvalidRoute.selector); router.getAmountsOut(1e18, empty);
        NeuraV1Router.Route[] memory r = new NeuraV1Router.Route[](2);
        r[0] = route()[0]; r[1] = route()[0];
        vm.expectRevert(NeuraV1Router.InvalidRoute.selector); router.getAmountsOut(1e18, r);
        r[1] = NeuraV1Router.Route(address(b), address(a), false, 3000);
        vm.expectRevert(NeuraV1Router.InvalidRoute.selector); router.getAmountsOut(1e18, r);
    }
    function testMultiHopQuoteMatchesReceived() public {
        MockToken c = new MockToken(18); c.mint(address(this), 1e24); c.approve(address(router), type(uint256).max);
        factory.createPool(address(b), address(c), false, 500);
        router.addLiquidity(address(b), address(c), false, 500, 100e18, 100e18, 0, 0, address(this), block.timestamp);
        NeuraV1Router.Route[] memory r = new NeuraV1Router.Route[](2);
        r[0] = route()[0]; r[1] = NeuraV1Router.Route(address(b), address(c), false, 500);
        uint256[] memory quotes = router.getAmountsOut(1e18, r);
        require(router.swapExactTokensForTokens(1e18, quotes[2], r, address(this), block.timestamp) == quotes[2]);
    }
    function testTransferTaxUsesActualRecipientDelta() public {
        a.setTax(100); b.setTax(200);
        uint256 before = b.balanceOf(address(this));
        uint256 quote = pool.getAmountOut(99e16, address(a));
        uint256 expected = quote - quote * 200 / 10000;
        uint256 received = router.swapExactTokensForTokens(1e18, expected, route(), address(this), block.timestamp);
        require(received == expected && b.balanceOf(address(this)) - before == expected);
    }
    function testLiquidityBurnAndLockedMinimum() public {
        require(pool.balanceOf(address(0xdead)) == 1000);
        pool.approve(address(router), type(uint256).max);
        router.removeLiquidity(address(a), address(b), false, 3000, pool.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
        require(pool.totalSupply() == 1000);
        vm.prank(address(0xdead)); vm.expectRevert(NeuraV1Pool.InvalidTo.selector); pool.transfer(address(this), 1000);
    }
    function testFlashRepaymentAndReentryGuard() public {
        FlashBorrower borrower = new FlashBorrower(pool);
        MockToken(pool.token0()).mint(address(borrower), 1e18);
        borrower.run(1e18, true); require(borrower.reentryBlocked());
        vm.expectRevert(NeuraV1Pool.InsufficientInput.selector); borrower.run(1e18, false);
    }
    function testCumulativeRawReservePrice() public {
        vm.warp(block.timestamp + 60); pool.sync();
        require(pool.price0CumulativeLast() == 60e18 && pool.price1CumulativeLast() == 60e18);
    }
    function testStableMixedDecimalsAndBalancedInitialization() public {
        MockToken six = new MockToken(6); six.mint(address(this), 1e14); six.approve(address(router), type(uint256).max);
        NeuraV1Pool stablePool = NeuraV1Pool(factory.createPool(address(six), address(b), true, 100));
        vm.expectRevert();
        router.addLiquidity(address(six), address(b), true, 100, 1000e6, 999e18, 0, 0, address(this), block.timestamp);
        router.addLiquidity(address(six), address(b), true, 100, 1000e6, 1000e18, 0, 0, address(this), block.timestamp);
        uint256 out = stablePool.getAmountOut(1e6, address(six));
        require(out > 999e15 && out <= 1e18);
        six.transfer(address(stablePool), 1e6);
        if (stablePool.token0() == address(six)) stablePool.swap(0, out, address(this), "");
        else stablePool.swap(out, 0, address(this), "");
    }
    function testStableBoundsRejectOverflowBeforeArithmetic() public {
        NeuraV1Pool s = NeuraV1Pool(factory.createPool(address(a), address(b), true, 100));
        a.transfer(address(s), 1e28 + 1); b.transfer(address(s), 1e28 + 1);
        vm.expectRevert(NeuraV1Pool.Overflow.selector); s.mint(address(this));
    }
    function testStableBurnCannotCreateZeroInvariantDrain() public {
        NeuraV1Pool s = NeuraV1Pool(factory.createPool(address(a), address(b), true, 100));
        router.addLiquidity(address(a), address(b), true, 100, 1e16, 1e16, 0, 0, address(this), block.timestamp);
        s.approve(address(router), type(uint256).max);
        router.removeLiquidity(address(a), address(b), true, 100, s.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
        require(NeuraMath.stableK(s.reserve0(), s.reserve1()) > 1000);
        uint256 quote = s.getAmountOut(1, address(a));
        if (quote > 0) {
            a.transfer(address(s), 1);
            if (s.token0() == address(a)) s.swap(0, quote, address(this), "");
            else s.swap(quote, 0, address(this), "");
        }
        require(NeuraMath.stableK(s.reserve0(), s.reserve1()) > 1000);
    }
    function testStableSixDecimalPairsAndNoMisleadingOracle() public {
        MockToken sixA = new MockToken(6); MockToken sixB = new MockToken(6);
        sixA.mint(address(this), 1000e6); sixB.mint(address(this), 1000e6);
        sixA.approve(address(router), type(uint256).max); sixB.approve(address(router), type(uint256).max);
        NeuraV1Pool s = NeuraV1Pool(factory.createPool(address(sixA), address(sixB), true, 100));
        router.addLiquidity(address(sixA), address(sixB), true, 100, 1000e6, 1000e6, 0, 0, address(this), block.timestamp);
        require(s.balanceOf(address(0xdead)) == 1000);
        uint256 quote = s.getAmountOut(1e6, address(sixA));
        require(quote > 999000 && quote < 1000000);
        vm.warp(block.timestamp + 60); s.sync();
        require(s.price0CumulativeLast() == 0 && s.price1CumulativeLast() == 0);
    }
    function testFuzzStableQuotedSwapsExecuteAndPreserveK(uint96 seed) public {
        NeuraV1Pool s = NeuraV1Pool(factory.createPool(address(a), address(b), true, 100));
        router.addLiquidity(address(a), address(b), true, 100, 1000e18, 1000e18, 0, 0, address(this), block.timestamp);
        uint256 input = uint256(seed) % 1000e18 + 1e12;
        uint256 beforeK = NeuraMath.stableK(s.reserve0(), s.reserve1());
        uint256 quote = s.getAmountOut(input, address(a));
        NeuraV1Router.Route[] memory r = new NeuraV1Router.Route[](1);
        r[0] = NeuraV1Router.Route(address(a), address(b), true, 100);
        require(router.swapExactTokensForTokens(input, quote, r, address(this), block.timestamp) == quote);
        require(NeuraMath.stableK(s.reserve0(), s.reserve1()) >= beforeK);
    }
    function testFuzzVolatileSwapsPreserveK(uint96 seed) public {
        uint256 input = uint256(seed) % 100e18 + 1e12;
        uint256 quote = pool.getAmountOut(input, address(a));
        uint256 received = router.swapExactTokensForTokens(input, quote, route(), address(this), block.timestamp);
        require(received == quote && uint256(pool.reserve0()) * pool.reserve1() >= 100e18 * 100e18);
    }
    function testFuzzStableSolverReturnsMinimalSafeReserve(uint96 xSeed, uint96 ySeed, uint96 inSeed) public pure {
        uint256 x = uint256(xSeed) % 1e24 + 1e18;
        uint256 y = uint256(ySeed) % 1e24 + 1e18;
        uint256 dx = uint256(inSeed) % 1e24 + 1;
        uint256 k = NeuraMath.stableK(x, y);
        uint256 solved = NeuraMath.stableGetY(x + dx, k, y);
        require(NeuraMath.stableK(x + dx, solved) >= k);
        require(solved == 0 || NeuraMath.stableK(x + dx, solved - 1) < k);
    }
}