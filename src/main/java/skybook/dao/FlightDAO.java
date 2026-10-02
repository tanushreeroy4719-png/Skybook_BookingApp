package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Flight;
import skybook.model.Flight.FlightCategory;
import skybook.model.Flight.FlightType;
import skybook.util.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * FlightDAO — all flight-related DB operations.
 *
 * Java-II U9:  JDBC — PreparedStatement for all queries (SQL injection prevention).
 * Java-II U6:  Collections — results returned as ArrayList<Flight>.
 * DBMS U7:     Joins — flights joined with Aircraft, Airlines, Airports for rich display.
 * DBMS U4:     Date functions — search uses DATE() to match departure date.
 * DS   U1:     Array — available flight results stored in ArrayList (dynamic array).
 */
public class FlightDAO {

    // ── Search ────────────────────────────────────────────────────────────────

    /**
     * Searches for flights between two airports on the given date ±1 day.
     * Returns:
     *   1. Direct flights from→to
     *   2. Leg-1 Connecting flights whose immediate arrival matches toCode
     *   3. Leg-1 Connecting flights whose leg-2 (ConnectingFlightID) arrives at toCode
     *      — this makes full-route connecting itineraries findable when the user
     *        searches by final destination (e.g. DEL→LHR finds DEL→DXB→LHR)
     *   4. Leg-2 flights (standalone departure from the connecting airport) that
     *      match fromCode→toCode, so DXB→LHR is also directly searchable.
     *
     * DBMS U7: JOIN across Flights, Aircraft, Airlines, Airports (departure + arrival).
     */
    public List<Flight> search(String fromCode, String toCode, LocalDate date)
            throws DatabaseException {

        // Query 1: direct origin→dest match (covers both Direct and Connecting leg-1/leg-2)
        String sql = """
                SELECT f.FlightID, f.AircraftID, f.DepartureAirportID, f.ArrivalAirportID,
                       f.DepartureTime, f.ArrivalTime, f.StateTaxAmount, f.BasePrice,
                       f.FlightType, f.FlightCategory, f.ConnectingFlightID, f.MealsAvailable,
                       al.AirlineName, al.AirlineID,
                       dep.City AS DepartureCity, arr.City AS ArrivalCity,
                       ac.AircraftModel,
                       (SELECT COUNT(*) FROM Seats s
                        WHERE s.AircraftID = f.AircraftID AND s.IsAvailable = TRUE) AS AvailSeats
                FROM Flights f
                JOIN Aircraft  ac  ON f.AircraftID         = ac.AircraftID
                JOIN Airlines  al  ON ac.AirlineID         = al.AirlineID
                JOIN Airports  dep ON f.DepartureAirportID = dep.AirportCode
                JOIN Airports  arr ON f.ArrivalAirportID   = arr.AirportCode
                WHERE f.DepartureAirportID = ?
                  AND f.ArrivalAirportID   = ?
                  AND DATE(f.DepartureTime) BETWEEN ? AND ?
                  AND al.IsActive = TRUE
                  AND ac.Status   = 'Active'
                ORDER BY f.DepartureTime
                """;

        // Query 2: connecting leg-1 flights from fromCode whose leg-2 arrives at toCode
        // e.g. searching DEL→LHR finds Flight 7 (DEL→DXB) which has ConnectingFlightID=9 (DXB→LHR)
        String sqlViaConnect = """
                SELECT f.FlightID, f.AircraftID, f.DepartureAirportID, f.ArrivalAirportID,
                       f.DepartureTime, f.ArrivalTime, f.StateTaxAmount, f.BasePrice,
                       f.FlightType, f.FlightCategory, f.ConnectingFlightID, f.MealsAvailable,
                       al.AirlineName, al.AirlineID,
                       dep.City AS DepartureCity, arr.City AS ArrivalCity,
                       ac.AircraftModel,
                       (SELECT COUNT(*) FROM Seats s
                        WHERE s.AircraftID = f.AircraftID AND s.IsAvailable = TRUE) AS AvailSeats
                FROM Flights f
                JOIN Aircraft  ac   ON f.AircraftID         = ac.AircraftID
                JOIN Airlines  al   ON ac.AirlineID         = al.AirlineID
                JOIN Airports  dep  ON f.DepartureAirportID = dep.AirportCode
                JOIN Airports  arr  ON f.ArrivalAirportID   = arr.AirportCode
                JOIN Flights   leg2 ON f.ConnectingFlightID = leg2.FlightID
                WHERE f.DepartureAirportID  = ?
                  AND leg2.ArrivalAirportID = ?
                  AND DATE(f.DepartureTime) BETWEEN ? AND ?
                  AND al.IsActive = TRUE
                  AND ac.Status   = 'Active'
                ORDER BY f.DepartureTime
                """;

        LocalDate from = date.minusDays(1);
        LocalDate to   = date.plusDays(1);

        try (Connection c = DBConnection.getConnection()) {

            // Collect results, deduplicating by FlightID
            java.util.LinkedHashMap<Integer, Flight> seen = new java.util.LinkedHashMap<>();

            // 1. Direct / same-leg matches
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, fromCode.toUpperCase());
                ps.setString(2, toCode.toUpperCase());
                ps.setDate(3, Date.valueOf(from));
                ps.setDate(4, Date.valueOf(to));
                for (Flight f : executeAndMap(ps)) seen.put(f.getFlightId(), f);
            }

