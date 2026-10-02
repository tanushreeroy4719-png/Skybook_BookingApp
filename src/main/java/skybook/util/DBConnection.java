package skybook.util;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * DBConnection — pooled JDBC connection manager for the web application.
 *
 * WEB CONVERSION NOTE:
 * The original console app used ONE shared, non-closeable Connection for the
 * whole program, because only one user was ever active at a time. A website
 * has many users hitting the server at the same time, so that design is not
 * safe here (two concurrent transactions would fight over the same
 * Connection's autoCommit/commit/rollback state).
 *
 * This version uses a HikariCP connection pool instead. Every call to
 * getConnection() hands out a real, independent, poolable Connection.
 * Calling close() on it (including via try-with-resources, which almost
 * every DAO already uses) correctly returns it to the pool rather than
 * actually closing the socket. No other DAO/service code needed to change.
 *
 * Configure the database URL/user/password below to match your XAMPP
 * (or any) MySQL instance.
 */
public class DBConnection {

    // ── Configuration — EDIT THESE to match your MySQL / XAMPP setup ───────────
    private static final String URL =
            "jdbc:mysql://localhost:3306/skybook"
            + "?useSSL=false&serverTimezone=Asia/Kolkata&allowPublicKeyRetrieval=true";
    private static final String USER     = "root";
    private static final String PASSWORD = "";   // XAMPP's default MySQL root password is blank
    // ─────────────────────────────────────────────────────────────────────────

    private static final HikariDataSource DATA_SOURCE;

    static {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(URL);
        config.setUsername(USER);
        config.setPassword(PASSWORD);
        config.setDriverClassName("com.mysql.cj.jdbc.Driver");
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);
        config.setPoolName("SkyBookPool");
        DATA_SOURCE = new HikariDataSource(config);
    }

    private DBConnection() {}

    /** Returns a real, poolable connection. close() returns it to the pool. */
    public static Connection getConnection() throws SQLException {
        return DATA_SOURCE.getConnection();
    }

    /** Shuts the pool down. Call once from a ServletContextListener on app shutdown. */
    public static void close() {
        if (DATA_SOURCE != null && !DATA_SOURCE.isClosed()) {
            DATA_SOURCE.close();
        }
    }
}
