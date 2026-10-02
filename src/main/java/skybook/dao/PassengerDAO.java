package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Passenger;
import skybook.util.DBConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * PassengerDAO — insert new passengers; find by email or ID.
 *
 * Java-II U9:  JDBC PreparedStatement, RETURN_GENERATED_KEYS.
 * DBMS U6:     Normalization — Passengers table is in 3NF; no repeating data.
 */
public class PassengerDAO {

    public Passenger findByEmail(String email) throws DatabaseException {
        String sql = "SELECT * FROM Passengers WHERE Email = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("PassengerDAO.findByEmail", e);
        }
    }

    public Passenger findById(int id) throws DatabaseException {
        String sql = "SELECT * FROM Passengers WHERE PassengerID = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("PassengerDAO.findById", e);
        }
    }

    /**
     * Inserts a new passenger. Returns the generated PassengerID.
     * Uses a shared Connection for transaction support.
     */
    public int insert(Passenger p, Connection c) throws SQLException {
        String sql = "INSERT INTO Passengers (FirstName, LastName, Email, ContactNo, "
                   + "DateOfBirth, PassportNumber) VALUES (?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, p.getFirstName());
            ps.setString(2, p.getLastName());
            ps.setString(3, p.getEmail());
            ps.setString(4, p.getContactNo());
            ps.setDate(5, Date.valueOf(p.getDateOfBirth()));
            if (p.getPassportNumber() != null && !p.getPassportNumber().isEmpty())
                ps.setString(6, p.getPassportNumber());
            else
                ps.setNull(6, Types.VARCHAR);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        return -1;
    }

    private Passenger map(ResultSet rs) throws SQLException {
        Passenger p = new Passenger();
        p.setPassengerId(rs.getInt("PassengerID"));
        p.setFirstName(rs.getString("FirstName"));
        p.setLastName(rs.getString("LastName"));
        p.setEmail(rs.getString("Email"));
        p.setContactNo(rs.getString("ContactNo"));
        p.setDateOfBirth(rs.getDate("DateOfBirth").toLocalDate());
        p.setPassportNumber(rs.getString("PassportNumber"));
        return p;
    }
}
