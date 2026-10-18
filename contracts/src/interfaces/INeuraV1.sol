// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

interface IERC20Minimal {
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
}

interface INeuraV1Callee {
    function neuraV1Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface INeuraV1Factory {
    function parameters() external view returns (address token0, address token1, bool stable, uint24 baseFee, uint24 surgeFee);
    function getPool(address tokenA, address tokenB, bool stable, uint24 baseFee) external view returns (address);
}

interface INeuraV1Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function stable() external view returns (bool);
    function getReserves() external view returns (uint112, uint112, uint32);
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);
    function mint(address to) external returns (uint256);
    function burn(address to) external returns (uint256, uint256);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
}
