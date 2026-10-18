# Swaps and routing

Exact-input swaps, multi-hop routes and how the Router protects you.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Routes

A route is a list of hops. Each hop names its pool by `(from, to, stable, fee)`:

```text
 WBTC ──(volatile 0.30%)──▶ ETH ──(volatile 0.05%)──▶ USDC ──(stable 0.01%)──▶ USDT
```

The Router sends each hop's output **directly to the next pool**, saving one transfer per hop.

## Protections on every swap

- **amountOutMin** — the swap reverts if you would get less.
- **deadline** — the swap reverts if mined too late.
- **Real balance check** — the Router measures what *actually* arrived in your wallet, so fee-on-transfer tokens can't trick the minimum.

## Best route

A future executable interface can quote candidate routes with `getAmountsOut` across fee tiers and both curves, then compare output after gas. V1 has no on-chain best-route discovery. Swap is currently coming soon; AI previews do not submit trades.
