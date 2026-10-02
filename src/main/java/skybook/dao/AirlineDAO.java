package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Airline;
import skybook.model.Meal;
import skybook.model.Meal.MealCategory;
import skybook.model.Meal.DietType;
import skybook.model.Meal.MealType;
import skybook.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AirlineDAO — reads/writes the Airlines table.
 *
 * Java-II U6: HashMap<Integer,Airline> used as an in-memory cache after first load.
 * DBMS U3:    DDL via Statement for airline creation; DML for update/delete.
 */
public class AirlineDAO {

    // Simple in-memory cache — DS: HashMap (U6) for O(1) lookup by AirlineID
    private static final Map<Integer, Airline> CACHE = new HashMap<>();

    public Airline findById(int id) throws DatabaseException {
        // Always query DB directly — never serve from cache.
        // The cache previously caused stale IsActive values after deactivation.
        String sql = "SELECT * FROM Airlines WHERE AirlineID = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Airline a = map(rs);
                    CACHE.put(id, a);   // keep cache warm for other callers
                    return a;
                }
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("AirlineDAO.findById", e);
        }
    }

    public List<Airline> findAll() throws DatabaseException {
        String sql = "SELECT * FROM Airlines ORDER BY AirlineID";
        List<Airline> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             Statement s = c.createStatement();
             ResultSet rs = s.executeQuery(sql)) {
            while (rs.next()) {
                Airline a = map(rs);
                CACHE.put(a.getAirlineId(), a);
                list.add(a);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("AirlineDAO.findAll", e);
        }
    }

    public int insert(Airline a) throws DatabaseException,
            skybook.exception.Exceptions.DuplicateAccountException {
        try {
            return insert(a, DBConnection.getConnection());
        } catch (skybook.exception.Exceptions.DuplicateAccountException | DatabaseException e) {
            throw e;
        } catch (SQLException e) {
            throw new DatabaseException("AirlineDAO.insert", e);
        }
    }

    /**
     * Transactional overload: inserts using a shared connection.
     * Java-II U10: JDBC Transaction support.
     *
     * Throws DuplicateAccountException (reused for IATA uniqueness) with a clear
     * message when the IATA code is already taken, instead of leaking a raw
     * "Database error during: AirlineDAO.insert" to the user.
     */
    public int insert(Airline a, Connection c) throws DatabaseException,
            skybook.exception.Exceptions.DuplicateAccountException {
        String sql = "INSERT INTO Airlines (AirlineName, IATACode, Country, ContactEmail, IsActive) "
                   + "VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, a.getAirlineName());
            ps.setString(2, a.getIataCode());
            ps.setString(3, a.getCountry());
            ps.setString(4, a.getContactEmail());
            ps.setBoolean(5, a.isActive());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    int id = keys.getInt(1);
                    a.setAirlineId(id);
                    CACHE.put(id, a);
                    return id;
                }
            }
            return -1;
        } catch (SQLException e) {
            // MySQL error code 1062 = Duplicate entry (UNIQUE constraint violation).
            // Check specifically for the IATACode unique key so we can give a clear message.
            if (e.getErrorCode() == 1062) {
                String msg = e.getMessage() != null ? e.getMessage().toLowerCase() : "";
                if (msg.contains("iatacode") || msg.contains("iata_code") || msg.contains("iata")) {
                    throw new skybook.exception.Exceptions.DuplicateAccountException(
                            "IATA code '" + a.getIataCode() + "' is already registered by another airline. "
                            + "Please use a unique IATA code.");
                }
                // Other unique-key violation (e.g. airline name) — still user-friendly
                throw new skybook.exception.Exceptions.DuplicateAccountException(
                        "A duplicate value was detected: " + e.getMessage());
            }
            throw new DatabaseException("AirlineDAO.insert", e);
        }
    }

    public void setActive(int airlineId, boolean active) throws DatabaseException {
        String sql = "UPDATE Airlines SET IsActive = ? WHERE AirlineID = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBoolean(1, active);
            ps.setInt(2, airlineId);
            ps.executeUpdate();
            CACHE.remove(airlineId);   // invalidate cache
        } catch (SQLException e) {
            throw new DatabaseException("AirlineDAO.setActive", e);
        }
    }

    private Airline map(ResultSet rs) throws SQLException {
        Airline a = new Airline();
        a.setAirlineId(rs.getInt("AirlineID"));
        a.setAirlineName(rs.getString("AirlineName"));
        a.setIataCode(rs.getString("IATACode"));
        a.setCountry(rs.getString("Country"));
        a.setContactEmail(rs.getString("ContactEmail"));
        a.setActive(rs.getBoolean("IsActive"));
        return a;
    }
}
