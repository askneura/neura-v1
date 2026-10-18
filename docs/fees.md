# Fees and the surge fee

Fixed fee tiers, the same-block surcharge, fee recipients and economic limits.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Fees are measured in **pips** (1 pip = 0.0001%). They are taken from the input token and stay in the pool, so they automatically grow every LP's share.

## Fee tiers

| Tier | Base fee | Surge (extra) | Typical pairs |
|---|---|---|---|
| 100 | 0.01% | +0.04% | Stablecoins, liquid staking |
| 500 | 0.05% | +0.10% | Blue chips (ETH/USDC) |
| 3000 | 0.30% | +0.25% | Most pairs |
| 10000 | 1.00% | — | Exotic / new tokens |

Total fee is hard-capped at **1%** in the contract. Fee tiers are fixed at deployment; **no one can change a pool's fee afterwards**.

## Same-block surcharge — scope and limits

A sandwich attack needs at least two swaps in the same block around yours. Neura charges:

$$
\text{fee} = \begin{cases} \text{base} & \text{first swap in a block} \\ \text{base} + \text{surge} & \text{every later swap in the same block} \end{cases}
$$

```text
 block N:  bot buy  ──▶  your swap  ──▶  bot sell
           base fee      base+surge      base+surge
```

The surcharge applies to **every later swap in that pool**, even when a different ordinary user submits it. The contract cannot identify a bot or guarantee an unprofitable sandwich. Quotes can become stale if an earlier swap is mined first; user-approved minima remain essential.

## Who earns fees

100% of swap fees go to liquidity providers. There is **no protocol fee** in V1.
