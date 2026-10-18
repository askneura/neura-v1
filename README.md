# Neura V1

Neura's public liquidity-protocol reference source and documentation.

**Unaudited. Not deployed. Not ready for real funds.** Swap and Pools are coming soon. This repository does not include the Neura website, private services, user records or credentials.

[![Contract checks](https://github.com/askneura/neura-v1/actions/workflows/contracts.yml/badge.svg)](https://github.com/askneura/neura-v1/actions/workflows/contracts.yml)

## Quickstart
Install Foundry from its official distribution, then:
```bash
git clone https://github.com/askneura/neura-v1.git
cd neura-v1
forge build
forge test -vv
forge script contracts/script/DeployNeuraV1.s.sol:DeployNeuraV1
```
Tests and the default script simulation use no live funds or secrets. No broadcast was performed. CI results are visible through the badge; a configured workflow is not itself evidence of a successful run.

## Repository map
- `contracts/src`: Factory, Pool, Router, interfaces and integer math.
- `contracts/test`: self-contained regressions and 256-case fuzz checks.
- `contracts/script`: local deployment preparation.
- `docs`: protocol concepts and developer/API references.
- `.github`: contract checks and contribution templates.

Core and routing code share one repository so interface changes and tests are reviewed together. No additional empty repositories or unaudited token/governance contracts are presented as completed products.

## Explore
- [Documentation](docs/README.md) — protocol concepts, formulas, products and source explanations.
- [Developer guide](DEVELOPMENT.md) — local contract compilation and review checklist.
- [Security policy](SECURITY.md) — limitations and private vulnerability reporting.
- [Contributing](CONTRIBUTING.md) — proposed improvements and review expectations.
- [Licensing status](LICENSING.md) — existing source notices and unresolved license terms.

## Architecture
```text
Factory → Pool ↔ Router
          ↓
       NeuraMath
```

The factory creates pools identified by token pair, curve and fee tier. Pools hold reserves and issue LP shares. The router coordinates liquidity and exact-input routes. See [contract architecture](docs/contracts.md).

Neura's interface supports Ethereum, Base, Arbitrum, Optimism, Polygon and BNB Chain; this does not mean V1 contracts have been deployed on those networks. There are no official V1 addresses in this release.

## Official links
- Website: https://askneura.app
- Documentation: https://askneura.app/docs
- X: https://x.com/AskNeura
- Telegram: https://t.me/AskNeura

Maintained under the Neura brand. Public source visibility is not a security audit or an unrestricted license grant.
