package skybook.service;

import skybook.dao.UserDAO;
import skybook.dao.PassengerDAO;
import skybook.dao.AirlineDAO;
import skybook.exception.Exceptions.*;
import skybook.model.UserAccount;
import skybook.model.UserAccount.Role;
import skybook.model.Passenger;
import skybook.model.Airline;
import skybook.util.DBConnection;
import skybook.util.PasswordUtil;

import java.sql.Connection;
import java.time.LocalDate;
import java.util.concurrent.locks.ReentrantLock;

/**
 * AuthService — login, registration, and session management.
 *
 * Java-II U4: Multithreading — ReentrantLock prevents race conditions if two
 *             sessions try to register the same username simultaneously.
 * Java-II U3: Exception handling — throws/catch chain for invalid credentials,
 *             duplicate accounts, inactive accounts.
 * DBMS U8:    Security — passwords hashed with SHA-256; role-based access control.
 *
 * Session: stores the currently logged-in UserAccount in a static field.
 *          One user is active at a time in this console application.
 */
public class AuthService {

    private static UserAccount currentSession = null;

    // Java-II U4: Lock for thread-safe registration
    private static final ReentrantLock REGISTER_LOCK = new ReentrantLock();

    private final UserDAO      userDAO      = new UserDAO();
    private final PassengerDAO passengerDAO = new PassengerDAO();
    private final AirlineDAO   airlineDAO   = new AirlineDAO();

    // ── Login ─────────────────────────────────────────────────────────────────

