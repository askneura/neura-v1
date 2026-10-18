# How Neura works

The three layers of Neura: interface, AI and the on-chain protocol.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Neura has three layers. Only the last one holds funds — and it is code nobody, including us, can override.

```text
 ┌──────────────────────────────────────────────────────────────┐
 │  1. Interface     askneura.app — wallet connect, quotes, UI   │
 ├──────────────────────────────────────────────────────────────┤
 │  2. Neura AI      live prices · gas · wallet scan · risk      │
 │                   reads data, never signs or moves funds      │
 ├──────────────────────────────────────────────────────────────┤
 │  3. Neura V1      Factory ─▶ Pools ◀─ Router  (on-chain)      │
 │                   non-custodial, immutable fee tiers          │
 └──────────────────────────────────────────────────────────────┘
```

## A trade, step by step

1. You type *"swap 1 ETH to USDC"* or use the swap box.
2. The interface asks each candidate pool for `getAmountOut` and picks the best route.
3. Neura AI explains the quote: price impact, slippage, token risk, gas.
4. **You sign** in your own wallet. Neura never holds keys.
5. The Router moves your tokens through the pools; if you would receive less than your minimum, the whole transaction reverts.

## Non-custodial by design

Pools hold liquidity; the Router holds nothing between calls; the Factory cannot change a pool's fee or pause it. There is **no admin key over user funds**.
