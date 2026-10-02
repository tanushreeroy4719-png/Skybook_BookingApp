package skybook.util;

import skybook.exception.Exceptions.*;
import skybook.model.Airline;
import skybook.dao.AirlineDAO;

import java.math.BigDecimal;
import java.sql.*;

/**
 * SeatGenerator — auto-generates Seats rows for a newly added aircraft.
 *
 * Surcharge tiers (from schema spec):
 *   Budget  (IndiGo/6E, SpiceJet/SG, GoFirst/G8, AirAsia/I5)
 *              Window=150, Aisle=75,  Middle=0
 *   Mid     (Vistara/UK, Akasa/QP, AirIndia Express/IX)
 *              Window=250, Aisle=100, Middle=0
 *   Premium (Air India/AI, Emirates/EK, Qatar/QR, Singapore/SQ, and all others)
 *              Window=500, Aisle=200, Middle=0
 *
 * Seat layout per row (Economy, 6-across: W A M | M A W)
 *   positions: 1W, 1A, 1M, 1M2, 1A2, 1W2
 * For aircraft with >120 seats a small Business section (rows 1-3) is prepended.
 *
 * DBMS U3: Batch INSERT into Seats (weak entity keyed on AircraftID + SeatNumber).
 */
public class SeatGenerator {

    // Budget IATA codes
    private static final java.util.Set<String> BUDGET = java.util.Set.of("6E","SG","G8","I5");
    // Mid IATA codes
    private static final java.util.Set<String> MID    = java.util.Set.of("UK","QP","IX");
    // Everything else → Premium

    /**
     * Generates and inserts all seat rows for the given aircraft.
     * Uses the airline's IATA code to pick the surcharge tier.
     *
     * @param aircraftId   the newly inserted AircraftID
     * @param totalSeats   Aircraft.TotalSeats
     * @param airlineId    to look up IATA code for tier
     */
    public static void generate(int aircraftId, int totalSeats, int airlineId)
            throws DatabaseException {

        // Look up IATA code
        AirlineDAO dao = new AirlineDAO();
        Airline airline = dao.findById(airlineId);
        String iata = (airline != null && airline.getIataCode() != null)
                ? airline.getIataCode().toUpperCase() : "";

        // Determine surcharge tier
        BigDecimal windowSurcharge, aisleSurcharge;
        if (BUDGET.contains(iata)) {
            windowSurcharge = new BigDecimal("150.00");
            aisleSurcharge  = new BigDecimal("75.00");
        } else if (MID.contains(iata)) {
            windowSurcharge = new BigDecimal("250.00");
            aisleSurcharge  = new BigDecimal("100.00");
        } else {
            // Premium (Air India/AI, Emirates/EK, Qatar/QR, SIA/SQ, new airlines)
            windowSurcharge = new BigDecimal("500.00");
            aisleSurcharge  = new BigDecimal("200.00");
        }
        BigDecimal middleSurcharge = BigDecimal.ZERO;

        String sql = "INSERT INTO Seats (AircraftID, SeatNumber, SeatClass, SeatPosition, SeatSurcharge, IsAvailable) "
                   + "VALUES (?, ?, ?, ?, ?, TRUE)";

        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            int seatsInserted = 0;

            // --- Business section (rows 1-3, 4-across: W A | A W) ---
            // Only add Business if aircraft is large enough (>120 seats)
            int businessRows = 0;
            if (totalSeats > 120) {
                businessRows = 3;
                for (int row = 1; row <= businessRows; row++) {
                    // W A | A W  (4 seats per row)
                    addSeat(ps, aircraftId, row + "W",  "Business", "Window", windowSurcharge); seatsInserted++;
                    addSeat(ps, aircraftId, row + "A",  "Business", "Aisle",  aisleSurcharge);  seatsInserted++;
                    addSeat(ps, aircraftId, row + "A2", "Business", "Aisle",  aisleSurcharge);  seatsInserted++;
                    addSeat(ps, aircraftId, row + "W2", "Business", "Window", windowSurcharge); seatsInserted++;
                }
            }

            // --- Economy section (6-across: W A M | M A W) ---
            int economySeats = totalSeats - seatsInserted;
            int econRows     = (int) Math.ceil(economySeats / 6.0);
            int startRow     = businessRows + 1;

            for (int row = startRow; row < startRow + econRows && seatsInserted < totalSeats; row++) {
                addSeat(ps, aircraftId, row + "W",  "Economy", "Window", windowSurcharge); seatsInserted++;
                if (seatsInserted >= totalSeats) break;
                addSeat(ps, aircraftId, row + "A",  "Economy", "Aisle",  aisleSurcharge);  seatsInserted++;
                if (seatsInserted >= totalSeats) break;
                addSeat(ps, aircraftId, row + "M",  "Economy", "Middle", middleSurcharge); seatsInserted++;
                if (seatsInserted >= totalSeats) break;
                addSeat(ps, aircraftId, row + "M2", "Economy", "Middle", middleSurcharge); seatsInserted++;
                if (seatsInserted >= totalSeats) break;
                addSeat(ps, aircraftId, row + "A2", "Economy", "Aisle",  aisleSurcharge);  seatsInserted++;
                if (seatsInserted >= totalSeats) break;
                addSeat(ps, aircraftId, row + "W2", "Economy", "Window", windowSurcharge); seatsInserted++;
            }

            ps.executeBatch();   // single batch commit

        } catch (SQLException e) {
            throw new DatabaseException("SeatGenerator.generate", e);
        }
    }

    /** Adds one seat to the batch. */
    private static void addSeat(PreparedStatement ps, int aircraftId,
                                 String seatNumber, String seatClass,
                                 String position, BigDecimal surcharge)
            throws SQLException {
        ps.setInt(1, aircraftId);
        ps.setString(2, seatNumber);
        ps.setString(3, seatClass);
        ps.setString(4, position);
        ps.setBigDecimal(5, surcharge);
        ps.addBatch();
    }
}
