# Developer guide

## Source layout
- `contracts/src/NeuraV1Factory.sol`: permissionless pool creation.
- `contracts/src/NeuraV1Pool.sol`: reserves, LP accounting, swaps and cumulative prices.
- `contracts/src/NeuraV1Router.sol`: liquidity operations and exact-input routes.
- `contracts/src/libraries/NeuraMath.sol`: invariant arithmetic.
- `contracts/src/interfaces/INeuraV1.sol`: contract interfaces.

## Compile locally
Install Foundry from its official distribution, then run `forge build`. The included configuration pins Solidity 0.8.28. No wallet, API key, private key or production connection is required for compilation. Compilation alone does not establish safety.

## Required validation before deployment
Add unit, integration, invariant and fuzz tests covering both curves, different token decimals, initialization, rounding, reserve limits, callback repayment, liquidity accounting, same-block fees and malicious/non-standard tokens. Review every router path and oracle consumer. Complete independent audits and publish findings before considering any funds-bearing deployment.

No deployment script, funded-trade tests or completed audit report is included. This public repository is intentionally separate from the private website repository.
