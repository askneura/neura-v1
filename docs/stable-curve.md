# Stable curve (x³y + xy³ = k)

Why pegged assets need a flatter curve, the invariant and how it is solved on-chain.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

For assets expected to trade near 1:1 (for example USDC/USDT), constant product wastes liquidity on prices that never happen. The stable invariant is much flatter around the peg:

$$
x^3 y + x y^3 = k
$$

Amounts are first **normalized to 18 decimals**, so a 6-decimal USDC and an 18-decimal DAI compare fairly.

## Solving for the output

The implementation solves the integer invariant with bounded bisection. The derivative explains the curve, but is not the executable solver:

$$
y_{n+1} = y_n + \frac{k - f(x, y_n)}{f'(x, y_n)}, \qquad f'(x,y) = 3xy^2 + x^3
$$

Bisection selects the smallest retained output reserve whose integer invariant meets the target. Stable normalized reserves are bounded at 10^28; this costs more iterations than Newton but avoids zero derivatives and overshoot. See [NeuraMath](math-library.md) and [compatibility](token-compatibility.md).

## Volatile vs stable, same liquidity

```text
 price
   │ volatile  ╲
   │            ╲__
   │ stable  ──────────────╮
   │                        ╲___
   └──────────────────────────────── amount swapped
```

Near the peg the stable curve gives far less slippage; far from it, slippage rises sharply so the pool cannot be drained at a bad price.

## Safety rule

The first deposit into a stable pool **must be balanced** in normalized units, and $k$ must exceed a minimum. Initialization alone is insufficient: stable LP locking uses a decimal-aware normalized floor, and post-update invariant must remain above 1,000, including after burns. These are tested boundaries, not a guarantee against all attacks.
