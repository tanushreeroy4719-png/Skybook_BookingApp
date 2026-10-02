package skybook.exception;

/**
 * SkyBookException — base custom exception for all SkyBook application errors.
 *
 * Java-II Unit 3 coverage:
 *   • Custom checked exception hierarchy
 *   • Chained exceptions (cause wrapping)
 *   • throw / throws usage throughout the app
 */
public class SkyBookException extends Exception {

    private final String errorCode;

    public SkyBookException(String message) {
        super(message);
        this.errorCode = "ERR_GENERAL";
    }

    public SkyBookException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }

    public SkyBookException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "ERR_GENERAL";
    }

    public SkyBookException(String errorCode, String message, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }

    public String getErrorCode() { return errorCode; }

    @Override
    public String toString() {
        return "[" + errorCode + "] " + getMessage();
    }
}
