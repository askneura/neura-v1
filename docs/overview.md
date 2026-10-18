# Welcome to Neura

What Neura is, how it is different, and where to start reading.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Neura is an **AI-native, multi-chain exchange** for EVM networks. It pairs our own on-chain liquidity protocol — **Neura V1** — with an assistant that reads live chain data and checks risk *before* you trade.

> **Status.** The Neura interface, Neura AI and Check OG are live. Swap and Pools are **coming soon**. The Neura V1 contracts in these docs are a public reference implementation: **unaudited and not deployed**. Never send funds to an address claiming to be a Neura contract until it is listed on [Deployments](deployments.md).

## What makes Neura different

| | Classic AMM | Neura V1 |
|---|---|---|
| Curves | One curve per protocol | **Volatile + Stable curves in one pool contract** |
| Fees | Fixed per pool | **Fixed tier + same-block surge fee** that taxes sandwich bots, not users |
| Risk | You find out after | **Neura AI risk check before signing** |
| Chains | Usually one per deployment | **Six EVM mainnets, one interface** |
| Oracle | Optional | **Built-in TWAP on every pool** |

## Read next

- [How Neura works](how-it-works.md) — the five-minute tour
- [Neura V1 protocol](protocol.md) — the design of our pools
- [Smart contracts](contracts.md) — every line of code, explained
- [Security model](security.md) — what we defend against and how
