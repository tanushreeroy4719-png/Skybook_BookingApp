package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Ticket;
import skybook.util.DBConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * TicketDAO — inserts and retrieves Tickets.
 * Java-II U10: JDBC Advanced — Transactions, RETURN_GENERATED_KEYS, multi-table JOIN.
 * DBMS U7:     5-table JOIN for full ticket display.
 */
public class TicketDAO {

    public int insertTicket(int bookingId, int aircraftId, String seatNumber,
                            BigDecimal pricePaid, String pnr,
                            BigDecimal extraKg, BigDecimal extraCost,
                            Connection c) throws SQLException {
        String sql = """
                INSERT INTO Tickets (BookingID, AircraftID, SeatNumber, PricePaid,
                                     PNR, ExtraLuggageKG, ExtraLuggageCost)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, bookingId);
            ps.setInt(2, aircraftId);
            ps.setString(3, seatNumber);
            ps.setBigDecimal(4, pricePaid);
            ps.setString(5, pnr);
            ps.setBigDecimal(6, extraKg);
            ps.setBigDecimal(7, extraCost);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        return -1;
    }

    /**
     * Retrieves a full ticket with all joined display fields.
     * DBMS U7: 6-table JOIN.
     */
    public Ticket findByBooking(int bookingId) throws DatabaseException {
        String sql = """
                SELECT t.TicketID, t.BookingID, t.AircraftID, t.SeatNumber,
                       t.PricePaid, t.PNR, t.ExtraLuggageKG, t.ExtraLuggageCost,
                       CONCAT(p.FirstName,' ',p.LastName) AS PassengerName,
                       CONCAT(f.DepartureAirportID,' → ',f.ArrivalAirportID) AS FlightRoute,
                       DATE_FORMAT(f.DepartureTime,'%d-%b-%Y %H:%i') AS DepartureTime,
                       al.AirlineName,
                       s.SeatClass, s.SeatPosition,
                       COALESCE((SELECT SUM(m.Price * bm.Quantity)
                                 FROM BookingMeals bm
                                 JOIN Meals m ON bm.MealID = m.MealID
                                 WHERE bm.BookingID = t.BookingID), 0) AS MealCost
                FROM Tickets t
                JOIN Bookings   b  ON t.BookingID         = b.BookingID
                JOIN Passengers p  ON b.PassengerID       = p.PassengerID
                JOIN Flights    f  ON b.FlightID          = f.FlightID
                JOIN Aircraft   ac ON t.AircraftID        = ac.AircraftID
                JOIN Airlines   al ON ac.AirlineID        = al.AirlineID
                JOIN Seats      s  ON t.AircraftID        = s.AircraftID
                                   AND t.SeatNumber       = s.SeatNumber
                WHERE t.BookingID = ?
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapTicket(rs);
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("TicketDAO.findByBooking", e);
        }
    }

    public Ticket findByPNR(String pnr) throws DatabaseException {
        String sql = "SELECT BookingID FROM Tickets WHERE PNR = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, pnr);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return findByBooking(rs.getInt("BookingID"));
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("TicketDAO.findByPNR", e);
        }
    }

    private Ticket mapTicket(ResultSet rs) throws SQLException {
        Ticket t = new Ticket();
        t.setTicketId(rs.getInt("TicketID"));
        t.setBookingId(rs.getInt("BookingID"));
        t.setAircraftId(rs.getInt("AircraftID"));
        t.setSeatNumber(rs.getString("SeatNumber"));
        t.setPricePaid(rs.getBigDecimal("PricePaid"));
        t.setPnr(rs.getString("PNR"));
        t.setExtraLuggageKg(rs.getBigDecimal("ExtraLuggageKG"));
        t.setExtraLuggageCost(rs.getBigDecimal("ExtraLuggageCost"));
        t.setPassengerName(rs.getString("PassengerName"));
        t.setFlightRoute(rs.getString("FlightRoute"));
        t.setDepartureTime(rs.getString("DepartureTime"));
        t.setAirlineName(rs.getString("AirlineName"));
        t.setSeatClass(rs.getString("SeatClass"));
        t.setSeatPosition(rs.getString("SeatPosition"));
        t.setMealCost(rs.getBigDecimal("MealCost"));
        return t;
    }
}
