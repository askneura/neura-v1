# Price impact and slippage

The difference between price impact and slippage, and how to set tolerance.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

**Price impact** is how much *your own trade* moves the price. **Slippage** is how much the price moves *between quoting and mining*.

## Price impact (volatile pool)

$$
\text{impact} = 1 - \frac{\Delta y / \Delta x}{y / x} = \frac{\Delta x'}{x + \Delta x'}
$$

| Trade size vs reserve in | Impact |
|---|---|
| 0.1% | ~0.1% |
| 1% | ~1% |
| 10% | ~9.1% |

## Slippage tolerance

$$
\text{amountOutMin} = \text{quote} \times (1 - s)
$$

The contract has no default tolerance. AI preview uses **0.5%** when none is supplied; this does not execute a trade. Neura AI warns above 2%, because a loose tolerance is exactly what sandwich bots look for.
