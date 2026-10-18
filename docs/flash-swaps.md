# Flash swaps

Receive tokens first and pay at the end of the same transaction.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

`swap` sends output tokens **before** checking payment. If `data` is non-empty, the pool calls your contract:

```solidity
function neuraV1Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
```

Inside the callback you can do anything — arbitrage, liquidate, refinance — as long as, when it returns, the pool's invariant holds after fees. Otherwise the entire transaction reverts and nothing happened.

```text
 pool ──tokens──▶ you ──(use them)──▶ repay pool ──▶ invariant check ✓
```

The re-entrancy lock prevents calling back into the same pool during the callback.
