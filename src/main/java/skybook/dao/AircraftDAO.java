package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Aircraft;
import skybook.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * AircraftDAO — CRUD operations on the Aircraft table.
 *
 * Java-II U9:  PreparedStatement with RETURN_GENERATED_KEYS for INSERT.
 * Java-II U6:  Returns ArrayList<Aircraft> from findByAirline.
 * DBMS U3:     DDL-mapped: Aircraft(AircraftID PK, AirlineID FK, ...).
 * DBMS U7:     JOIN with Airlines table to enrich display name.
 * DBMS U8:     AirlineID FK ensures aircraft always belongs to a valid airline.
 */
public class AircraftDAO {

    // ── Read ──────────────────────────────────────────────────────────────────

    /**
     * Returns all aircraft belonging to a given airline.
     * Java-II U6: Populates and returns ArrayList<Aircraft>.
     * DBMS U7:    JOIN Airlines to get AirlineName for display.
     */
    public List<Aircraft> findByAirline(int airlineId) throws DatabaseException {
        String sql = """
                SELECT ac.*, al.AirlineName
                FROM   Aircraft ac
                JOIN   Airlines al ON ac.AirlineID = al.AirlineID
                WHERE  ac.AirlineID = ?
                ORDER  BY ac.AircraftID
                """;
        List<Aircraft> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, airlineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("AircraftDAO.findByAirline", e);
        }
    }

    /**
     * Finds a single aircraft by ID.
     * DBMS U3: DQL SELECT with WHERE.
     */
    public Aircraft findById(int aircraftId) throws DatabaseException {
        String sql = """
                SELECT ac.*, al.AirlineName
                FROM   Aircraft ac
                JOIN   Airlines al ON ac.AirlineID = al.AirlineID
                WHERE  ac.AircraftID = ?
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("AircraftDAO.findById", e);
        }
    }

    // ── Write ─────────────────────────────────────────────────────────────────

    /**
     * Inserts a new aircraft and returns its generated AircraftID.
     * Java-II U9: PreparedStatement + RETURN_GENERATED_KEYS.
     * DBMS U3:    DML INSERT with FK to Airlines.
     */
    public int insert(Aircraft a) throws DatabaseException {
        String sql = """
                INSERT INTO Aircraft
                    (AirlineID, RegistrationNo, AircraftModel,
                     TotalSeats, Status, ManufactureYear)
                VALUES (?, ?, ?, ?, ?, ?)
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, a.getAirlineId());
            ps.setString(2, a.getRegistrationNo());
            ps.setString(3, a.getAircraftModel());
            ps.setInt(4, a.getTotalSeats());
            ps.setString(5, a.getStatus() != null ? a.getStatus() : "Active");
            if (a.getManufactureYear() > 0)
                ps.setInt(6, a.getManufactureYear());
            else
                ps.setNull(6, Types.INTEGER);

            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    int id = keys.getInt(1);
                    a.setAircraftId(id);
                    return id;
                }
            }
            return -1;

        } catch (SQLIntegrityConstraintViolationException e) {
            throw new DatabaseException("AircraftDAO.insert — duplicate RegistrationNo or invalid AirlineID", e);
        } catch (SQLException e) {
            throw new DatabaseException("AircraftDAO.insert", e);
        }
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    private Aircraft map(ResultSet rs) throws SQLException {
        Aircraft a = new Aircraft();
        a.setAircraftId(rs.getInt("AircraftID"));
        a.setAirlineId(rs.getInt("AirlineID"));
        a.setRegistrationNo(rs.getString("RegistrationNo"));
        a.setAircraftModel(rs.getString("AircraftModel"));
        a.setTotalSeats(rs.getInt("TotalSeats"));
        a.setStatus(rs.getString("Status"));
        a.setManufactureYear(rs.getInt("ManufactureYear"));
        // Joined field — present only when queried with JOIN Airlines
        try { a.setAirlineName(rs.getString("AirlineName")); }
        catch (SQLException ignored) {}
        return a;
    }
}
