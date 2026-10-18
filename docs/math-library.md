# NeuraMath & interfaces

Square root, stable invariant and Newton solver, plus interfaces.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

/// @title NeuraMath — integer math for Neura V1 pools
library NeuraMath {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// Babylonian square root (floor).
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// Stable invariant on 1e18-normalized amounts:  k = x^3*y + x*y^3
    function stableK(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 a = (x * y) / 1e18;
        uint256 b = (x * x) / 1e18 + (y * y) / 1e18;
        return (a * b) / 1e18;
    }

    /// d(k)/dy = 3*x*y^2 + x^3
    function _d(uint256 x, uint256 y) private pure returns (uint256) {
        return (3 * x * ((y * y) / 1e18)) / 1e18 + ((((x * x) / 1e18) * x) / 1e18);
    }

    /// Newton's method: find y such that stableK(x, y) == k, starting from `y`.
    /// Always rounds in the pool's favour.
    function stableGetY(uint256 x, uint256 k, uint256 y) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 kNow = stableK(x, y);
            if (kNow < k) {
                uint256 dy = ((k - kNow) * 1e18) / _d(x, y);
                if (dy == 0) {
                    if (kNow == k) return y;
                    if (stableK(x, y + 1) > k) return y + 1;
                    dy = 1;
                }
                y += dy;
            } else {
                uint256 dy = ((kNow - k) * 1e18) / _d(x, y);
                if (dy == 0) {
                    if (kNow == k || stableK(x, y - 1) < k) return y;
                    dy = 1;
                }
                y -= dy;
            }
        }
        revert("NeuraMath: no convergence");
    }
}
```

## Interfaces

```solidity
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
```
