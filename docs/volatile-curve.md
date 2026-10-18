# Volatile curve (x·y = k)

The constant-product formula, swap output math and a worked example.

> Reference documentation. V1 contracts are unaudited and not deployed. Read the [security limitations](../SECURITY.md); descriptions are not guarantees.

Volatile pools keep the product of reserves constant (it only grows, from fees).

$$
x \cdot y = k
$$

## Output for an exact input

With reserves $x$ (in) and $y$ (out), fee $f$ and input $\Delta x$:

$$
\Delta x' = \Delta x\,(1-f) \qquad \Delta y = \frac{\Delta x' \cdot y}{x + \Delta x'}
$$

## Worked example

Pool: 100 ETH and 300,000 USDC, fee 0.30%. Swap 1 ETH.

- $\Delta x' = 1 \times 0.997 = 0.997$
- $\Delta y = 0.997 \times 300{,}000 / 100.997 \approx 2{,}961.5$ USDC
- Spot price was 3,000 → you pay ~1.28% (0.30% fee + 0.98% price impact).

## Marginal price

$$
P = \frac{y}{x}
$$

The curve never runs out: as $x$ grows, $y$ approaches zero but never reaches it, so the pool can always quote a price.
