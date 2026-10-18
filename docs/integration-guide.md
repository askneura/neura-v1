# Integrating Neura V1

Token approvals, route validation, unit conversions and transaction boundaries.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Integration sequence

1. Obtain the **verified factory and router for the target chain**. None exist officially yet; use local simulation only.
2. Resolve the pool through factory.getPool(tokenA, tokenB, stable, fee). A zero address means the pool does not exist.
3. Approve the router for the exact ERC-20 spending amount, according to the token's approval rules. An approval is not a swap.
4. Build a connected list of Route structs. Each hop uses from, to, stable and fee; from of the next hop must equal to of the preceding hop. Empty routes and repeated pools are rejected.
5. Quote with getAmountsOut. Re-read the quote immediately before constructing the transaction; this is a snapshot, not a guaranteed execution price.
6. Set amountOutMin and a realistic deadline, then submit the exact-input call with a recipient distinct from zero and the router.
7. Read the transaction receipt and Swap/Sync events. A mined revert leaves transfers rolled back, but gas is still spent.

## Units and slippage

All call amounts use the token's **raw integer units**. A quantity of one 6-decimal token is 1,000,000; one 18-decimal token is 10^18. Never use JavaScript floating point for transaction amounts.

```text
amountOutMin = floor(quote * (10_000 - toleranceBps) / 10_000)
deadline = currentChainTimestamp + chosenWindowSeconds
```

Tolerance is an application/user decision, not a contract default. The recipient's output-token balance delta enforces the minimum on swaps. Fee-on-transfer quotes do not know token taxes in advance; exact-input execution measures actual transfers but this is not universal support for malicious or rebasing tokens.

## Native assets

V1 accepts **ERC-20 tokens only**. It has no payable native-asset route, wrapper or permit entry point. Use an independently verified wrapped native asset; native wrapping must happen separately. Do not send native coins to these contracts.

The router does not find a best route or bridge assets. Route discovery is off-chain and every hop executes on the same chain. See [compatibility](token-compatibility.md) and [errors](errors.md).
