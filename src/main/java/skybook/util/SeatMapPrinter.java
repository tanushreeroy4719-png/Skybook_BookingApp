package skybook.util;

import skybook.model.Seat;

import java.util.List;
import java.util.HashMap;
import java.util.Map;

/**
 * SeatMapPrinter — displays an aircraft cabin as a 2-D grid.
 *
 * DS U1 / U2: 2-D array representation of a matrix (rows × seats-per-row).
 *             Seats are placed into a String[][] grid, then printed row by row.
 *
 * Each cell shows:  rowNum + posCode + [A/W/M]
 *   Available  : "3W " in green
 *   Booked     : " X " in red  (with passenger name if known)
 *
 * Seat naming convention used in the DB:
 *   1W, 1A          — single window or aisle (business-like rows)
 *   2W, 2M, 2A, 2A2, 2M2, 2W2  — six-across economy rows
 *
 * We detect the row number (leading digits) and position suffix (W/A/M + optional index).
 */
public final class SeatMapPrinter {

    private SeatMapPrinter() {}

    /**
     * Prints the seat map for the given list of seats.
     *
     * @param seats  all seats for one aircraft (from SeatDAO)
     */
    public static void print(List<Seat> seats) {
        // ── Build a map: rowNum → list of seats in that row ────────────────
        // DS: HashMap (U6) for O(1) row lookup, ArrayList (U5) for ordered seat list
        Map<Integer, java.util.ArrayList<Seat>> rowMap = new HashMap<>();

        for (Seat s : seats) {
            int row = extractRow(s.getSeatNumber());
            rowMap.computeIfAbsent(row, k -> new java.util.ArrayList<>()).add(s);
        }

        // Sort rows (DS: we use a simple array-based sort on key set)
        Integer[] rowNums = rowMap.keySet().toArray(new Integer[0]);
        java.util.Arrays.sort(rowNums);     // built-in sort (DS: sorting concept)

        // ── Legend ─────────────────────────────────────────────────────────
        System.out.println();
        System.out.println(Console.BOLD + "  SEAT MAP" + Console.RESET);
        System.out.println(Console.BLUE + "  " + "─".repeat(60) + Console.RESET);
        System.out.println("  Legend:  "
                + Console.GREEN + "[nW]" + Console.RESET + " Window(+surcharge)  "
                + Console.CYAN  + "[nA]" + Console.RESET + " Aisle(+surcharge)   "
                + Console.RESET + "[nM]" + Console.RESET + " Middle(free)  "
                + Console.RED   + " X  " + Console.RESET + " Booked");
        System.out.println(Console.BLUE + "  " + "─".repeat(60) + Console.RESET);

        // ── Header: LEFT WINDOW | AISLE | MIDDLE | MIDDLE | AISLE | RIGHT WINDOW
        System.out.printf("  %-6s  %-6s  %-6s  %s  %-6s  %-6s  %-6s%n",
                "WIN-L", "AIL-L", "MID-L", "║", "MID-R", "AIL-R", "WIN-R");
        System.out.println(Console.BLUE + "  " + "─".repeat(60) + Console.RESET);

        // ── Print each row ─────────────────────────────────────────────────
        for (int row : rowNums) {
            java.util.ArrayList<Seat> rowSeats = rowMap.get(row);

            // Build a position-indexed map for this row
            // Key: "W1", "A1", "M1", "W2", "A2", "M2"  etc.
            Map<String, Seat> posMap = new HashMap<>();
            for (Seat s : rowSeats) {
                String pos = extractPosKey(s.getSeatNumber());
                posMap.put(pos, s);
            }

            // Determine if this is a wide (6-across) or narrow (2-across) row
            boolean wide = posMap.containsKey("M1") || posMap.containsKey("M2");

            if (wide) {
                // 6-across: W1 | A1 | M1 ║ M2 | A2 | W2
                String w1 = cellStr(posMap.get("W1"));
                String a1 = cellStr(posMap.get("A1"));
                String m1 = cellStr(posMap.get("M1"));
                String m2 = cellStr(posMap.get("M2"));
                String a2 = cellStr(posMap.get("A2"));
                String w2 = cellStr(posMap.get("W2"));
                System.out.printf("  %s  %s  %s  %s  %s  %s  %s%n",
                        w1, a1, m1, Console.BLUE + "║" + Console.RESET, m2, a2, w2);
            } else {
                // 2-across: W1 | A1
                String w1 = cellStr(posMap.get("W1"));
                String a1 = cellStr(posMap.get("A1"));
                System.out.printf("  %s  %s%n", w1, a1);
            }
        }

        System.out.println(Console.BLUE + "  " + "─".repeat(60) + Console.RESET);
        System.out.println("  To choose a seat enter e.g:  1W  3A  5M  2A2  (row + position)");
        System.out.println();
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    /** Formats one cell as a 6-char coloured string. */
    private static String cellStr(Seat s) {
        if (s == null) return Console.RESET + "      ";          // empty slot
        String label = s.getSeatNumber();                        // e.g. "3W", "5A2"
        if (!s.isAvailable()) {
            // Show booked seat as red X
            return String.format("%s %-5s%s", Console.RED, label + "✗", Console.RESET);
        }
        // Colour by position
        String colour = switch (s.getSeatPosition()) {
            case Window -> Console.GREEN;
            case Aisle  -> Console.CYAN;
            case Middle -> Console.RESET;
        };
        return String.format("%s%-6s%s", colour, label, Console.RESET);
    }

    /** Extracts the integer row number from a seat number like "3W", "10A2". */
    public static int extractRow(String seatNo) {
        StringBuilder digits = new StringBuilder();
        for (char c : seatNo.toCharArray()) {
            if (Character.isDigit(c)) digits.append(c);
            else break;
        }
        try { return Integer.parseInt(digits.toString()); }
        catch (NumberFormatException e) { return 0; }
    }

    /**
     * Maps seat number to canonical position key used in posMap.
     * "1W" → "W1",  "2A2" → "A2",  "2M" → "M1",  "2W2" → "W2"
     * DS: String manipulation as char array traversal.
     */
    static String extractPosKey(String seatNo) {
        // strip leading digits to get suffix like "W", "A2", "M", "W2"
        int i = 0;
        while (i < seatNo.length() && Character.isDigit(seatNo.charAt(i))) i++;
        String suffix = seatNo.substring(i);  // e.g. "W", "A2", "M", "W2"

        if (suffix.length() == 1) {
            // Single letter like "W", "A", "M"  → "W1", "A1", "M1"
            return suffix + "1";
        } else {
            // Letter + digit like "W2", "A2", "M2"
            char pos    = suffix.charAt(0);                        // W / A / M
            String idx  = suffix.substring(1);                     // "2"
            return pos + idx;                                      // "W2"
        }
    }
}
