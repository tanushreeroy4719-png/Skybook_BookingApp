package skybook.util;

import java.util.Scanner;

/**
 * Console — single shared Scanner + simple print helpers.
 * Java-II U7/U8: Character I/O via Scanner (wraps System.in).
 * Keeps all user input/output in one place so no duplicate Scanner instances.
 */
public final class Console {

    private static final Scanner SC = new Scanner(System.in);

    // ANSI colours
    public static final String RESET   = "\u001B[0m";
    public static final String BOLD    = "\u001B[1m";
    public static final String RED     = "\u001B[31m";
    public static final String GREEN   = "\u001B[32m";
    public static final String YELLOW  = "\u001B[33m";
    public static final String BLUE    = "\u001B[34m";
    public static final String CYAN    = "\u001B[36m";
    public static final String MAGENTA = "\u001B[35m";

    private Console() {}

    /** Clears the terminal screen using ANSI escape codes. */
    public static void clear() {
        System.out.print("\033[H\033[2J");
        System.out.flush();
    }

    // ── Output helpers ─────────────────────────────────────────────
    public static void println(String s)  { System.out.println(s); }
    public static void println()          { System.out.println(); }
    public static void print(String s)    { System.out.print(s); }
    public static void info(String s)     { System.out.println(CYAN    + s + RESET); }
    public static void success(String s)  { System.out.println(GREEN   + s + RESET); }
    public static void warn(String s)     { System.out.println(YELLOW  + s + RESET); }
    public static void error(String s)    { System.out.println(RED     + s + RESET); }
    public static void header(String s)   { System.out.println(BOLD + BLUE + s + RESET); }
    public static void rule()             { System.out.println(BLUE + "─".repeat(65) + RESET); }
    public static void dRule()            { System.out.println(BLUE + "═".repeat(65) + RESET); }

    public static void banner(String title) {
        int w   = Math.max(63, title.length() + 2);
        int pad = (w - title.length()) / 2;
        String lp = " ".repeat(pad);
        String rp = " ".repeat(Math.max(0, w - pad - title.length()));
        System.out.println(BOLD + BLUE + "╔" + "═".repeat(w) + "╗");
        System.out.println("║" + lp + title + rp + "║");
        System.out.println("╚" + "═".repeat(w) + "╝" + RESET);
    }

    public static void section(String s) {
        System.out.println("\n" + BOLD + MAGENTA + "▶  " + s + RESET);
        System.out.println(MAGENTA + "─".repeat(45) + RESET);
    }

    public static void kv(String key, String value) {
        System.out.printf("  %s%-22s%s %s%n", CYAN, key + ":", RESET, value);
    }

    // ── Input helpers ──────────────────────────────────────────────

    /** Read a trimmed line (may be empty). */
    public static String readLine(String prompt) {
        System.out.print(YELLOW + prompt + RESET);
        return SC.nextLine().trim();
    }

    /** Read a non-blank string; loops until something is typed. */
    public static String readRequired(String prompt) {
        while (true) {
            String v = readLine(prompt);
            if (!v.isEmpty()) return v;
            error("  This field cannot be blank.");
        }
    }

    /** Read an integer in [min, max] — loops on bad input. */
    public static int readInt(String prompt, int min, int max) {
        while (true) {
            System.out.print(YELLOW + prompt + RESET);
            String raw = SC.nextLine().trim();
            try {
                int v = Integer.parseInt(raw);
                if (v >= min && v <= max) return v;
                error("  Enter a number between " + min + " and " + max + ".");
            } catch (NumberFormatException e) {
                error("  '" + raw + "' is not a valid number.");
            }
        }
    }

    /** Read an integer >= min (no upper bound). */
    public static int readInt(String prompt, int min) {
        return readInt(prompt, min, Integer.MAX_VALUE);
    }

    /** Read a non-negative double — loops on bad input. */
    public static double readDouble(String prompt) {
        while (true) {
            System.out.print(YELLOW + prompt + RESET);
            String raw = SC.nextLine().trim();
            try {
                double v = Double.parseDouble(raw);
                if (v >= 0) return v;
                error("  Value cannot be negative.");
            } catch (NumberFormatException e) {
                error("  Invalid decimal value.");
            }
        }
    }

