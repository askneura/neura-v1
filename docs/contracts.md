# Contract architecture

How the Factory, Pool, Router and math library fit together.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

```text
                         ┌────────────────────┐
         createPool ───▶ │   NeuraV1Factory   │  fee tiers (immutable)
                         └─────────┬──────────┘
                                   │ CREATE2
                                   ▼
   user ──▶ NeuraV1Router ──▶ NeuraV1Pool (LP token + reserves + oracle)
              │  deadlines         │  uses
              │  slippage          ▼
              │  multi-hop     NeuraMath (sqrt, stable invariant, Newton)
              ▼
         your wallet
```

| Contract | Role | Holds funds? | Upgradeable? |
|---|---|---|---|
| NeuraV1Factory | Creates pools, fixes fee tiers | No | No |
| NeuraV1Pool | Reserves, swaps, LP token, TWAP | **Yes** | No |
| NeuraV1Router | Safe user entry point | No | No |
| NeuraMath | Pure math library | No | No |

- Solidity **0.8.28** (checked arithmetic by default)
- No owner, no pause, no proxy — the code you read is the code that runs
- Licence: BUSL-1.1

> Reference implementation — **unaudited, not deployed.**