            // 2. Leg-1 of a connecting itinerary whose final destination is toCode
            try (PreparedStatement ps = c.prepareStatement(sqlViaConnect)) {
                ps.setString(1, fromCode.toUpperCase());
                ps.setString(2, toCode.toUpperCase());
                ps.setDate(3, Date.valueOf(from));
                ps.setDate(4, Date.valueOf(to));
                for (Flight f : executeAndMap(ps)) seen.putIfAbsent(f.getFlightId(), f);
            }

            return new ArrayList<>(seen.values());

        } catch (SQLException e) {
            throw new DatabaseException("FlightDAO.search", e);
        }
    }

    /**
     * Returns a flight by ID — used to look up leg-2 of Connecting itineraries.
     */
    public Flight findById(int flightId) throws DatabaseException, FlightNotFoundException {
        String sql = """
                SELECT f.FlightID, f.AircraftID, f.DepartureAirportID, f.ArrivalAirportID,
                       f.DepartureTime, f.ArrivalTime, f.StateTaxAmount, f.BasePrice,
                       f.FlightType, f.FlightCategory, f.ConnectingFlightID, f.MealsAvailable,
                       al.AirlineName, al.AirlineID,
                       dep.City AS DepartureCity, arr.City AS ArrivalCity,
                       ac.AircraftModel,
                       (SELECT COUNT(*) FROM Seats s
                        WHERE s.AircraftID = f.AircraftID AND s.IsAvailable = TRUE) AS AvailSeats
                FROM Flights f
                JOIN Aircraft  ac  ON f.AircraftID         = ac.AircraftID
                JOIN Airlines  al  ON ac.AirlineID         = al.AirlineID
                JOIN Airports  dep ON f.DepartureAirportID = dep.AirportCode
                JOIN Airports  arr ON f.ArrivalAirportID   = arr.AirportCode
                WHERE f.FlightID = ?
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setInt(1, flightId);
            List<Flight> list = executeAndMap(ps);
            if (list.isEmpty()) throw new FlightNotFoundException(flightId);
            return list.get(0);

        } catch (SQLException e) {
            throw new DatabaseException("FlightDAO.findById", e);
        }
    }

    /**
     * Returns all flights for a given airlineId (used by Airline menu).
     * Java-II U6: ArrayList returned as a Collection.
     */
    public List<Flight> findByAirline(int airlineId) throws DatabaseException {
        String sql = """
                SELECT f.FlightID, f.AircraftID, f.DepartureAirportID, f.ArrivalAirportID,
                       f.DepartureTime, f.ArrivalTime, f.StateTaxAmount, f.BasePrice,
                       f.FlightType, f.FlightCategory, f.ConnectingFlightID, f.MealsAvailable,
                       al.AirlineName, al.AirlineID,
                       dep.City AS DepartureCity, arr.City AS ArrivalCity,
                       ac.AircraftModel,
                       (SELECT COUNT(*) FROM Seats s
                        WHERE s.AircraftID = f.AircraftID AND s.IsAvailable = TRUE) AS AvailSeats
                FROM Flights f
                JOIN Aircraft  ac  ON f.AircraftID         = ac.AircraftID
                JOIN Airlines  al  ON ac.AirlineID         = al.AirlineID
                JOIN Airports  dep ON f.DepartureAirportID = dep.AirportCode
                JOIN Airports  arr ON f.ArrivalAirportID   = arr.AirportCode
                WHERE al.AirlineID = ?
                ORDER BY f.DepartureTime
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, airlineId);
            return executeAndMap(ps);
        } catch (SQLException e) {
            throw new DatabaseException("FlightDAO.findByAirline", e);
        }
    }

    // ── Airline write operations ───────────────────────────────────────────────

    /**
     * Inserts a new flight. Returns the generated FlightID.
     * Java-II U9: RETURN_GENERATED_KEYS pattern.
     */
    public int insert(Flight f) throws DatabaseException {
        String sql = """
                INSERT INTO Flights (AircraftID, DepartureAirportID, ArrivalAirportID,
                    DepartureTime, ArrivalTime, StateTaxAmount, BasePrice,
                    FlightType, FlightCategory, ConnectingFlightID)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,    f.getAircraftId());
            ps.setString(2, f.getDepartureAirportId());
            ps.setString(3, f.getArrivalAirportId());
            ps.setTimestamp(4, Timestamp.valueOf(f.getDepartureTime()));
            ps.setTimestamp(5, Timestamp.valueOf(f.getArrivalTime()));
            ps.setBigDecimal(6, f.getStateTaxAmount());
            ps.setBigDecimal(7, f.getBasePrice());
            ps.setString(8,  f.getFlightType().name());
            ps.setString(9,  f.getFlightCategory().name());
            if (f.getConnectingFlightId() != null)
                ps.setInt(10, f.getConnectingFlightId());
            else
                ps.setNull(10, Types.INTEGER);

            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
            return -1;

        } catch (SQLException e) {
            throw new DatabaseException("FlightDAO.insert", e);
        }
    }

    /**
     * Updates departure/arrival time (delay scenario).
     * Java-II U9: PreparedStatement with Timestamp binding.
     */
    public void updateTimes(int flightId, LocalDateTime newDep, LocalDateTime newArr)
            throws DatabaseException {
        String sql = "UPDATE Flights SET DepartureTime = ?, ArrivalTime = ? WHERE FlightID = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(newDep));
            ps.setTimestamp(2, Timestamp.valueOf(newArr));
            ps.setInt(3, flightId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("FlightDAO.updateTimes", e);
        }
    }


    /**
     * Updates base price of a flight.
     * Java-II U9: PreparedStatement with BigDecimal binding.
     * DBMS U3: DML UPDATE.
     */
    public void updatePrice(int flightId, java.math.BigDecimal newPrice) throws DatabaseException {
        String sql = "UPDATE Flights SET BasePrice = ? WHERE FlightID = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBigDecimal(1, newPrice);
            ps.setInt(2, flightId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("FlightDAO.updatePrice", e);
        }
    }

    /**
     * Deletes a flight by ID atomically.
     *
     * The FK constraint fk_bookings_flight has no ON DELETE CASCADE, so we must
     * manually cancel all bookings on this flight before deleting it.
     * All steps run in a single transaction so the state is never inconsistent.
     *
     * Java-II U10: JDBC Transaction — setAutoCommit(false) / commit / rollback.
     * DBMS U3:     DML — UPDATE Bookings then DELETE Flights in one transaction.
     */
    public void delete(int flightId) throws DatabaseException {
        String cancelBookings = "UPDATE Bookings SET Status = 'Cancelled' "
                              + "WHERE FlightID = ? AND Status = 'Confirmed'";
        String deleteTicketMeals = "DELETE bm FROM BookingMeals bm "
                              + "JOIN Bookings b ON bm.BookingID = b.BookingID "
                              + "WHERE b.FlightID = ?";
        String deleteFlight = "DELETE FROM Flights WHERE FlightID = ?";

        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try {
                // 1. Cancel all confirmed bookings for this flight
                try (PreparedStatement ps = c.prepareStatement(cancelBookings)) {
                    ps.setInt(1, flightId);
                    ps.executeUpdate();
                }
                // 2. Remove meal rows linked to those bookings (FK: BookingMeals.BookingID)
                try (PreparedStatement ps = c.prepareStatement(deleteTicketMeals)) {
                    ps.setInt(1, flightId);
                    ps.executeUpdate();
                }
                // 3. Delete the flight (Tickets cascade via fk_tickets_booking ON DELETE CASCADE;
                //    Payments cascade via fk_payments_ticket ON DELETE CASCADE)
                try (PreparedStatement ps = c.prepareStatement(deleteFlight)) {
                    ps.setInt(1, flightId);
                    ps.executeUpdate();
                }
                c.commit();
            } catch (SQLException ex) {
                try { c.rollback(); } catch (SQLException ignored) {}
                throw ex;
            } finally {
                try { c.setAutoCommit(true); } catch (SQLException ignored) {}
            }
        } catch (SQLException e) {
            throw new DatabaseException("FlightDAO.delete", e);
        }
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private List<Flight> executeAndMap(PreparedStatement ps) throws SQLException {
        List<Flight> list = new ArrayList<>();
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Flight f = new Flight();
                f.setFlightId(rs.getInt("FlightID"));
                f.setAircraftId(rs.getInt("AircraftID"));
                f.setDepartureAirportId(rs.getString("DepartureAirportID"));
                f.setArrivalAirportId(rs.getString("ArrivalAirportID"));
                f.setDepartureTime(rs.getTimestamp("DepartureTime").toLocalDateTime());
                f.setArrivalTime(rs.getTimestamp("ArrivalTime").toLocalDateTime());
                f.setStateTaxAmount(rs.getBigDecimal("StateTaxAmount"));
                f.setBasePrice(rs.getBigDecimal("BasePrice"));
                f.setFlightType(FlightType.valueOf(rs.getString("FlightType")));
                f.setFlightCategory(FlightCategory.valueOf(rs.getString("FlightCategory")));
                int connId = rs.getInt("ConnectingFlightID");
                f.setConnectingFlightId(rs.wasNull() ? null : connId);
                f.setMealsAvailable(rs.getBoolean("MealsAvailable"));
                f.setAirlineName(rs.getString("AirlineName"));
                f.setDepartureCity(rs.getString("DepartureCity"));
                f.setArrivalCity(rs.getString("ArrivalCity"));
                f.setAircraftModel(rs.getString("AircraftModel"));
                f.setAvailableSeats(rs.getInt("AvailSeats"));
                list.add(f);
            }
        }
        return list;
    }
}
