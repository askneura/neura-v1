# Developer quickstart

Clone the public source, run local contract tests and simulate deployment without real funds.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Public source

[Neura V1 on GitHub](https://github.com/askneura/neura-v1) contains protocol contracts, tests and documentation only. The website and private wallet services are not part of this repository.

```bash
git clone https://github.com/askneura/neura-v1.git
cd neura-v1
forge build
forge test -vv
forge test --match-test testFuzz -vv
forge script contracts/script/DeployNeuraV1.s.sol:DeployNeuraV1
```

Install Foundry from its official distribution first. Solidity is pinned to 0.8.28, optimization to 200 runs, via-IR enabled and EVM target Paris. Tests are self-contained: no provider key, wallet key, RPC URL or real assets are required. The script command above **simulates locally**; it does not broadcast.

## Start here

1. Read [integration assumptions](integration-guide.md).
2. Study [contract APIs](contract-api.md).
3. Run the [validation suite](testing.md).
4. Review [security boundaries](security.md) before building on the reference code.

Passing local tests does not establish production safety. There are no official V1 deployments, token launch or production release guarantees.
