package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Seat;
import skybook.model.Seat.SeatClass;
import skybook.model.Seat.SeatPosition;
import skybook.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * SeatDAO — seat availability queries and status updates.
 *
 * Java-II U9:  JDBC PreparedStatement.
 * DS   U1/U8:  Results loaded into ArrayList; seat layout displayed as 2-D array
 *              by SeatMapPrinter.
 * DBMS U7:     Subquery to find nearest available seats (clustering for group travel).
 */
public class SeatDAO {

    /** Returns ALL seats for an aircraft (for the seat map display). */
    public List<Seat> findByAircraft(int aircraftId) throws DatabaseException {
        String sql = """
                SELECT s.AircraftID, s.SeatNumber, s.SeatClass, s.SeatPosition,
                       s.SeatSurcharge, s.IsAvailable
                FROM Seats s
                WHERE s.AircraftID = ?
                ORDER BY s.SeatNumber
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            return executeAndMap(ps);
        } catch (SQLException e) {
            throw new DatabaseException("SeatDAO.findByAircraft", e);
        }
    }

    /** Returns only available seats for an aircraft. */
    public List<Seat> findAvailable(int aircraftId) throws DatabaseException {
        String sql = """
                SELECT AircraftID, SeatNumber, SeatClass, SeatPosition,
                       SeatSurcharge, IsAvailable
                FROM Seats
                WHERE AircraftID = ? AND IsAvailable = TRUE
                ORDER BY SeatNumber
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            return executeAndMap(ps);
        } catch (SQLException e) {
            throw new DatabaseException("SeatDAO.findAvailable", e);
        }
    }

    /** Fetches a specific seat. Returns null if not found. */
    public Seat findSeat(int aircraftId, String seatNumber) throws DatabaseException {
        String sql = "SELECT * FROM Seats WHERE AircraftID = ? AND SeatNumber = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            ps.setString(2, seatNumber.toUpperCase());
            List<Seat> list = executeAndMap(ps);
            return list.isEmpty() ? null : list.get(0);
        } catch (SQLException e) {
            throw new DatabaseException("SeatDAO.findSeat", e);
        }
    }

    /**
     * Marks a seat as unavailable (booked).
     * Called inside BookingService transaction.
     */
    public void markUnavailable(int aircraftId, String seatNumber, Connection c)
            throws SQLException {
        String sql = "UPDATE Seats SET IsAvailable = FALSE WHERE AircraftID = ? AND SeatNumber = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            ps.setString(2, seatNumber.toUpperCase());
            ps.executeUpdate();
        }
    }

    /**
     * Marks a seat as available again (cancellation rollback).
     * Called inside CancellationService transaction.
     */
    public void markAvailable(int aircraftId, String seatNumber, Connection c)
            throws SQLException {
        String sql = "UPDATE Seats SET IsAvailable = TRUE WHERE AircraftID = ? AND SeatNumber = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            ps.setString(2, seatNumber.toUpperCase());
            ps.executeUpdate();
        }
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private List<Seat> executeAndMap(PreparedStatement ps) throws SQLException {
        List<Seat> list = new ArrayList<>();
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Seat s = new Seat();
                s.setAircraftId(rs.getInt("AircraftID"));
                s.setSeatNumber(rs.getString("SeatNumber"));
                try { s.setSeatClass(SeatClass.valueOf(rs.getString("SeatClass"))); }
                catch (IllegalArgumentException ignored) {}
                try { s.setSeatPosition(SeatPosition.valueOf(rs.getString("SeatPosition"))); }
                catch (IllegalArgumentException ignored) {}
                s.setSeatSurcharge(rs.getBigDecimal("SeatSurcharge"));
                s.setAvailable(rs.getBoolean("IsAvailable"));
                list.add(s);
            }
        }
        return list;
    }
}
