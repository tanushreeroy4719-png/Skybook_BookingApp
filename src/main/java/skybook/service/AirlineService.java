package skybook.service;

import skybook.dao.AircraftDAO;
import skybook.dao.AirlineDAO;
import skybook.dao.BookingDAO;
import skybook.dao.FlightDAO;
import skybook.model.Aircraft;
import skybook.exception.Exceptions.*;
import skybook.model.Airline;
import skybook.model.Booking;
import skybook.model.Flight;
import skybook.model.UserAccount.Role;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * AirlineService — operations available to a logged-in AIRLINE user.
 *
 * Java-II U2:  Access Modifiers — public service methods, private helpers.
 * Java-II U3:  Exception Handling — all ops validate role and ownership, throw on error.
 * Java-II U1:  Abstraction — exposes only what the airline needs; DAO details hidden.
 * DBMS U3/U7:  DML (INSERT, UPDATE, DELETE) + DQL (SELECT with joins) via FlightDAO.
 * DBMS U8:     Access Control — airline can only modify its OWN flights.
 */
public class AirlineService {

    private final FlightDAO   flightDAO   = new FlightDAO();
    private final AirlineDAO  airlineDAO  = new AirlineDAO();
    private final BookingDAO  bookingDAO  = new BookingDAO();
    private final AircraftDAO aircraftDAO = new AircraftDAO();

    // ── View flights ─────────────────────────────────────────────────────────

    /** Returns all flights for the currently logged-in airline. */
    public List<Flight> myFlights(int airlineId) throws DatabaseException {
        return flightDAO.findByAirline(airlineId);
    }

    /** Returns a single flight by ID — used to validate connecting leg-2 ID when adding a flight. */
    public Flight getFlightById(int flightId) throws DatabaseException, FlightNotFoundException {
        return flightDAO.findById(flightId);
    }

    /**
     * Returns all aircraft registered to this airline by Admin.
     * DS U6: Returns ArrayList<Aircraft>.
     * DBMS U8: Airline sees only its own aircraft (filtered by AirlineID).
     */
    public List<Aircraft> myFleet(int airlineId) throws DatabaseException {
        return aircraftDAO.findByAirline(airlineId);
    }

    public Airline getMyProfile(int airlineId) throws DatabaseException {
        return airlineDAO.findById(airlineId);
    }

    // ── Booking history ───────────────────────────────────────────────────────

    /**
     * Returns all bookings made on flights belonging to this airline.
     * DBMS U7: JOIN across Bookings, Flights, Aircraft, Airlines, Passengers.
     */
    public List<Booking> myBookingHistory(int airlineId) throws DatabaseException {
        return bookingDAO.historyByAirline(airlineId);
    }

    // ── Active status guard ───────────────────────────────────────────────────

    /**
     * Verifies that the airline account is still active in the DB.
     * Called before every write operation so a deactivated-while-logged-in
     * airline cannot add/edit/remove flights mid-session.
     *
     * DBMS U8: Re-reads Airlines.IsActive from DB; does not trust in-memory session.
     */
    private void requireAirlineActive(int airlineId) throws ValidationException, DatabaseException {
        Airline airline = airlineDAO.findById(airlineId);
        if (airline == null || !airline.isActive()) {
            throw new ValidationException("AirlineStatus",
                    "Your airline account has been deactivated by the administrator. "
                  + "You cannot perform this action.");
        }
    }

    // ── Add Flight ────────────────────────────────────────────────────────────

    /**
     * Adds a new flight. Verifies the aircraft belongs to this airline.
     * Java-II U3: throws ValidationException if times/price are invalid.
     * DBMS U3:    DML — INSERT into Flights.
     * DBMS U8:    Ownership check — airline cannot add flight to another airline's aircraft.
     */
    public int addFlight(int airlineId, int aircraftId,
                         String depAirport, String arrAirport,
                         LocalDateTime depTime, LocalDateTime arrTime,
                         BigDecimal basePrice, BigDecimal stateTax,
                         Flight.FlightType flightType,
                         Flight.FlightCategory flightCategory,
                         Integer connectingFlightId)
            throws ValidationException, DatabaseException {

        // WEB CONVERSION: role/ownership is enforced by AirlineFilter + the airlineId
        // taken from the logged-in user's HttpSession — not by AuthService's static field.
        // DBMS U8: Re-check active status from DB — catches deactivation mid-session
        requireAirlineActive(airlineId);

        // DBMS U8: verify aircraft belongs to this airline
        if (!aircraftBelongsToAirline(aircraftId, airlineId)) {
            throw new ValidationException("AircraftID",
                    "Aircraft #" + aircraftId + " does not belong to your airline.");
        }

        // Validate: departure and arrival airports must be different
        if (depAirport.equalsIgnoreCase(arrAirport)) {
            throw new ValidationException("DepartureAirport",
                    "Departure and arrival airports cannot be the same ("
                    + depAirport.toUpperCase() + "). Please choose different airports.");
        }

        if (!arrTime.isAfter(depTime)) {
            throw new ValidationException("ArrivalTime",
                    "Arrival must be after departure.");
        }
        if (basePrice.compareTo(BigDecimal.ZERO) < 0) {
            throw new ValidationException("BasePrice", "Price cannot be negative.");
        }

        Flight f = new Flight();
        f.setAircraftId(aircraftId);
        f.setDepartureAirportId(depAirport.toUpperCase());
        f.setArrivalAirportId(arrAirport.toUpperCase());
        f.setDepartureTime(depTime);
        f.setArrivalTime(arrTime);
        f.setBasePrice(basePrice);
        f.setStateTaxAmount(stateTax);
        f.setFlightType(flightType);
        f.setFlightCategory(flightCategory);
        f.setConnectingFlightId(connectingFlightId);

        return flightDAO.insert(f);
    }

