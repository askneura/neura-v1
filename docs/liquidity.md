# Providing liquidity

How LP shares are minted and burned, with formulas and an example.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

When you deposit, you receive **NEURA-V1-LP** tokens that represent your share of the pool.

## First deposit

$$
L = \sqrt{\Delta x \cdot \Delta y} - 1000
$$

For volatile pools the first 1,000 LP units are permanently locked. Stable pools lock max(1,000, floor(sqrt(decimals0 × decimals1) × 10^15 / 10^18)) raw LP units to keep the remaining balances out of the zero-invariant dust domain. Here decimals0/1 are token unit scales (10 raised to metadata decimals), not decimal counts. Accordingly the first stable mint subtracts this larger lock rather than 1,000. A lock raises inflation cost but does not guarantee economic safety.

## Later deposits

$$
L = \min\left(\frac{\Delta x \cdot S}{x},\ \frac{\Delta y \cdot S}{y}\right)
$$

where $S$ is the LP supply. Depositing out of ratio only credits the smaller side, so the Router always computes the optimal amounts for you.

## Withdrawing

$$
\Delta x = \frac{L \cdot x}{S}, \qquad \Delta y = \frac{L \cdot y}{S}
$$

## Example

Pool 100 ETH / 300,000 USDC, supply 5,000 LP. You add 1 ETH + 3,000 USDC → you get $1 \times 5000/100 = 50$ LP (≈ 0.99% of the pool). Every fee paid afterwards increases what those 50 LP tokens redeem for.
