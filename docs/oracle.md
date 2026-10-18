# TWAP oracle

How every pool records a manipulation-resistant time-weighted average price.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Each pool accumulates price × time on the first action of every block:

$$
P_{\text{cum}}(t) = \sum_i P_i \cdot \Delta t_i
$$

Any contract can read the cumulative value at two times and compute the average:

$$
\text{TWAP}_{t_1 \to t_2} = \frac{P_{\text{cum}}(t_2) - P_{\text{cum}}(t_1)}{t_2 - t_1}
$$

Prices are scaled by $10^{18}$. Because the value is recorded **before** any trade in a block, moving the TWAP requires holding a distorted price across many blocks — expensive and visible. Use windows of at least 30 minutes for anything that secures money.