    // ── Update Delay ──────────────────────────────────────────────────────────

    /**
     * Updates departure/arrival time (delay scenario).
     * DBMS U8: Ownership check — airline can only update its own flights.
     */
    public void updateFlightTime(int airlineId, int flightId,
                                 LocalDateTime newDep, LocalDateTime newArr)
            throws ValidationException, FlightNotFoundException, DatabaseException {

        // WEB CONVERSION: role/ownership is enforced by AirlineFilter + the airlineId
        // taken from the logged-in user's HttpSession — not by AuthService's static field.
        requireAirlineActive(airlineId);

        if (!newArr.isAfter(newDep)) {
            throw new ValidationException("ArrivalTime",
                    "Arrival must be after new departure time.");
        }

        Flight flight = flightDAO.findById(flightId);   // throws FlightNotFoundException

        // DBMS U8: Ownership verification
        if (!flightBelongsToAirline(flight, airlineId)) {
            throw new ValidationException("FlightID",
                    "Flight #" + flightId + " does not belong to your airline.");
        }

        flightDAO.updateTimes(flightId, newDep, newArr);
    }

    // ── Remove Flight ─────────────────────────────────────────────────────────

    /**
     * Deletes a flight. Airline can only remove its own flights.
     * DBMS U8: Ownership check before DELETE.
     */
    public void removeFlight(int airlineId, int flightId)
            throws FlightNotFoundException, ValidationException, DatabaseException {

        // WEB CONVERSION: role/ownership is enforced by AirlineFilter + the airlineId
        // taken from the logged-in user's HttpSession — not by AuthService's static field.
        requireAirlineActive(airlineId);

        Flight flight = flightDAO.findById(flightId);

        if (!flightBelongsToAirline(flight, airlineId)) {
            throw new ValidationException("FlightID",
                    "Flight #" + flightId + " does not belong to your airline.");
        }

        flightDAO.delete(flightId);
    }

    // ── Update base price ─────────────────────────────────────────────────────

    /**
     * Updates base price of a flight.
     * DBMS U8: Ownership check — airline can only update its own flight prices.
     */
    public void updateFlightPrice(int airlineId, int flightId, BigDecimal newPrice)
            throws ValidationException, FlightNotFoundException, DatabaseException {

        // WEB CONVERSION: role/ownership is enforced by AirlineFilter + the airlineId
        // taken from the logged-in user's HttpSession — not by AuthService's static field.
        requireAirlineActive(airlineId);

        if (newPrice.compareTo(BigDecimal.ZERO) < 0) {
            throw new ValidationException("BasePrice", "Price cannot be negative.");
        }

        Flight flight = flightDAO.findById(flightId);

        if (!flightBelongsToAirline(flight, airlineId)) {
            throw new ValidationException("FlightID",
                    "Flight #" + flightId + " does not belong to your airline.");
        }

        flightDAO.updatePrice(flightId, newPrice);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    /**
     * Returns true if the given flight's aircraft belongs to this airline.
     * DBMS U8: row-level ownership check via JOIN.
     */
    private boolean flightBelongsToAirline(Flight flight, int airlineId)
            throws DatabaseException {
        // flight.getAirlineName() is populated by the JOIN in FlightDAO
        // but the reliable check is via aircraftId
        return aircraftBelongsToAirline(flight.getAircraftId(), airlineId);
    }

    /**
     * Checks the Aircraft table — returns true if AircraftID belongs to airlineId.
     * DBMS U7: Single-row subquery.
     */
    private boolean aircraftBelongsToAirline(int aircraftId, int airlineId)
            throws DatabaseException {
        String sql = "SELECT COUNT(*) FROM Aircraft WHERE AircraftID = ? AND AirlineID = ?";
        try (java.sql.Connection c = skybook.util.DBConnection.getConnection();
             java.sql.PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            ps.setInt(2, airlineId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (java.sql.SQLException e) {
            throw new DatabaseException("AirlineService.aircraftBelongsToAirline", e);
        }
    }
}
