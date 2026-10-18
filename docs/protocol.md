# Neura V1 at a glance

The hybrid pool design: two curves, fee tiers, surge fees and a built-in oracle.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Neura V1 is a **hybrid constant-function market maker**. We studied the ideas that have proven themselves across DeFi — the simplicity of constant-product pools, the capital efficiency of stable curves, flash swaps, on-chain TWAPs — and combined them into one small, auditable contract with a new protection on top.

## Building blocks

| Feature | What it does | Why it matters |
|---|---|---|
| **Volatile curve** | $x \cdot y \ge k$ | Works for any pair, liquidity across all prices |
| **Stable curve** | $x^3y + xy^3 \ge k$ | Near-zero slippage for pegged pairs |
| **Fee tiers** | 0.01% · 0.05% · 0.30% · 1.00% | Match the fee to the pair's risk |
| **Surge fee** | Extra fee on 2nd+ swap in a block | Sandwich attacks stop paying |
| **TWAP oracle** | Cumulative prices every block | Manipulation-resistant price feed |
| **Flash swaps** | Borrow output, repay in the same tx | Arbitrage and liquidations without capital |
| **Locked minimum liquidity** | First 1,000 LP units burned | Kills share-inflation attacks |

## Pool identity

A pool is unique per **(token0, token1, curve, fee tier)**. ETH/USDC can have a 0.05% volatile pool *and* a 0.30% volatile pool; USDC/USDT would typically use the 0.01% stable pool.

```text
              NeuraV1Factory
        createPool(A, B, stable, fee)
                    │  CREATE2(salt = key)
     ┌──────────────┼──────────────┐
     ▼              ▼              ▼
 ETH/USDC       ETH/USDC       USDC/USDT
 volatile       volatile        stable
  0.05%          0.30%           0.01%
```
