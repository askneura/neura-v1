# Fees and the surge fee

Fee tiers, the same-block surge fee that defends against sandwich attacks, and who earns what.

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

## Surge fee — Neura's anti-sandwich rule

A sandwich attack needs at least two swaps in the same block around yours. Neura charges:

$$
\text{fee} = \begin{cases} \text{base} & \text{first swap in a block} \\ \text{base} + \text{surge} & \text{every later swap in the same block} \end{cases}
$$

```text
 block N:  bot buy  ──▶  your swap  ──▶  bot sell
           base fee      base+surge      base+surge
```

The bot's back-run pays the surge, which wipes out the profit on most small and medium trades. Normal users, who almost never trade twice in the same block, pay just the base fee. Arbitrageurs still keep prices aligned — they simply pay LPs more for it.

## Who earns fees

100% of swap fees go to liquidity providers. There is **no protocol fee** in V1.
