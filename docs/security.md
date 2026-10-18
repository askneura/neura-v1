# Security model

Known AMM attacks and how Neura V1 handles each one.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

**Unaudited reference code.** The mechanisms below are not guarantees against all attacks. See [testing](testing.md) for executable coverage.

| Threat | Mechanism and limits in V1 |
|---|---|
| Re-entrancy | `lock` modifier on every state-changing pool function |
| LP share inflation (first depositor) | 1,000 volatile units; decimal-aware larger stable lock |
| Stable-pool dust initialisation | Balanced first deposit; stable lock and post-update invariant floor |
| Sandwich / MEV | Surcharge on all later swaps; no bot detection or guaranteed protection |
| Rounding exploits | Bisection retains minimal safe reserve; bounded arithmetic and fuzz checks |
| Fee-on-transfer tokens | Pool reads real balances; Router checks real received amount |
| Non-standard ERC-20 (no bool) | Low-level `call` accepting empty return data |
| Oracle manipulation | Volatile raw-ratio cumulatives only; consumers need reviewed observations and risk controls |
| Overflow | Checked math, uint112 raw cap and 10^28 stable normalized cap |
| Admin abuse | No owner, no pause, no upgrade, immutable fees |
| Stale transactions | `deadline` on all Router calls |

## Known limits

- **Rebasing tokens** (balance changes without transfers) are not supported — use wrapped versions.
- A pool cannot protect against a **malicious token** contract; Neura AI flags unknown tokens.
- `skim` lets anyone collect donated excess; never send tokens directly to a pool.

## Before mainnet

Independent audits and a deployment review remain required. Local regression/fuzz tests are included, but formal verification and longer adversarial campaigns remain outstanding. No completed audit, bounty program or deployment date is claimed.
