# Errors and troubleshooting

What contract reverts mean and which inputs to inspect before retrying.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Router errors

| Error | Inspect |
|---|---|
| Expired | Deadline and current chain timestamp. |
| Slippage | Both liquidity minima or final recipient balance delta. Refresh quote; do not silently loosen limits. |
| NoPool | Pair, curve, fee and verified factory. |
| InvalidRoute | Empty path, disconnected hops, identical hop tokens or reused pool. |
| InvalidRecipient | Zero address or router used as recipient. |
| transferFrom | Token approval, sender balance and token-specific transfer rules. |

## Pool errors

| Error | Inspect |
|---|---|
| Locked | Same-pool reentry from a token or flash callback. |
| InsufficientLiquidityMinted / Burned | Deposit size, reserves, locked minimum, sent LP amount and rounding. |
| InsufficientOutput / Input | Positive requested output and actual transferred repayment. |
| InsufficientLiquidity | Requested outputs must be below corresponding reserves. |
| InvalidTo | Zero, pool, token-contract recipient or locked-address LP transfer. |
| KInvariant | Fee-adjusted repayment insufficient, or stable reserves outside invariant floor. |
| Overflow | uint112 raw cap or 10^28 normalized stable reserve cap. |
| UnsupportedDecimals | Metadata above 18 decimals. |
| TransferFailed | Token transfer reverted or returned false. |

Factory string reasons include identical, zero, token code, fee tier, exists and creating. Stable initialization requires equal normalized balances and enough liquidity above the locked floor.

Reverts are not transactions to retry blindly. Decode against the exact source/ABI revision, simulate with current state and preserve user-approved limits. Never print raw RPC HTML or private wallet data to visitors.
