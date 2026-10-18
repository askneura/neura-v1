# TWAP oracle

Volatile raw-reserve price cumulatives, observation units and consumer risks.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

For **volatile pools only**, a reserve update adds the prior raw reserve ratio times elapsed seconds to each cumulative field. The values use a 10^18 scale. Stable cumulative fields remain **zero**: a stable reserve ratio is not that curve's marginal price, so no stable oracle is supplied.

## Observation math

Take two valid observations at distinct timestamps. Divide their cumulative difference by elapsed seconds. For token0 priced in token1, convert from raw units to human units by multiplying by 10^(decimals0 - decimals1). Cumulative arithmetic and uint32 timestamps wrap; consumers need deliberate wrap-aware subtraction.

## Consumer requirements

Observations only advance when mint, burn, swap or sync updates the pool. An idle pool needs a reviewed counterfactual observation or a sync before reading; simply reading an old accumulator with the current clock gives a wrong average.

No observation collector, minimum window or production oracle consumer is supplied. Liquidity depth, depegs, manipulation costs, missing updates, wrap behavior and independent reference prices require separate analysis. A fixed 30-minute window is not a universal safety guarantee. Do not use stable fields or a single instantaneous observation to secure borrowing, liquidation or other funds.
