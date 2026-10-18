# Security model

Known AMM attacks and how Neura V1 handles each one.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

| Threat | Mitigation in V1 |
|---|---|
| Re-entrancy | `lock` modifier on every state-changing pool function |
| LP share inflation (first depositor) | 1,000 LP units permanently burned |
| Stable-pool dust initialisation | First stable deposit must be balanced; minimum $k$ |
| Sandwich / MEV | Surge fee on 2nd+ swap in a block; tight default slippage |
| Rounding exploits | All math rounds in the pool's favour; Newton solver ±1 wei checks |
| Fee-on-transfer tokens | Pool reads real balances; Router checks real received amount |
| Non-standard ERC-20 (no bool) | Low-level `call` accepting empty return data |
| Oracle manipulation | Price recorded before trades each block; use ≥30 min TWAP |
| Overflow | Solidity 0.8 checked math; reserves capped at uint112 |
| Admin abuse | No owner, no pause, no upgrade, immutable fees |
| Stale transactions | `deadline` on all Router calls |

## Known limits

- **Rebasing tokens** (balance changes without transfers) are not supported — use wrapped versions.
- A pool cannot protect against a **malicious token** contract; Neura AI flags unknown tokens.
- `skim` lets anyone collect donated excess; never send tokens directly to a pool.

## Before mainnet

Independent audits, a public bug bounty and invariant fuzz testing will be completed and published here before any deployment.
