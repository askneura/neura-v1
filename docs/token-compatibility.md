# Token compatibility

Supported decimal ranges and limits for taxed, rebasing and malicious tokens.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Supported metadata and domains

- Token addresses must contain contract code.
- decimals() must succeed and return an integer from **0 to 18**. V1 rejects higher decimals.
- Raw recorded reserves cannot exceed uint112 maximum.
- Stable reserves normalize to 18 decimals and cannot exceed **10^28 per side**. Amounts beyond this domain revert before invariant arithmetic.
- Stable initialization is balanced in normalized units. Locked LP shares retain at least the normalized dust floor; stable post-update invariant must exceed 1,000.

## Transfer behavior

Ordinary ERC-20 transfers returning true or no data are accepted. A false return or revert fails the operation. Exact-input swaps measure actual pool inputs and final recipient balance changes, including the simple transfer-tax fixtures in the local tests.

This does **not** mean arbitrary token compatibility:

| Behavior | Status / risk |
|---|---|
| Fixed transfer tax | Selected swap behavior tested; static quotes cannot predict taxes. Liquidity-return values are nominal. |
| Rebasing / reflective balances | Unsupported; reserve accounting can change without a transfer. |
| Callback / malicious ERC-20 | Untrusted; pool lock helps same-pool reentry but cannot make malicious assets safe. |
| Blacklists, pauses, upgradeable tokens | Issuer controls can stop transfers or change behavior. |
| Decimals above 18 or missing metadata | Rejected. |
| Native ETH / BNB / POL | Not ERC-20 input; no native wrapping route. |

Stable-curve use assumes economically correlated prices. A depeg or a malicious asset can cause LP loss. A matching symbol is not evidence of a peg or authenticity.