    /**
     * Attempts to log in with the given credentials.
     *
     * Java-II U3: throws InvalidCredentialsException, AccountInactiveException.
     * DBMS U8:    Verifies SHA-256 hash — plaintext password never leaves this method.
     *
     * @return the authenticated UserAccount
     */
    public UserAccount login(String username, String password)
            throws InvalidCredentialsException, AccountInactiveException,
                   DatabaseException {

        UserAccount user = userDAO.findByUsername(username);

        if (user == null || !PasswordUtil.verify(password, user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }

        if (!user.isActive()) {
            throw new AccountInactiveException(username);
        }

        currentSession = user;
        return user;
    }

    // ── Registration ──────────────────────────────────────────────────────────

    /**
     * Registers a new PASSENGER account.
     * Inserts a Passenger row first, then creates the login account linked to it.
     *
     * Java-II U4: ReentrantLock used around DB insert to prevent duplicate username race.
     * Java-II U10: JDBC Transaction — Passenger + UserAccount inserted atomically.
     * Java-II U3: throws DuplicateAccountException if username taken.
     */
    public UserAccount registerPassenger(String username, String password,
                                          String firstName, String lastName,
                                          String email, String contactNo,
                                          LocalDate dob, String passport)
            throws DuplicateAccountException, ValidationException, DatabaseException {

        // Passenger chooses their own password, but it must follow the format name@123
        if (!PasswordUtil.isValidUserPassword(password)) {
            throw new ValidationException("Password", PasswordUtil.USER_PASSWORD_HINT);
        }

        // Check if username already exists
        if (userDAO.findByUsername(username) != null) {
            throw new DuplicateAccountException("Username '" + username + "' is already taken.");
        }

        // Check if email is already registered (UNIQUE constraint on Passengers.Email)
        if (passengerDAO.findByEmail(email) != null) {
            throw new DuplicateAccountException("Email '" + email + "' is already registered. Please use a different email or login to your existing account.");
        }

        REGISTER_LOCK.lock();   // Java-II U4: acquire lock
        try {
            Connection c = DBConnection.getConnection();
            try {
                c.setAutoCommit(false);   // Java-II U10: begin transaction

                // 1. Insert Passenger
                Passenger p = new Passenger(firstName, lastName, email,
                                            contactNo, dob, passport);
                int passengerId = passengerDAO.insert(p, c);

                // 2. Insert UserAccount (use shared connection for atomicity)
                String hash = PasswordUtil.hash(password);
                UserAccount ua = new UserAccount(username, hash, Role.PASSENGER,
                                                 passengerId, true);
                int userId = userDAO.insert(ua, c);
                ua.setUserId(userId);
                ua.setLinkedId(passengerId);

                c.commit();   // Java-II U10: commit
                currentSession = ua;
                return ua;

            } catch (Exception e) {
                try { c.rollback(); } catch (java.sql.SQLException ex) { /* ignore */ }
                throw e;
            } finally {
                try { c.setAutoCommit(true); } catch (java.sql.SQLException ignored) {}
            }

        } catch (DuplicateAccountException | DatabaseException re) {
            throw re;
        } catch (Exception e) {
            throw new DatabaseException("AuthService.registerPassenger", e);
        } finally {
            REGISTER_LOCK.unlock();   // Java-II U4: always release lock
        }
    }

    /**
     * Admin creates a new AIRLINE account and links it to an Airlines entry.
     * The account's password is always the fixed value "airline@123".
     * Java-II U4: Same locking pattern as registerPassenger.
     */
    public UserAccount registerAirline(String username,
                                        String airlineName, String iataCode,
                                        String country, String contactEmail)
            throws DuplicateAccountException, DatabaseException {

        // WEB CONVERSION: role is enforced by the servlet's AdminFilter (per-session),
        // not by this static, single-user field — see AdminFilter.

        if (userDAO.findByUsername(username) != null) {
            throw new DuplicateAccountException(username);
        }

        REGISTER_LOCK.lock();
        try {
            Connection c = DBConnection.getConnection();
            try {
                c.setAutoCommit(false);

                // 1. Insert into Airlines table (use shared connection for atomicity).
                // AirlineDAO.insert throws DuplicateAccountException if IATACode is taken.
                Airline airline = new Airline(airlineName, iataCode, country, contactEmail, true);
                int airlineId = airlineDAO.insert(airline, c);  // may throw DuplicateAccountException

                // 2. Insert UserAccount linked to airlineId (use shared connection)
                // Every airline account gets the fixed password "airline@123"
                String hash = PasswordUtil.hash(PasswordUtil.AIRLINE_PASSWORD);
                UserAccount ua = new UserAccount(username, hash, Role.AIRLINE, airlineId, true);
                int userId = userDAO.insert(ua, c);
                ua.setUserId(userId);
                ua.setLinkedId(airlineId);   // FIX: was missing — caused AirlineID=0 FK violation on addAircraft

                c.commit();
                return ua;

            } catch (Exception e) {
                try { c.rollback(); } catch (java.sql.SQLException ex) { /* ignore */ }
                throw e;
            } finally {
                try { c.setAutoCommit(true); } catch (java.sql.SQLException ignored) {}
            }

        } catch (DuplicateAccountException | DatabaseException re) {
            throw re;
        } catch (Exception e) {
            throw new DatabaseException("AuthService.registerAirline", e);
        } finally {
            REGISTER_LOCK.unlock();
        }
    }

    /**
     * Changes password for the current session user.
     * Java-II U3: throws InvalidCredentialsException if old password wrong.
     */
    public void changePassword(String oldPassword, String newPassword)
            throws InvalidCredentialsException, DatabaseException {

        requireLogin();
        if (!PasswordUtil.verify(oldPassword, currentSession.getPasswordHash())) {
            throw new InvalidCredentialsException("Old password is incorrect.");
        }
        String newHash = PasswordUtil.hash(newPassword);
        userDAO.updatePassword(currentSession.getUsername(), newHash);
        currentSession.setPasswordHash(newHash);
    }

    // ── Session helpers ───────────────────────────────────────────────────────

    public void logout() { currentSession = null; }

    public static UserAccount getSession() { return currentSession; }

    public static boolean isLoggedIn() { return currentSession != null; }

    /**
     * Checks that a user with the expected role is logged in.
     * Java-II U3: throws RuntimeException (unchecked) as a guard assertion.
     */
    public static void requireRole(Role role) {
        if (currentSession == null || currentSession.getRole() != role) {
            throw new SecurityException("Access denied: requires role " + role);
        }
    }

    private static void requireLogin() {
        if (currentSession == null)
            throw new SecurityException("No user logged in.");
    }

    /**
     * Admin: deactivate an airline account (and its Airlines row).
     * Robust: if linked_id is 0 (legacy data), looks up AirlineID via Airlines table
     * by matching the username to the airline account.
     */
    public void deactivateAirline(String airlineUsername)
            throws AccountNotFoundException, DatabaseException {

        // WEB CONVERSION: role is enforced by AdminFilter before this method is called.
        UserAccount ua = userDAO.findByUsername(airlineUsername);
        if (ua == null || ua.getRole() != Role.AIRLINE) {
            throw new AccountNotFoundException(airlineUsername);
        }
        if (!ua.isActive()) {
            throw new AccountNotFoundException(
                    airlineUsername + " (already deactivated)");
        }

        // Deactivate the login account
        userDAO.setActive(airlineUsername, false);

        // Deactivate the Airlines row — use linked_id if valid, else skip
        int linkedId = ua.getLinkedId();
        if (linkedId > 0) {
            airlineDAO.setActive(linkedId, false);
        }
        // If linked_id is 0 (legacy data), user row is still deactivated
        // so the airline cannot log in — this is sufficient protection.
    }
}
