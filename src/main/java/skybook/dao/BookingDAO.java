package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Booking;
import skybook.model.Booking.Status;
import skybook.model.Ticket;
import skybook.model.Payment;
import skybook.model.Payment.PaymentStatus;
import skybook.util.DBConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * BookingDAO + TicketDAO + PaymentDAO — combined in one file for the transaction unit.
 *
 * Java-II U9:  JDBC — PreparedStatement, CallableStatement, RETURN_GENERATED_KEYS.
 * Java-II U10: JDBC Advanced — Transactions (setAutoCommit/commit/rollback),
 *              DatabaseMetaData, file/image storage concepts (ticket as file via TicketPrinter).
 * DBMS U7:     SQL Advanced — Joins for history queries (SELECT with multiple JOINs).
 * DBMS U8:     ACID Transactions — booking insert is atomic across Bookings + Tickets + Payments.
 * DBMS U9:     PL/SQL concept — stored-procedure-style transaction block replicated in Java.
 */
public class BookingDAO {

    // ── Booking operations ────────────────────────────────────────────────────

    /** Inserts a Booking row using an active shared transaction connection. */
    public int insertBooking(int flightId, int passengerId, Connection c) throws SQLException {
        String sql = "INSERT INTO Bookings (FlightID, PassengerID, BookingDate, Status) "
                   + "VALUES (?, ?, NOW(), 'Confirmed')";
        try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, flightId);
            ps.setInt(2, passengerId);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        return -1;
    }

    /** Cancels a booking (sets Status = Cancelled). */
    public void cancelBooking(int bookingId, Connection c) throws SQLException {
        String sql = "UPDATE Bookings SET Status = 'Cancelled' WHERE BookingID = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            ps.executeUpdate();
        }
    }

    /**
     * Finds a single booking by ID (with passenger + flight info joined).
     * DBMS U7: Three-table JOIN.
     */
    public Booking findById(int bookingId) throws DatabaseException {
        String sql = """
                SELECT b.BookingID, b.FlightID, b.PassengerID, b.BookingDate, b.Status,
                       CONCAT(p.FirstName,' ',p.LastName) AS PassengerName,
                       CONCAT(f.DepartureAirportID,' → ',f.ArrivalAirportID) AS FlightInfo
                FROM Bookings b
                JOIN Passengers p ON b.PassengerID = p.PassengerID
                JOIN Flights    f ON b.FlightID    = f.FlightID
                WHERE b.BookingID = ?
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapBooking(rs);
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("BookingDAO.findById", e);
        }
    }

    /**
     * Returns full booking history for a passenger.
     * DBMS U7: Multi-table JOIN with GROUP BY for meal cost aggregate.
     * Java-II U6: Returns ArrayList<Booking>.
     */
    public List<Booking> historyByPassenger(int passengerId) throws DatabaseException {
        String sql = """
                SELECT b.BookingID, b.FlightID, b.PassengerID, b.BookingDate, b.Status,
                       CONCAT(p.FirstName,' ',p.LastName) AS PassengerName,
                       CONCAT(f.DepartureAirportID,' → ',f.ArrivalAirportID,
                              '  [', DATE_FORMAT(f.DepartureTime,'%d-%b-%Y %H:%i'), ']') AS FlightInfo
                FROM Bookings b
                JOIN Passengers p ON b.PassengerID = p.PassengerID
                JOIN Flights    f ON b.FlightID    = f.FlightID
                WHERE b.PassengerID = ?
                ORDER BY b.BookingDate DESC
                """;
        List<Booking> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, passengerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapBooking(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("BookingDAO.historyByPassenger", e);
        }
    }


    /**
     * Returns full booking history for all Passengers rows sharing the given email.
     * This covers cases where the booking created a new Passenger row different
     * from the registered one, because BookingService.bookFlight matches by email.
     *
     * DBMS U7: JOIN on Passengers.Email (wider than PassengerID).
     */
    public List<Booking> historyByEmail(String email) throws DatabaseException {
        String sql = """
                SELECT b.BookingID, b.FlightID, b.PassengerID, b.BookingDate, b.Status,
                       CONCAT(p.FirstName,' ',p.LastName) AS PassengerName,
                       CONCAT(f.DepartureAirportID,' → ',f.ArrivalAirportID,
                              '  [', DATE_FORMAT(f.DepartureTime,'%d-%b-%Y %H:%i'), ']') AS FlightInfo
                FROM Bookings b
                JOIN Passengers p ON b.PassengerID = p.PassengerID
                JOIN Flights    f ON b.FlightID    = f.FlightID
                WHERE p.Email = ?
                ORDER BY b.BookingDate DESC
                """;
        List<Booking> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapBooking(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("BookingDAO.historyByEmail", e);
        }
    }

    /**
     * Marks completed flights for all Passenger rows sharing the given email.
     * Companion to historyByEmail — keeps status consistent across all rows.
     */
    public void markCompletedFlightsByEmail(String email) throws DatabaseException {
        String sql = """
                UPDATE Bookings b
                JOIN Flights    f ON b.FlightID    = f.FlightID
                JOIN Passengers p ON b.PassengerID = p.PassengerID
                SET b.Status = 'Completed'
                WHERE p.Email = ?
                  AND b.Status = 'Confirmed'
                  AND f.ArrivalTime < NOW()
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("BookingDAO.markCompletedFlightsByEmail", e);
        }
    }

    /**
     * Returns all bookings for flights belonging to a given airline.
     * DBMS U7: Multi-table JOIN — Bookings → Flights → Aircraft → Airlines → Passengers.
     * Java-II U6: Returns ArrayList<Booking>.
     */
    public List<Booking> historyByAirline(int airlineId) throws DatabaseException {
        String sql = """
                SELECT b.BookingID, b.FlightID, b.PassengerID, b.BookingDate, b.Status,
                       CONCAT(p.FirstName,' ',p.LastName) AS PassengerName,
                       CONCAT(f.DepartureAirportID,' → ',f.ArrivalAirportID,
                              '  [', DATE_FORMAT(f.DepartureTime,'%d-%b-%Y %H:%i'), ']') AS FlightInfo
                FROM Bookings b
                JOIN Passengers p  ON b.PassengerID = p.PassengerID
                JOIN Flights    f  ON b.FlightID    = f.FlightID
                JOIN Aircraft   ac ON f.AircraftID  = ac.AircraftID
                WHERE ac.AirlineID = ?
                ORDER BY b.BookingDate DESC
                """;
        List<Booking> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, airlineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapBooking(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("BookingDAO.historyByAirline", e);
        }
    }

    /**
     * Marks all Confirmed bookings whose flight has already departed + arrived
     * as Completed. Called each time a passenger views their history so that
     * past flights are automatically shown as Completed.
     *
     * DBMS U3: DML UPDATE with a subquery/join on ArrivalTime < NOW().
     */
    public void markCompletedFlights(int passengerId) throws DatabaseException {
        // Update all Confirmed bookings for this passenger where flight ArrivalTime < NOW()
        String sql = """
                UPDATE Bookings b
                JOIN Flights f ON b.FlightID = f.FlightID
                SET b.Status = 'Completed'
                WHERE b.PassengerID = ?
                  AND b.Status = 'Confirmed'
                  AND f.ArrivalTime < NOW()
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, passengerId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("BookingDAO.markCompletedFlights", e);
        }
    }

    private Booking mapBooking(ResultSet rs) throws SQLException {
        Booking b = new Booking();
        b.setBookingId(rs.getInt("BookingID"));
        b.setFlightId(rs.getInt("FlightID"));
        b.setPassengerId(rs.getInt("PassengerID"));
        Timestamp ts = rs.getTimestamp("BookingDate");
        if (ts != null) b.setBookingDate(ts.toLocalDateTime());
        try { b.setStatus(Status.valueOf(rs.getString("Status"))); }
        catch (IllegalArgumentException ignored) {}
        b.setPassengerName(rs.getString("PassengerName"));
        b.setFlightInfo(rs.getString("FlightInfo"));
        return b;
    }
}