    /** Yes/no question — accepts y/yes/n/no (case-insensitive). */
    public static boolean confirm(String prompt) {
        while (true) {
            String v = readLine(prompt + " [y/n]: ").toLowerCase();
            if (v.equals("y") || v.equals("yes")) return true;
            if (v.equals("n") || v.equals("no"))  return false;
            error("  Please enter y or n.");
        }
    }

    /** Masked password input; falls back to plain read in IDEs. */
    public static String readPassword(String prompt) {
        System.out.print(YELLOW + prompt + RESET);
        java.io.Console c = System.console();
        if (c != null) {
            char[] pw = c.readPassword();
            return pw == null ? "" : new String(pw);
        }
        warn("  (IDE mode — password visible)");
        return SC.nextLine().trim();
    }

    /**
     * Reads and validates a NEW password according to the policy:
     *   - Minimum length of 6 characters
     *   - Position 2 (index 1) must be a special character
     *   - Position 4 (index 3) must be a special character
     *   - At least 1 uppercase letter anywhere
     *
     * Shows the policy rules before prompting. Loops until valid.
     * Used only for registration / account creation -- NOT for login.
     */
    public static String readNewPassword(String prompt) {
        info("  Password policy:");
        info("    * Minimum 6 characters");
        info("    * Position 2 must be a special character (e.g. @, #, $, !)");
        info("    * Position 4 must be a special character (e.g. @, #, $, !)");
        info("    * At least 1 uppercase letter");

        while (true) {
            System.out.print(YELLOW + prompt + RESET);
            java.io.Console c = System.console();
            String pw;
            if (c != null) {
                char[] chars = c.readPassword();
                pw = (chars == null) ? "" : new String(chars);
            } else {
                warn("  (IDE mode -- password visible)");
                pw = SC.nextLine();
            }

            if (pw.length() < 6) {
                error("  Password must be at least 6 characters long.");
                continue;
            }

            // Position 2 = index 1, Position 4 = index 3
            if (!isSpecialChar(pw.charAt(1))) {
                error("  Position 2 (2nd character) must be a special character (e.g. @, #, $, !, %).");
                continue;
            }

            if (!isSpecialChar(pw.charAt(3))) {
                error("  Position 4 (4th character) must be a special character (e.g. @, #, $, !, %).");
                continue;
            }

            boolean hasUpper = false;
            for (char ch : pw.toCharArray()) {
                if (Character.isUpperCase(ch)) { hasUpper = true; break; }
            }
            if (!hasUpper) {
                error("  Password must contain at least 1 uppercase letter.");
                continue;
            }

            return pw;
        }
    }

    /** Returns true if the character is a special (non-alphanumeric) character. */
    private static boolean isSpecialChar(char c) {
        return !Character.isLetterOrDigit(c);
    }

    /** Wait for Enter. */
    public static void pause() {
        System.out.print(CYAN + "\n  [ Press ENTER to continue ] " + RESET);
        SC.nextLine();
    }

    // ── Validated input helpers ────────────────────────────────────

    /**
     * Reads an email that must:
     *  - have at least 3 alphabetic characters before '@'
     *  - end with @gmail.com or @yahoo.com
     * Loops until valid.
     */
    public static String readEmail(String prompt) {
        while (true) {
            String v = readLine(prompt).trim();
            if (v.isEmpty()) { error("  Email cannot be blank."); continue; }

            // @ must appear exactly once
            long atCount = v.chars().filter(c -> c == '@').count();
            if (atCount != 1) {
                error("  Email must contain exactly one '@' character.");
                continue;
            }

            // Must end with @gmail.com or @yahoo.com (case-insensitive)
            String lower = v.toLowerCase();
            boolean validDomain = lower.endsWith("@gmail.com") || lower.endsWith("@yahoo.com");
            if (!validDomain) {
                error("  Email must end with @gmail.com or @yahoo.com.");
                continue;
            }

            // Extract local part (before @)
            int atIdx = v.indexOf('@');
            String local = v.substring(0, atIdx);

            // Local part must contain ONLY letters and digits — no special characters
            if (!local.matches("[a-zA-Z0-9]+")) {
                error("  Characters before '@' must be letters and digits only (no special characters, dots, or underscores).");
                continue;
            }

            // Count alphabetic chars in local part — need at least 3
            long alphaCount = local.chars().filter(Character::isLetter).count();
            if (alphaCount < 3) {
                error("  Email must have at least 3 alphabetic characters before '@'.");
                continue;
            }
            return v;
        }
    }

