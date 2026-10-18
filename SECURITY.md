# Security policy

**Reference implementation: unaudited, not deployed. No production-safety guarantee.** No version is currently designated safe for real funds.

Do not publish exploit details, wallet secrets or personal records in issues. Ask @AskNeura through the official X account for a private reporting channel before sending sensitive findings. A dedicated security email and bounty program are not established in this release; no bounty payment is promised.

## Review scope
Factory, Pool, Router, NeuraMath and interfaces. Report affected source revision, assumptions, local reproduction and impact without using live funds.

## Limitations
- Same-block surge fees are not guaranteed sandwich or MEV protection and may affect ordinary transactions.
- Cumulative prices are primitives, not a complete manipulation-resistant oracle; consumers need independent review.
- Rebasing, malicious and non-standard tokens can invalidate accounting assumptions; fee-on-transfer handling is not universal support.
- Stable arithmetic, decimal normalization, rounding and callbacks require adversarial tests.
- No pause or upgrade mechanism does not mean no vulnerabilities.

Documentation describes intended mechanisms, not proven security outcomes. Where wording appears absolute, these limitations apply. Audits, fuzz testing and a deployment review remain outstanding.
