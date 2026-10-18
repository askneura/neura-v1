# Contract API reference

Entry points, argument meanings, return values and effects for V1 contracts.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Factory

| Entry point | Purpose / result |
|---|---|
| createPool(tokenA, tokenB, stable, fee) | Creates an undeployed local-reference pool; returns its address. Requires distinct nonzero contract tokens, supported metadata/fee and no duplicate. |
| getPool(tokenA, tokenB, stable, fee) | Sorted pair lookup; returns zero when absent. |
| allPools(index), allPoolsLength() | Pool enumeration and count. |
| feeEnabled(fee), surgeForFee(fee) | Fixed enabled tiers and same-block surcharge. |
| parameters() | Transient constructor parameters during creation; cleared afterwards. Not a pool registry. |

## Pool

| Entry point | Purpose / result |
|---|---|
| getReserves() | uint112 raw reserves and uint32 last update timestamp. |
| getAmountOut(amountIn, tokenIn) | Net output under currentFee; zero for zero input/empty reserves. Invalid tokens revert. |
| currentFee() | Fee in millionths for the next swap at the current block. |
| mint(to) | Accounts newly transferred balances; returns LP units. Low-level deposits have no slippage protection. |
| burn(to) | Burns LP tokens already sent to the pool and transfers the proportional tokens; returns amount0 and amount1. |
| swap(amount0Out, amount1Out, to, data) | Optimistic outputs, optional callback, balance-based fee-adjusted invariant enforcement. |
| skim(to), sync() | Collect excess or reconcile reserves with balances. Both are permissionless. |
| approve, transfer, transferFrom | LP-token allowance and transfers; the permanently locked address cannot spend shares. |
| price0CumulativeLast, price1CumulativeLast | Volatile raw-reserve-ratio cumulative observations only. Stable values remain zero. |

## Router

| Entry point | Purpose / result |
|---|---|
| poolFor(Route) | Resolve a pool or revert NoPool. |
| getAmountsOut(amountIn, Route[]) | Static quote per hop, returning array of input plus outputs. |
| addLiquidity(tokens, curve, fee, desiredAmounts, minima, to, deadline) | Select ratio, enforce both minima, pull tokens and mint LP; returns selected amounts and LP shares. |
| removeLiquidity(tokens, curve, fee, liquidity, minima, to, deadline) | Pull approved LP, burn, reorder outputs and enforce minima. |
| swapExactTokensForTokens(amountIn, amountOutMin, routes, to, deadline) | Connected, non-repeating route; returns recipient's real output-token balance increase. |

Read full [factory](factory.md), [pool](pool.md), [router](router.md) and [interfaces](math-library.md) source. This reference omits unsupported features deliberately: no exact-output swap, native-asset wrapping, LP permit, bridging, governance or upgrade controls.
