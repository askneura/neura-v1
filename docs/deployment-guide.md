# Deployment preparation

Safe local simulation, compiler settings and the release checklist before any mainnet broadcast.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Local simulation only

```bash
forge script contracts/script/DeployNeuraV1.s.sol:DeployNeuraV1
```

The supplied script creates Factory then Router(factory). Foundry's default script execution is local simulation. No broadcast flag, production URL or private key is embedded. Local addresses are not official deployments.

## Before any funds-bearing release

1. Freeze the source revision and retain compiler 0.8.28, via-IR, optimizer settings and EVM target with the release record.
2. Run regression, fuzz and longer stateful campaigns; independently review token compatibility, stable domains, economic assumptions and calldata.
3. Complete independent security audits and publish scope, reports, residual risks and remediation commits.
4. Obtain owner-approved licensing terms and decide the verified public release identifier.
5. Use secure deployer key management outside this repository; never paste keys into issues or source.
6. Confirm chain ID, transaction simulation, deployed bytecode and explorer verification independently.
7. Record factory/router addresses, transaction hashes and bytecode hashes in [Deployments](deployments.md) only after verification.

Pool CREATE2 addresses depend on **factory address, salt and pool initialization bytecode**. Matching addresses across chains are not guaranteed. No cross-chain deployment or live broadcast was performed for this reference release.
