# Events and indexing

Pool creation, LP transfers and swap/liquidity event semantics.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Factory events

PoolCreated(token0, token1, stable, baseFee, pool, index) uses sorted token addresses and a **zero-based** index into allPools. Bind every pool to a verified factory on the same chain; an event with a familiar name from another contract is not proof of authenticity.

## Pool events

| Event | Interpretation |
|---|---|
| Mint(sender, amount0, amount1, to) | Balance additions credited to an LP mint; amounts use raw token units. |
| Burn(sender, amount0, amount1, to) | Pool-side outgoing liquidity amounts, not guaranteed recipient deltas for taxed tokens. |
| Swap(sender, in0, in1, out0, out1, feePips, to) | Actual measured input, requested outputs, effective fee and immediate recipient. |
| Sync(reserve0, reserve1) | Post-action recorded reserves. |
| Transfer(from, to, value) | LP movements; zero sender identifies issuance, zero recipient burn. |
| Approval(owner, spender, value) | LP allowance change. |

## Indexer checklist

- Use chain ID, transaction hash, log index and emitting contract as the event identity.
- Track confirmation depth and roll back orphaned logs on reorganization.
- Fetch decimals once, verify supported metadata, and keep raw units alongside display amounts.
- Distinguish swap sender (often the router) from the transaction origin and beneficiary.
- A multi-hop Swap recipient is often the next pool, not the user's final wallet.
- Never infer revenue in USD from a reserve event without an independently sourced price and timestamp.
- Read token balances for taxed or non-standard assets; events do not prove final received amounts.

No hosted Neura subgraph or official indexing endpoint is available in this reference release.
