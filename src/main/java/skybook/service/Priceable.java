package skybook.service;

import java.math.BigDecimal;

/**
 * Priceable — interface for anything that has a computable price.
 *
 * Java-II U1: Interface + Lambda usage.
 *   - Implemented by CancellationPolicy (anonymous inner / lambda context).
 *   - Also used as a functional interface where lambdas compute refund amounts.
 *
 * Java-II U1: Runtime Polymorphism — callers use Priceable references without
 *             knowing the concrete class behind it.
 */
@FunctionalInterface
public interface Priceable {
    /**
     * Computes and returns the relevant price/amount.
     *
     * @param baseAmount the original price to base the calculation on
     * @return           the computed price (e.g. refund, surcharge)
     */
    BigDecimal compute(BigDecimal baseAmount);
}
