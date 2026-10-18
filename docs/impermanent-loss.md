# Impermanent loss

Why LPs can end up with less value than holding, with the formula and a table.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

If the price ratio changes by a factor $r$ since you deposited into a volatile pool, your position compared with simply holding is:

$$
\text{IL}(r) = \frac{2\sqrt{r}}{1 + r} - 1
$$

| Price change | IL |
|---|---|
| ×1.25 | −0.6% |
| ×1.5 | −2.0% |
| ×2 | −5.7% |
| ×3 | −13.4% |
| ×5 | −25.5% |

Fees earned offset this loss. It is "impermanent" because it disappears if the price returns — but becomes real when you withdraw.

**Stable pools** have very low IL as long as the peg holds. If a peg breaks, LPs end up holding mostly the weaker asset. Neura AI flags pegged pairs whose price has drifted.