    /**
     * Reads a name (first or last) that must:
     *  - contain only alphabetic characters (A-Z, a-z)
     *  - contain no spaces or special characters
     *  - not be blank
     * Loops until valid.
     */
    public static String readName(String prompt) {
        while (true) {
            String v = readLine(prompt).trim();
            if (v.isEmpty()) { error("  This field cannot be blank."); continue; }
            if (!v.matches("[a-zA-Z]+")) {
                error("  Name must contain only alphabetic characters (no spaces, digits, or special characters).");
                continue;
            }
            return v;
        }
    }

    /**
     * Reads a phone number that must:
     *  - be exactly 10 digits
     *  - start with 6, 7, or 9
     * Loops until valid.
     */
    public static String readPhone(String prompt) {
        while (true) {
            String v = readLine(prompt).trim();
            if (v.isEmpty()) { error("  Phone number cannot be blank."); continue; }

            if (!v.matches("\\d{10}")) {
                error("  Phone number must be exactly 10 digits (no spaces or dashes).");
                continue;
            }
            char first = v.charAt(0);
            if (first != '6' && first != '7' && first != '9') {
                error("  Phone number must start with 6, 7, or 9.");
                continue;
            }
            return v;
        }
    }

    /**
     * Reads a date in dd-MM-yyyy, enforcing age bounds in years.
     * Loops until valid.
     *
     * @param prompt     text shown to user
     * @param minAge     minimum age in years (e.g. 18); 0 = no minimum age check
     * @param maxAge     maximum age in years (e.g. 110); 0 = no maximum age check
     * @param futureOnly if true, date must be in the future (for travel date)
     * @param maxMonths  if > 0, date must not be more than maxMonths from today
     */
    public static java.time.LocalDate readDate(
            String prompt, int minAge, int maxAge, boolean futureOnly, int maxMonths) {

        java.time.format.DateTimeFormatter fmt =
                java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy");

        while (true) {
            String raw = readLine(prompt).trim();
            if (raw.isEmpty()) { error("  Date cannot be blank."); continue; }

            java.time.LocalDate date;
            try {
                date = java.time.LocalDate.parse(raw, fmt);
            } catch (java.time.format.DateTimeParseException e) {
                error("  Invalid date. Please use dd-MM-yyyy (e.g. 15-08-2005).");
                continue;
            }

            java.time.LocalDate today = java.time.LocalDate.now();

            // Age check (for DOB: date must be in the past, age >= minAge, age <= maxAge)
            if (minAge > 0 || maxAge > 0) {
                if (!date.isBefore(today)) {
                    error("  Date of birth must be a past date.");
                    continue;
                }
                int age = java.time.Period.between(date, today).getYears();
                if (minAge > 0 && age < minAge) {
                    error("  You must be at least " + minAge + " years old. "
                            + "Calculated age: " + age + " years.");
                    continue;
                }
                if (maxAge > 0 && age > maxAge) {
                    error("  Age cannot exceed " + maxAge + " years. "
                            + "Calculated age: " + age + " years.");
                    continue;
                }
            }

            // Future-only check (for travel date: must be after today)
            if (futureOnly) {
                if (!date.isAfter(today)) {
                    error("  Travel date must be a future date (after today: "
                            + today.format(fmt) + ").");
                    continue;
                }
                // Max months check
                if (maxMonths > 0) {
                    java.time.LocalDate limit = today.plusMonths(maxMonths);
                    if (date.isAfter(limit)) {
                        error("  Travel date cannot be more than " + maxMonths
                                + " months from today (latest: "
                                + limit.format(fmt) + ").");
                        continue;
                    }
                }
            }

            return date;
        }
    }

