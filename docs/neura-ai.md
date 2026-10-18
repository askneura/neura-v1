# Neura AI

What the assistant can do, where its data comes from and its limits.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Neura AI is a chat assistant connected to live data.

| Ask about | Data source |
|---|---|
| Any token's price, market cap, volume | CoinGecko |
| Top gainers and losers | CoinGecko |
| Gas on all six chains | Public chain RPCs |
| Any wallet's balances, activity, LP positions | Public RPCs + Blockscout |
| News and recent events | Web search |
| "Swap 1 ETH to USDC" | Quote preview (Swap is coming soon) |

Chats are saved privately per wallet. Neura AI **never** signs or sends transactions.
