# Public repositories and releases

Where public source lives, how to propose changes and how to identify an authentic snapshot.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

## Official public repository

[askneura/neura-v1](https://github.com/askneura/neura-v1) is the single public V1 reference repository. Core and router stay together so interface changes and tests are reviewed atomically; more repositories do not make a protocol safer.

```text
contracts/src/          Factory, Pool, Router, interfaces, math
contracts/test/         self-contained Solidity regressions + fuzz tests
contracts/script/       local deployment preparation
docs/                   protocol + developer documentation
.github/                CI, issue templates, pull-request checklist
foundry.toml            pinned compiler and test settings
SECURITY.md             private vulnerability reporting and boundaries
LICENSING.md            current licensing status
```

Each Git commit identifies a snapshot. Compare the exact contract source and build settings, not only the repository name. The current history does not establish an audited release; no production-ready version or official address exists.

Use ordinary issues for non-sensitive bugs and proposals, and the pull-request checklist for changes with tests. Do **not** publish exploit instructions or user secrets in public issues; follow SECURITY.md first.

Neura branding and official links do not imply unrestricted reuse rights. Existing BUSL-1.1 source notices remain, but owner-approved license terms have not yet been supplied.
