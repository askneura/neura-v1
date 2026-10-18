# Testing and validation

Reproducible Solidity regression and fuzz checks, plus what remains unverified.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Run locally

```bash
forge test -vv
forge test --match-test testFuzz -vv
forge test --gas-report
```

The public repository ships self-contained Solidity fixtures and a GitHub Actions workflow. CI compiles and executes the same tests on pull requests and main-branch pushes. It has read-only repository permissions and needs no secrets or funded wallet.

## Current test scope

- Sorted pool lookup, duplicate/token-code/decimal rejection and the four fixed fee tiers.
- Exact-input quote/execution and fee-adjusted constant-product preservation.
- Same-block surcharge application and next-block reset.
- Swap slippage/deadline atomic rollback and both liquidity minima in every selection branch.
- Empty/disconnected/repeated-pool route rejection and multi-hop receipt checks.
- Simple input/output transfer-tax balance handling.
- LP withdrawal and permanent locked-share enforcement.
- Flash repayment, missing repayment and same-pool reentry rejection.
- Volatile cumulative raw-reserve price updates.
- Mixed-decimal balanced stable initialization, stable quote/execution and reserve-domain rejection.
- Regression against burning a stable pool into a zero-invariant dust state.
- 256 generated cases per fuzz test for volatile swaps and minimal safe stable solver output.

## Not an audit

These are bounded tests, not proof against all attacks. Formal verification, independent audits, broader malicious-token scenarios, economic/MEV analysis, long sequence invariant campaigns, gas benchmarking and production deployment review remain outstanding. There is no claim of zero bugs or guaranteed returns.
