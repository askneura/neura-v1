# Neura V1

Neura's public liquidity-protocol reference source and documentation.

**Unaudited. Not deployed. Not ready for real funds.** Swap and Pools are coming soon. This repository does not include the Neura website, private services, user records or credentials.

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
