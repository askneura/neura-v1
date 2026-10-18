# Stable curve (x³y + xy³ = k)

Why pegged assets need a flatter curve, the invariant and how it is solved on-chain.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

For assets that should trade near 1:1 (USDC/USDT, ETH/wstETH), constant product wastes liquidity on prices that never happen. The stable invariant is much flatter around the peg:

$$
x^3 y + x y^3 = k
$$

Amounts are first **normalized to 18 decimals**, so a 6-decimal USDC and an 18-decimal DAI compare fairly.

## Solving for the output

There is no closed form for $y$, so the pool uses Newton's method:

$$
y_{n+1} = y_n + \frac{k - f(x, y_n)}{f'(x, y_n)}, \qquad f'(x,y) = 3xy^2 + x^3
$$

It converges in a handful of iterations and **always rounds in the pool's favour** (see [NeuraMath](math-library.md)).

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

The first deposit into a stable pool **must be balanced** in normalized units, and $k$ must exceed a minimum. This blocks a known attack where a dust first deposit skews the curve.
