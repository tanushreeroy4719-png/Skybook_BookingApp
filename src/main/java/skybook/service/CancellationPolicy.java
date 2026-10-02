package skybook.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

/**
 * CancellationPolicy — per-airline rules for cancellation windows and refunds.
 *
 * Java-II U1: Abstraction (abstract class) + Interface (Priceable as lambda).
 * Java-II U1: Lambda expressions — refund calculators stored as Priceable lambdas.
 * Java-II U6: HashMap stores policies keyed by airlineId.
 *
 * Real-world policies (based on published airline rules as of 2025):
 *
 * BUDGET airlines (IndiGo/SpiceJet/AirAsia/Akasa/GoFirst/AIExpress):
 *   - Cancel > 24h before departure: 25% refund
 *   - Cancel 3–24h before departure: 10% refund
 *   - Cancel < 3h before departure:  No refund
 *
 * MID-TIER (Vistara):
 *   - Cancel > 48h before departure: 50% refund
 *   - Cancel 12–48h:                 25% refund
 *   - Cancel < 12h:                  No refund
 *
 * PREMIUM (Air India, Emirates, Qatar, SIA, BA, Lufthansa, AirFrance, JAL, Qantas, MAS, Thai):
 *   - Cancel > 72h before departure: 75% refund
 *   - Cancel 24–72h:                 50% refund
 *   - Cancel < 24h:                  25% refund (admin fee deducted)
 */
public abstract class CancellationPolicy {

    /** Human-readable policy description shown to user before payment. */
    public abstract String getPolicyText();

    /**
     * Computes the refund amount for a given price paid and hours-until-departure.
     * Uses a Priceable lambda to encapsulate the refund logic.
     *
     * Java-II U1: Runtime polymorphism — subclass decides which lambda is used.
     */
    public abstract BigDecimal computeRefund(BigDecimal pricePaid, long hoursBeforeDeparture);

    /** Returns true if cancellation is allowed at this time. */
    public abstract boolean canCancel(long hoursBeforeDeparture);

    // ── Concrete subclasses ───────────────────────────────────────────────────

    /** Budget airlines: IndiGo(1), SpiceJet(3), GoFirst(5), AirAsia(6), Akasa(17), AIExpress(19) */
    public static class BudgetPolicy extends CancellationPolicy {

        // Priceable lambdas — Java-II U1 Lambda
        private static final Priceable REFUND_25 = base ->
                base.multiply(new BigDecimal("0.25")).setScale(2, RoundingMode.HALF_UP);
        private static final Priceable REFUND_10 = base ->
                base.multiply(new BigDecimal("0.10")).setScale(2, RoundingMode.HALF_UP);
        private static final Priceable REFUND_0  = base -> BigDecimal.ZERO;

        @Override
        public String getPolicyText() {
            return "BUDGET AIRLINE CANCELLATION POLICY\n" +
                   "  • Cancel > 24 hrs before departure : 25% refund\n" +
                   "  • Cancel 3–24 hrs before departure : 10% refund\n" +
                   "  • Cancel < 3 hrs before departure  : No refund";
        }

        @Override
        public BigDecimal computeRefund(BigDecimal pricePaid, long hours) {
            Priceable fn;
            if      (hours > 24) fn = REFUND_25;
            else if (hours >= 3) fn = REFUND_10;
            else                 fn = REFUND_0;
            return fn.compute(pricePaid);  // Runtime polymorphism via lambda
        }

        @Override
        public boolean canCancel(long hours) { return true; } // always allowed (0% case)
    }

    /** Mid-tier airlines: Vistara(4) */
    public static class MidPolicy extends CancellationPolicy {

        private static final Priceable REFUND_50 = base ->
                base.multiply(new BigDecimal("0.50")).setScale(2, RoundingMode.HALF_UP);
        private static final Priceable REFUND_25 = base ->
                base.multiply(new BigDecimal("0.25")).setScale(2, RoundingMode.HALF_UP);
        private static final Priceable REFUND_0  = base -> BigDecimal.ZERO;

        @Override
        public String getPolicyText() {
            return "MID-TIER AIRLINE CANCELLATION POLICY\n" +
                   "  • Cancel > 48 hrs before departure  : 50% refund\n" +
                   "  • Cancel 12–48 hrs before departure : 25% refund\n" +
                   "  • Cancel < 12 hrs before departure  : No refund";
        }

        @Override
        public BigDecimal computeRefund(BigDecimal pricePaid, long hours) {
            Priceable fn;
            if      (hours > 48) fn = REFUND_50;
            else if (hours >= 12) fn = REFUND_25;
            else                  fn = REFUND_0;
            return fn.compute(pricePaid);
        }

        @Override
        public boolean canCancel(long hours) { return true; }
    }

    /** Premium airlines: AirIndia(2), Emirates(7), Qatar(8), SIA(9), BA(10),
     *                    Lufthansa(11), AirFrance(12), JAL(13), Qantas(14),
     *                    MAS(15), Thai(16), BlueDart(20) */
    public static class PremiumPolicy extends CancellationPolicy {

        private static final Priceable REFUND_75 = base ->
                base.multiply(new BigDecimal("0.75")).setScale(2, RoundingMode.HALF_UP);
        private static final Priceable REFUND_50 = base ->
                base.multiply(new BigDecimal("0.50")).setScale(2, RoundingMode.HALF_UP);
        private static final Priceable REFUND_25 = base ->
                base.multiply(new BigDecimal("0.25")).setScale(2, RoundingMode.HALF_UP);

        @Override
        public String getPolicyText() {
            return "PREMIUM AIRLINE CANCELLATION POLICY\n" +
                   "  • Cancel > 72 hrs before departure  : 75% refund\n" +
                   "  • Cancel 24–72 hrs before departure : 50% refund\n" +
                   "  • Cancel < 24 hrs before departure  : 25% refund (admin fee)";
        }

        @Override
        public BigDecimal computeRefund(BigDecimal pricePaid, long hours) {
            Priceable fn;
            if      (hours > 72) fn = REFUND_75;
            else if (hours >= 24) fn = REFUND_50;
            else                  fn = REFUND_25;
            return fn.compute(pricePaid);
        }

        @Override
        public boolean canCancel(long hours) { return true; }
    }

    // ── Factory ───────────────────────────────────────────────────────────────

    /** Budget airline IDs from the data file */
    private static final java.util.Set<Integer> BUDGET  = new java.util.HashSet<>(
            java.util.Arrays.asList(1, 3, 5, 6, 17, 18, 19));
    /** Mid-tier airline IDs */
    private static final java.util.Set<Integer> MID     = new java.util.HashSet<>(
            java.util.Arrays.asList(4));
    // Everything else → Premium

    /**
     * Returns the correct policy for a given airline.
     * Java-II U6: HashSet for O(1) membership test.
     */
    public static CancellationPolicy forAirline(int airlineId) {
        if (BUDGET.contains(airlineId)) return new BudgetPolicy();
        if (MID.contains(airlineId))    return new MidPolicy();
        return new PremiumPolicy();
    }

    /**
     * Convenience: hours from now until departure.
     * Java-II U2: Java Date-Time API (Duration.between).
     */
    public static long hoursUntil(LocalDateTime departure) {
        LocalDateTime now = LocalDateTime.now();
        if (departure.isBefore(now)) return 0;
        return Duration.between(now, departure).toHours();
    }
}
