# Developer guide

## Source layout
- `contracts/src/NeuraV1Factory.sol`: permissionless pool creation.
- `contracts/src/NeuraV1Pool.sol`: reserves, LP accounting, swaps and cumulative prices.
- `contracts/src/NeuraV1Router.sol`: liquidity operations and exact-input routes.
- `contracts/src/libraries/NeuraMath.sol`: invariant arithmetic.
- `contracts/src/interfaces/INeuraV1.sol`: contract interfaces.

## Compile and test locally
Install Foundry from its official distribution, then run `forge build`, `forge test -vv` and `forge test --match-test testFuzz -vv`. Configuration pins Solidity 0.8.28, optimization at 200 runs, via-IR and the Paris EVM target. Self-contained mocks use no RPC, wallet or private key. See [validation scope](docs/testing.md).

## Local deployment simulation
Run `forge script contracts/script/DeployNeuraV1.s.sol:DeployNeuraV1` without broadcast flags. This deploys Factory and Router(factory) inside a local simulation only. Local output addresses are not official contracts. See [deployment preparation](docs/deployment-guide.md).

## Source provenance
Each Git commit identifies a reference snapshot, not an audited release. Contract changes and documentation originate in Neura's private workspace and are published through an explicit contract/test/documentation allowlist. No website implementation, generated build artifacts or private history is exported. Compare the contract source and compiler settings at the exact commit used for a build.

## Required validation before deployment
Add unit, integration, invariant and fuzz tests covering both curves, different token decimals, initialization, rounding, reserve limits, callback repayment, liquidity accounting, same-block fees and malicious/non-standard tokens. Review every router path and oracle consumer. Complete independent audits and publish findings before considering any funds-bearing deployment.

Local mock trades, regressions, fuzz tests, deployment simulation and CI configuration are included. No live funded trades, independent audit report or production deployment is claimed. This public repository remains separate from the private website repository.
