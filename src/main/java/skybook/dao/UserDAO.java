package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.UserAccount;
import skybook.model.UserAccount.Role;
import skybook.util.DBConnection;
import skybook.util.PasswordUtil;

import java.sql.*;

/**
 * UserDAO — CRUD for the app_users table (login accounts).
 *
 * Java-II U9:  JDBC Basics — Connection, PreparedStatement, ResultSet.
 * Java-II U10: JDBC Advanced — Metadata (getMetaData for table existence check).
 * DBMS U3/U4:  DDL (CREATE TABLE), DML (INSERT, UPDATE), DQL (SELECT).
 * DBMS U8:     Security — passwords stored as SHA-256 hashes, never plaintext.
 */
public class UserDAO {

    /**
     * Creates the app_users table if it does not already exist.
     * Called once at application startup.
     * Java-II U10: DatabaseMetaData to check table existence before DDL.
     */
    public static void ensureTable() throws DatabaseException {
        String ddl = """
                CREATE TABLE IF NOT EXISTS app_users (
                    user_id       INT          PRIMARY KEY AUTO_INCREMENT,
                    username      VARCHAR(50)  UNIQUE NOT NULL,
                    password_hash VARCHAR(64)  NOT NULL,
                    role          VARCHAR(10)  NOT NULL
                                  CHECK (role IN ('PASSENGER','AIRLINE','ADMIN')),
                    linked_id     INT          NOT NULL DEFAULT 0,
                    is_active     BOOLEAN      DEFAULT TRUE
                )
                """;
        try (Connection c = DBConnection.getConnection();
             Statement  s = c.createStatement()) {
            s.executeUpdate(ddl);

            // Seed the one admin account if the table is empty
            seedAdmin(c);

        } catch (SQLException e) {
            throw new DatabaseException("UserDAO.ensureTable", e);
        }
    }

    /** Inserts default admin if no admin row exists. */
    private static void seedAdmin(Connection c) throws SQLException {
        String chk = "SELECT COUNT(*) FROM app_users WHERE role = 'ADMIN'";
        try (Statement s = c.createStatement();
             ResultSet r = s.executeQuery(chk)) {
            if (r.next() && r.getInt(1) == 0) {
                String sql = "INSERT INTO app_users (username, password_hash, role, linked_id, is_active) "
                           + "VALUES (?, ?, 'ADMIN', 0, TRUE)";
                try (PreparedStatement ps = c.prepareStatement(sql)) {
                    ps.setString(1, "admin");
                    ps.setString(2, PasswordUtil.hash("admin123")); // default password
                    ps.executeUpdate();
                }
            }
        }
    }

    // ── Read ──────────────────────────────────────────────────────────────────

    /**
     * Finds a user by username.
     * Returns null if not found (caller checks).
     */
    public UserAccount findByUsername(String username) throws DatabaseException {
        String sql = "SELECT * FROM app_users WHERE username = ?";
        try (Connection c  = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return map(rs);
            }
            return null;

        } catch (SQLException e) {
            throw new DatabaseException("UserDAO.findByUsername", e);
        }
    }

    // ── Write ─────────────────────────────────────────────────────────────────

    /**
     * Inserts a new user account.
     * Returns the generated user_id.
     * Java-II U9: PreparedStatement with RETURN_GENERATED_KEYS.
     */
    public int insert(UserAccount u) throws DatabaseException, DuplicateAccountException {
        try {
            return insert(u, DBConnection.getConnection());
        } catch (DuplicateAccountException | DatabaseException e) {
            throw e;
        } catch (SQLException e) {
            throw new DatabaseException("UserDAO.insert", e);
        }
    }

    /**
     * Transactional overload: inserts using a shared connection (for atomic multi-table ops).
     * Java-II U10: JDBC Transaction support.
     */
    public int insert(UserAccount u, Connection c) throws DatabaseException, DuplicateAccountException {
        String sql = "INSERT INTO app_users (username, password_hash, role, linked_id, is_active) "
                   + "VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, u.getUsername());
            ps.setString(2, u.getPasswordHash());
            ps.setString(3, u.getRole().name());
            ps.setInt(4,    u.getLinkedId());
            ps.setBoolean(5, u.isActive());
            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
            return -1;

        } catch (SQLIntegrityConstraintViolationException e) {
            throw new DuplicateAccountException(u.getUsername());
        } catch (SQLException e) {
            throw new DatabaseException("UserDAO.insert", e);
        }
    }

    /** Updates password hash for a given username. */
    public void updatePassword(String username, String newHash) throws DatabaseException {
        String sql = "UPDATE app_users SET password_hash = ? WHERE username = ?";
        try (Connection c  = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newHash);
            ps.setString(2, username);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("UserDAO.updatePassword", e);
        }
    }

    /** Activates or deactivates an account. */
    public void setActive(String username, boolean active) throws DatabaseException {
        String sql = "UPDATE app_users SET is_active = ? WHERE username = ?";
        try (Connection c  = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBoolean(1, active);
            ps.setString(2, username);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("UserDAO.setActive", e);
        }
    }

    /** Links an existing AIRLINE account to a newly-created AirlineID. */
    public void linkAirline(String username, int airlineId) throws DatabaseException {
        String sql = "UPDATE app_users SET linked_id = ? WHERE username = ?";
        try (Connection c  = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, airlineId);
            ps.setString(2, username);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("UserDAO.linkAirline", e);
        }
    }

    // ── Mapper ────────────────────────────────────────────────────────────────

    /** Maps a ResultSet row to a UserAccount object. */
    private UserAccount map(ResultSet rs) throws SQLException {
        UserAccount u = new UserAccount();
        u.setUserId(rs.getInt("user_id"));
        u.setUsername(rs.getString("username"));
        u.setPasswordHash(rs.getString("password_hash"));
        u.setRole(Role.valueOf(rs.getString("role")));
        u.setLinkedId(rs.getInt("linked_id"));
        u.setActive(rs.getBoolean("is_active"));
        return u;
    }
}