    /**
     * Reads a LocalDateTime in "dd-MM-yyyy HH:mm", enforcing:
     *   - a minimum gap of minHoursAhead hours from now (0 = no min check)
     *   - a maximum of maxMonths months from now (0 = no max check)
     *   - must be after current date-time (always)
     * Loops until valid.
     */
    public static java.time.LocalDateTime readDateTimeWithMinGap(
            String prompt, int minHoursAhead) {
        return readDateTimeInRange(prompt, minHoursAhead, 0);
    }

    /**
     * Reads a LocalDateTime with both a minimum gap and a maximum months limit.
     *
     * @param prompt        text shown to user
     * @param minHoursAhead minimum hours from now (0 = just must be after now)
     * @param maxMonths     maximum months from now (0 = no upper limit)
     */
    public static java.time.LocalDateTime readDateTimeInRange(
            String prompt, int minHoursAhead, int maxMonths) {

        java.time.format.DateTimeFormatter fmt =
                java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy HH:mm");

        while (true) {
            String raw = readLine(prompt).trim();
            if (raw.isEmpty()) { error("  Date-time cannot be blank."); continue; }

            java.time.LocalDateTime dt;
            try {
                dt = java.time.LocalDateTime.parse(raw, fmt);
            } catch (java.time.format.DateTimeParseException e) {
                error("  Invalid format. Use dd-MM-yyyy HH:mm (e.g. 20-08-2026 14:30).");
                continue;
            }

            java.time.LocalDateTime now = java.time.LocalDateTime.now();

            // Must be in the future
            if (!dt.isAfter(now)) {
                error("  Date-time must be in the future (after " + now.format(fmt) + ").");
                continue;
            }

            // Minimum hours ahead check
            if (minHoursAhead > 0) {
                java.time.LocalDateTime earliest = now.plusHours(minHoursAhead);
                if (!dt.isAfter(earliest)) {
                    error("  Date-time must be at least " + minHoursAhead
                            + " hours from now. Earliest allowed: "
                            + earliest.format(fmt) + ".");
                    continue;
                }
            }

            // Maximum months ahead check
            if (maxMonths > 0) {
                java.time.LocalDateTime latest = now.plusMonths(maxMonths);
                if (dt.isAfter(latest)) {
                    error("  Date-time cannot be more than " + maxMonths
                            + " month(s) from now. Latest allowed: "
                            + latest.format(fmt) + ".");
                    continue;
                }
            }

            return dt;
        }
    }

    // ── Simple table printer ───────────────────────────────────────
    // DS Unit 1: Arrays — headers and rows are 1-D / 2-D String arrays.

    public static void printTable(String[] headers, String[][] rows, int[] minWidths) {
        // compute column widths
        int cols = headers.length;
        int[] w  = new int[cols];
        for (int c = 0; c < cols; c++) {
            w[c] = (c < minWidths.length) ? minWidths[c] : 0;
            w[c] = Math.max(w[c], headers[c].length());
            for (String[] row : rows)
                if (c < row.length) w[c] = Math.max(w[c], row[c].length());
        }

        String sep = buildSep(w, cols);
        System.out.println(BLUE + sep + RESET);

        // header row
        StringBuilder hb = new StringBuilder("│");
        for (int c = 0; c < cols; c++)
            hb.append(BOLD + CYAN + " ").append(pad(headers[c], w[c])).append(" " + RESET + BLUE + "│" + RESET);
        System.out.println(hb);
        System.out.println(BLUE + sep + RESET);

        // data rows
        for (String[] row : rows) {
            StringBuilder rb = new StringBuilder("│");
            for (int c = 0; c < cols; c++) {
                String cell = (c < row.length) ? row[c] : "";
                rb.append(" ").append(pad(cell, w[c])).append(" ").append(BLUE + "│" + RESET);
            }
            System.out.println(rb);
        }
        System.out.println(BLUE + sep + RESET);
    }

    private static String buildSep(int[] w, int cols) {
        StringBuilder sb = new StringBuilder("├");
        for (int i = 0; i < cols; i++) {
            sb.append("─".repeat(w[i] + 2));
            sb.append(i < cols - 1 ? "┼" : "┤");
        }
        return sb.toString();
    }

    private static String pad(String s, int len) {
        if (s == null) s = "";
        if (s.length() >= len) return s.substring(0, len);
        return s + " ".repeat(len - s.length());
    }
}
