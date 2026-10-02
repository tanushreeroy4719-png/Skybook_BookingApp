package skybook.exception;

/**
 * Exceptions.java — all domain-specific exception classes in one file for convenience.
 *
 * Java-II Unit 3: Exception Handling — try, catch, throw, throws, finally, custom exceptions
 */
public final class Exceptions {

    private Exceptions() {}   // not instantiable

    // ──────────────────────────────────────────────────────────────
    //  Authentication & Authorization
    // ──────────────────────────────────────────────────────────────

    /** Thrown when login credentials are invalid */
    public static class InvalidCredentialsException extends SkyBookException {
        public InvalidCredentialsException() {
            super("AUTH_001", "Invalid username or password.");
        }
        public InvalidCredentialsException(String msg) {
            super("AUTH_001", msg);
        }
    }

    /** Thrown when a user/airline/admin is not found */
    public static class AccountNotFoundException extends SkyBookException {
        public AccountNotFoundException(String id) {
            super("AUTH_002", "No account found for: " + id);
        }
    }

    /** Thrown when trying to register an already-existing account */
    public static class DuplicateAccountException extends SkyBookException {
        public DuplicateAccountException(String id) {
            super("AUTH_003", "Account already exists: " + id);
        }
    }

    /** Thrown when an account is blocked or inactive */
    public static class AccountInactiveException extends SkyBookException {
        public AccountInactiveException(String name) {
            super("AUTH_004", "Account is inactive or blocked: " + name);
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Flight & Search
    // ──────────────────────────────────────────────────────────────

    /** Thrown when no flights match search criteria */
    public static class NoFlightsFoundException extends SkyBookException {
        public NoFlightsFoundException(String from, String to, String date) {
            super("FLT_001", "No flights found from " + from + " to " + to + " on " + date + " (±1 day).");
        }
    }

    /** Thrown when a flight ID does not exist */
    public static class FlightNotFoundException extends SkyBookException {
        public FlightNotFoundException(int flightId) {
            super("FLT_002", "Flight not found: ID " + flightId);
        }
    }

    /** Thrown when flight is full */
    public static class FlightFullException extends SkyBookException {
        public FlightFullException(int flightId) {
            super("FLT_003", "Flight " + flightId + " has no available seats.");
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Seat
    // ──────────────────────────────────────────────────────────────

    /** Thrown when a requested seat is already taken */
    public static class SeatUnavailableException extends SkyBookException {
        public SeatUnavailableException(String seat) {
            super("SEAT_001", "Seat " + seat + " is not available.");
        }
    }

    /** Thrown when seat number format is invalid */
    public static class InvalidSeatFormatException extends SkyBookException {
        public InvalidSeatFormatException(String input) {
            super("SEAT_002", "'" + input + "' is not a valid seat format. Use e.g. 1A, 3W, 5M.");
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Booking
    // ──────────────────────────────────────────────────────────────

    /** Thrown when a booking ID is not found */
    public static class BookingNotFoundException extends SkyBookException {
        public BookingNotFoundException(int bookingId) {
            super("BKG_001", "Booking not found: ID " + bookingId);
        }
    }

    /** Thrown when trying to cancel an already-cancelled booking */
    public static class AlreadyCancelledException extends SkyBookException {
        public AlreadyCancelledException(int bookingId) {
            super("BKG_002", "Booking " + bookingId + " is already cancelled.");
        }
    }

    /** Thrown when cancellation window has passed */
    public static class CancellationWindowExpiredException extends SkyBookException {
        public CancellationWindowExpiredException(String policy) {
            super("BKG_003", "Cancellation not allowed per airline policy: " + policy);
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Payment
    // ──────────────────────────────────────────────────────────────

    /** Thrown when a payment fails (simulate gateway error) */
    public static class PaymentFailedException extends SkyBookException {
        public PaymentFailedException(String reason) {
            super("PAY_001", "Payment failed: " + reason);
        }
    }

    /** Thrown when payment method is invalid */
    public static class InvalidPaymentMethodException extends SkyBookException {
        public InvalidPaymentMethodException(String method) {
            super("PAY_002", "Invalid payment method: " + method);
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Validation
    // ──────────────────────────────────────────────────────────────

    /** Generic input validation failure */
    public static class ValidationException extends SkyBookException {
        public ValidationException(String field, String reason) {
            super("VAL_001", "Validation failed for '" + field + "': " + reason);
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Database
    // ──────────────────────────────────────────────────────────────

    /** Wraps SQL errors as checked application exceptions */
    public static class DatabaseException extends SkyBookException {
        public DatabaseException(String operation, Throwable cause) {
            super("DB_001", "Database error during: " + operation
                    + (cause != null && cause.getMessage() != null ? " (" + cause.getMessage() + ")" : ""), cause);
        }
    }
}
