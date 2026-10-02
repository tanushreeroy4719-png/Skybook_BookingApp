package skybook.util;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Random;

/**
 * PasswordUtil — SHA-256 password hashing + PNR generator.
 *
 * Java-II U2: Packages (java.security), Access Modifiers (all static utility).
 * Java-II U3: Exception Handling — NoSuchAlgorithmException wrapped as RuntimeException
 *             because SHA-256 is always available in Java SE; callers need not declare it.
 *
 * DS U10: Hashing concept — SHA-256 is a cryptographic hash function.
 *         Demonstrates: deterministic mapping, avalanche effect, one-way property.
 */
public final class PasswordUtil {

    /** Fixed password given to every AIRLINE account (set automatically by the admin flow). */
    public static final String AIRLINE_PASSWORD = "airline@123";

    /**
     * Passenger password rule: letters, then '@', then digits — e.g. "tanu@123".
     * At least 2 letters and 3 digits.
     */
    private static final java.util.regex.Pattern USER_PASSWORD =
            java.util.regex.Pattern.compile("^[A-Za-z]{2,}@[0-9]{3,}$");

    public static final String USER_PASSWORD_HINT =
            "Password must look like name@123 — letters, then @, then numbers (e.g. tanu@123).";

    private PasswordUtil() {}

    /** True if the password follows the passenger format (name@123). */
    public static boolean isValidUserPassword(String password) {
        return password != null && USER_PASSWORD.matcher(password).matches();
    }

    /**
     * Returns the SHA-256 hex digest of the given plaintext.
     * Same input always produces same hash (deterministic), but
     * you cannot reverse the hash to get the password (one-way).
     */
    public static String hash(String plaintext) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] bytes = md.digest(plaintext.getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            // SHA-256 is guaranteed in Java SE — should never happen
            throw new RuntimeException("SHA-256 algorithm not found", e);
        }
    }

    /**
     * Verifies plaintext against a stored hash.
     * Uses constant-time comparison via MessageDigest.isEqual to resist timing attacks.
     */
    public static boolean verify(String plaintext, String storedHash) {
        if (plaintext == null || storedHash == null) return false;
        String computed = hash(plaintext);
        // constant-time comparison (avoids timing side-channel)
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return MessageDigest.isEqual(
                    md.digest(computed.getBytes()),
                    md.digest(storedHash.getBytes())
            );
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Generates a random 10-character alphanumeric PNR (Passenger Name Record).
     * Format: 2 letters + 4 digits + 4 letters  (e.g. "AB1234CDEF")
     *
     * DS: Uses char array (1-D array) as the PNR buffer — demonstrates array manipulation.
     */
    public static String generatePNR() {
        String upper  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        String digits = "0123456789";
        Random rnd    = new Random();

        char[] pnr = new char[10];
        // positions 0-1: letters
        for (int i = 0; i < 2; i++)  pnr[i] = upper.charAt(rnd.nextInt(26));
        // positions 2-5: digits
        for (int i = 2; i < 6; i++)  pnr[i] = digits.charAt(rnd.nextInt(10));
        // positions 6-9: letters
        for (int i = 6; i < 10; i++) pnr[i] = upper.charAt(rnd.nextInt(26));

        return new String(pnr);
    }
}
