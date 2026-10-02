package skybook.service;

import skybook.dao.*;
import skybook.exception.Exceptions.*;
import skybook.model.*;
import skybook.model.Booking.Status;
import skybook.model.Payment.PaymentStatus;
import skybook.util.*;

import java.math.BigDecimal;
import java.sql.Connection;
import java.util.*;
import java.util.concurrent.locks.ReentrantLock;

/**
 * BookingService — orchestrates the full booking workflow:
 *   search → choose flight → select seats → auxiliary services → payment → ticket.
 *
 * Java-II U3:  Exception Handling — every step throws custom exceptions; callers
 *              catch at menu level and can choose to rollback to a prior confirm point.
 * Java-II U4:  Multithreading — seat selection uses ReentrantLock to prevent
 *              two passengers booking the same seat concurrently.
 * Java-II U5:  ArrayList, LinkedList (used for seat groups).
 * Java-II U6:  HashMap (auxiliary service selections).
 * Java-II U10: JDBC Transaction — setAutoCommit(false), commit, rollback across
 *              Bookings + Tickets + Seats + BookingMeals + Payments tables.
 * DS   U2/U5:  Stack used for "rollback to previous step" navigation.
 * DS   U10:    Hashing — PNR generated via PasswordUtil (SHA-256 concept).
 */
public class BookingService {

    // ── Per-seat lock map — prevents double booking of same seat ──────────────
    // Java-II U6: HashMap<seatKey, ReentrantLock> — one lock per seat
    private static final Map<String, ReentrantLock> SEAT_LOCKS = new HashMap<>();

    private final FlightDAO    flightDAO    = new FlightDAO();
    private final SeatDAO      seatDAO      = new SeatDAO();
    private final PassengerDAO passengerDAO = new PassengerDAO();
    private final BookingDAO   bookingDAO   = new BookingDAO();
    private final TicketDAO    ticketDAO    = new TicketDAO();
    private final PaymentDAO   paymentDAO   = new PaymentDAO();
    private final MealDAO      mealDAO      = new MealDAO();

    // ── Flight Search ─────────────────────────────────────────────────────────

    /**
     * Searches available flights for origin → destination on the given date (±1 day).
     * Java-II U5: Returns ArrayList<Flight>.
     * DS   U1:    ArrayList is internally backed by a dynamic array.
     */
    /** Returns a Flight by ID — used to look up leg-2 of Connecting itineraries. */
    public Flight getFlightById(int flightId)
            throws FlightNotFoundException, DatabaseException {
        return flightDAO.findById(flightId);
    }

    public List<Flight> searchFlights(String from, String to, java.time.LocalDate date)
            throws NoFlightsFoundException, DatabaseException {

        List<Flight> results = flightDAO.search(from, to, date);

        if (results.isEmpty()) {
            throw new NoFlightsFoundException(from, to, date.toString());
        }
        return results;
    }

    // ── Seat Map ──────────────────────────────────────────────────────────────

    /**
     * Returns all seats for the aircraft on the chosen flight.
     * Caller passes them to SeatMapPrinter.print() for 2-D display.
     * DS U1: List<Seat> used as 1-D input to the 2-D grid builder.
     */
    public List<Seat> getSeatsForFlight(int aircraftId) throws DatabaseException {
        return seatDAO.findByAircraft(aircraftId);
    }

    /**
     * Suggests adjacent seats for group booking.
     * DS U6: Uses LinkedList to iterate neighbours efficiently.
     *
     * Strategy: finds available seats, groups them by row number,
     * and returns the first row that has >= count consecutive seats.
     * Java-II U5: LinkedList traversal.
     */
    public List<Seat> suggestGroupSeats(int aircraftId, int count) throws DatabaseException {
        List<Seat> available = seatDAO.findAvailable(aircraftId);

        // DS U7: Group by row — Map<rowNum, LinkedList<Seat>>
        Map<Integer, LinkedList<Seat>> byRow = new LinkedHashMap<>();
        for (Seat s : available) {
            int row = SeatMapPrinter.extractRow(s.getSeatNumber());
            byRow.computeIfAbsent(row, k -> new LinkedList<>()).add(s);
        }

        // Find first row with enough seats
        for (Map.Entry<Integer, LinkedList<Seat>> entry : byRow.entrySet()) {
            LinkedList<Seat> rowSeats = entry.getValue();
            if (rowSeats.size() >= count) {
                List<Seat> chosen = new ArrayList<>();
                Iterator<Seat> it = rowSeats.iterator();
                for (int i = 0; i < count && it.hasNext(); i++) chosen.add(it.next());
                return chosen;
            }
        }

        // Fallback: just return first `count` available seats from any row
        List<Seat> fallback = new ArrayList<>();
        for (int i = 0; i < Math.min(count, available.size()); i++) fallback.add(available.get(i));
        return fallback;
    }

    // ── Full Booking Transaction ───────────────────────────────────────────────

    /**
     * Executes the complete atomic booking transaction for ONE passenger + seat.
     *
     * Steps (all in one DB transaction):
     *   1. Lock the seat (ReentrantLock in memory, then row-level in DB).
     *   2. Verify seat is still available.
     *   3. Insert Passenger (if new).
     *   4. Insert Booking.
     *   5. Insert Ticket.
     *   6. Mark Seat as unavailable.
     *   7. Insert BookingMeals (if any).
     *   8. Insert Payment.
     *   9. Commit.  On any error → Rollback.
     *
     * Java-II U10: setAutoCommit(false) / commit / rollback — ACID transaction.
     * Java-II U4:  ReentrantLock per seat prevents concurrent double-booking.
     * DBMS U8:     Serializability — seat lock ensures conflict-serializable schedule.
     *
     * @param flightId      chosen flight
     * @param passenger     passenger object (new or existing)
     * @param seatNumber    chosen seat e.g. "3W"
     * @param extraKg       extra luggage kg (0 if none)
     * @param mealChoices   map of mealId → quantity (empty if no meals)
     * @param paymentMethod "UPI" | "Card" | "NetBanking" | "Wallet" | "Cash"
     * @param totalPrice    pre-computed total (base + tax + surcharge + luggage + meals)
     *
     * @return confirmed Ticket
     */
    public Ticket bookFlight(int flightId, Passenger passenger, String seatNumber,
                             BigDecimal extraKg, Map<Integer, Integer> mealChoices,
                             String paymentMethod, BigDecimal totalPrice)
            throws SeatUnavailableException, FlightNotFoundException,
                   PaymentFailedException, DatabaseException {

        // ── 1. Acquire in-memory seat lock ────────────────────────────────────
        String seatKey = flightId + ":" + seatNumber.toUpperCase();
        ReentrantLock seatLock = SEAT_LOCKS.computeIfAbsent(seatKey, k -> new ReentrantLock());

        if (!seatLock.tryLock()) {
            throw new SeatUnavailableException(seatNumber + " (being booked by another session)");
        }

        try {
            // ── 2. Get flight details ─────────────────────────────────────────
            Flight flight = flightDAO.findById(flightId);

            // ── 3. Verify seat availability ───────────────────────────────────
            Seat seat = seatDAO.findSeat(flight.getAircraftId(), seatNumber);
            if (seat == null || !seat.isAvailable()) {
                throw new SeatUnavailableException(seatNumber);
            }

            // ── 4. Open transaction ───────────────────────────────────────────
            Connection c = DBConnection.getConnection();
            try {
                c.setAutoCommit(false);   // Java-II U10: begin transaction

                // ── 5. Resolve or create Passenger ────────────────────────────
                Passenger existing = passengerDAO.findByEmail(passenger.getEmail());
                int passengerId;
                if (existing != null) {
                    passengerId = existing.getPassengerId();
                } else {
                    passengerId = passengerDAO.insert(passenger, c);
                    passenger.setPassengerId(passengerId);
                }

                // ── 6. Insert Booking ─────────────────────────────────────────
                int bookingId = bookingDAO.insertBooking(flightId, passengerId, c);

                // ── 7. Compute luggage cost (₹300/kg standard) ─────────────
                BigDecimal luggageCost = extraKg.multiply(new BigDecimal("300"));

                // ── 8. Insert Ticket ──────────────────────────────────────────
                String pnr = PasswordUtil.generatePNR();
                BigDecimal baseAndTax = flight.getTotalPrice()
                        .add(seat.getSeatSurcharge() != null ? seat.getSeatSurcharge() : BigDecimal.ZERO);
                int ticketId = ticketDAO.insertTicket(bookingId, flight.getAircraftId(),
                        seatNumber.toUpperCase(), baseAndTax,
                        pnr, extraKg, luggageCost, c);

                // ── 9. Mark seat unavailable ──────────────────────────────────
                seatDAO.markUnavailable(flight.getAircraftId(), seatNumber, c);

                // ── 10. Record meal choices ───────────────────────────────────
                for (Map.Entry<Integer, Integer> entry : mealChoices.entrySet()) {
                    mealDAO.insertBookingMeal(bookingId, passengerId,
                                             entry.getKey(), entry.getValue(), c);
                }

                // ── 11. Insert Payment ────────────────────────────────────────
                // Simulate gateway check (throws PaymentFailedException if "FAIL")
                validatePaymentMethod(paymentMethod);
                paymentDAO.insertPayment(ticketId, totalPrice, paymentMethod, c);

                // ── 12. COMMIT ────────────────────────────────────────────────
                c.commit();   // Java-II U10: all-or-nothing commit

                // ── 13. Return enriched Ticket ────────────────────────────────
                Ticket ticket = ticketDAO.findByBooking(bookingId);
                if (ticket == null) {
                    throw new DatabaseException("BookingService.bookFlight",
                            new Exception("Ticket not found after booking commit (bookingId=" + bookingId + ")"));
                }
                return ticket;

            } catch (Exception e) {
                try { c.rollback(); } catch (java.sql.SQLException ex) { /* ignore */ }
                if (e instanceof SeatUnavailableException) throw (SeatUnavailableException) e;
                if (e instanceof PaymentFailedException)   throw (PaymentFailedException) e;
                throw new DatabaseException("BookingService.bookFlight", e);
            } finally {
                try { c.setAutoCommit(true); } catch (java.sql.SQLException ignored) {}
            }

        } catch (FlightNotFoundException | SeatUnavailableException |
                 PaymentFailedException | DatabaseException e) {
            throw e;
        } catch (Exception e) {
            throw new DatabaseException("BookingService.bookFlight.outer", e);
        } finally {
            seatLock.unlock();   // Java-II U4: always release seat lock
        }
    }

    // ── Meals ─────────────────────────────────────────────────────────────────

    /**
     * Returns meals offered by the airline for the selected flight.
     * Filters by MealCategory based on flight duration (< 2h → Snack, else Meal).
     * Java-II U2: Java Date-Time API (Duration).
     * Java-II U6: ArrayList result.
     */
    public List<Meal> getAvailableMeals(Flight flight) throws DatabaseException {
        // Get the airline for this flight
        // aircraft → airline join done in FlightDAO, so we read AirlineID from Aircraft
        int airlineId = resolveAirlineId(flight.getAircraftId());
        List<Meal> allMeals = mealDAO.findByAirline(airlineId);

        // Filter by category based on flight duration
        java.time.Duration dur = java.time.Duration.between(
                flight.getDepartureTime(), flight.getArrivalTime());
        boolean shortFlight = dur.toHours() < 2;
        Meal.MealCategory targetCat = shortFlight ? Meal.MealCategory.Snack : Meal.MealCategory.Meal;

        // Java-II U6: filter into new ArrayList
        List<Meal> filtered = new ArrayList<>();
        for (Meal m : allMeals) {
            if (m.getMealCategory() == targetCat) filtered.add(m);
        }
        return filtered;
    }

    // ── Cancellation ─────────────────────────────────────────────────────────

    /**
     * Cancels a booking and processes refund.
     *
     * Java-II U10: Transaction — cancel booking + update seat + update payment status atomically.
     * Java-II U1:  Lambda (CancellationPolicy.computeRefund uses Priceable lambda internally).
     * Java-II U3:  throws AlreadyCancelledException, CancellationWindowExpiredException.
     */
    public BigDecimal cancelBooking(int bookingId, int passengerId)
            throws BookingNotFoundException, AlreadyCancelledException,
                   CancellationWindowExpiredException, DatabaseException {

        Booking booking = bookingDAO.findById(bookingId);
        if (booking == null) throw new BookingNotFoundException(bookingId);

        // Ownership check: compare by email so bookings made under any Passenger row
        // for the registered email are all cancellable by this user.
        Passenger registered = passengerDAO.findById(passengerId);
        Passenger bookingPassenger = passengerDAO.findById(booking.getPassengerId());
        boolean ownsBooking = (booking.getPassengerId() == passengerId)
                || (registered != null && bookingPassenger != null
                    && registered.getEmail() != null
                    && registered.getEmail().equalsIgnoreCase(bookingPassenger.getEmail()));
        if (!ownsBooking)
            throw new SecurityException("This booking does not belong to you.");
        if (booking.getStatus() == Status.Cancelled)
            throw new AlreadyCancelledException(bookingId);

        // Get ticket for seat + price info
        Ticket ticket = ticketDAO.findByBooking(bookingId);
        if (ticket == null) throw new BookingNotFoundException(bookingId);

        // Get flight departure time for policy check
        Flight flight = null;
        try { flight = flightDAO.findById(booking.getFlightId()); }
        catch (FlightNotFoundException e) { throw new DatabaseException("Flight missing", e); }

        // Determine airline and cancellation policy
        int airlineId  = resolveAirlineId(flight.getAircraftId());
        CancellationPolicy policy = CancellationPolicy.forAirline(airlineId);
        long hoursLeft = CancellationPolicy.hoursUntil(flight.getDepartureTime());

        BigDecimal refund = policy.computeRefund(ticket.getPricePaid(), hoursLeft);

        // ── Transaction ───────────────────────────────────────────────────────
        try {
            Connection c = DBConnection.getConnection();
            try {
                c.setAutoCommit(false);

                // 1. Cancel booking record
                bookingDAO.cancelBooking(bookingId, c);

                // 2. Release seat
                seatDAO.markAvailable(flight.getAircraftId(), ticket.getSeatNumber(), c);

                // 3. Update payment to Refunded
                paymentDAO.updateStatus(ticket.getTicketId(), PaymentStatus.Refunded, c);

                c.commit();
                return refund;

            } catch (Exception e) {
                try { c.rollback(); } catch (java.sql.SQLException ex) { /* ignore rollback error */ }
                throw e;
            } finally {
                try { c.setAutoCommit(true); } catch (java.sql.SQLException ignored) {}
            }
        } catch (Exception e) {
            if (e instanceof DatabaseException) throw (DatabaseException) e;
            throw new DatabaseException("BookingService.cancelBooking", e);
        }
    }

    // ── Booking History ───────────────────────────────────────────────────────

    /**
     * Returns all bookings for the logged-in passenger.
     *
     * During booking, passengers are matched by email — a new Passengers row may
     * be created if the email doesn't exist yet, giving it a different PassengerID
     * than the one stored as linked_id in app_users.  To return every booking
     * regardless of which row was used, we resolve the registered email from the
     * linked PassengerID and query across all rows sharing that email.
     *
     * DBMS U7: historyByEmail joins Passengers on Email for a wider, correct result.
     */
    public List<Booking> getHistory(int passengerId) throws DatabaseException {
        // Resolve the registered passenger's email via their linked PassengerID
        Passenger registered = passengerDAO.findById(passengerId);
        if (registered == null || registered.getEmail() == null) {
            // Fallback: plain ID lookup (handles edge/legacy cases)
            bookingDAO.markCompletedFlights(passengerId);
            return bookingDAO.historyByPassenger(passengerId);
        }
        // Mark completed flights and fetch history across all passenger rows for this email
        bookingDAO.markCompletedFlightsByEmail(registered.getEmail());
        return bookingDAO.historyByEmail(registered.getEmail());
    }

    public Ticket getTicket(int bookingId) throws DatabaseException {
        return ticketDAO.findByBooking(bookingId);
    }

    public Payment getPayment(int ticketId) throws DatabaseException {
        return paymentDAO.findByTicket(ticketId);
    }

    /** Returns the Passenger row for the given PassengerID (used to pre-fill booking email). */
    public Passenger getPassengerById(int passengerId) throws DatabaseException {
        return passengerDAO.findById(passengerId);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Resolves the AirlineID for an aircraft.
     * DBMS U7: Single-JOIN query.
     */
    private int resolveAirlineId(int aircraftId) throws DatabaseException {
        String sql = "SELECT AirlineID FROM Aircraft WHERE AircraftID = ?";
        try (Connection c = DBConnection.getConnection();
             java.sql.PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aircraftId);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
            return 0;
        } catch (java.sql.SQLException e) {
            throw new DatabaseException("resolveAirlineId", e);
        }
    }

    /**
     * Validates the payment method.
     * Java-II U3: throws PaymentFailedException for unsupported method.
     */
    private void validatePaymentMethod(String method) throws PaymentFailedException {
        // Java-II U6: HashSet for O(1) lookup
        Set<String> valid = new HashSet<>(Arrays.asList("UPI", "Card", "NetBanking", "Wallet", "Cash"));
        if (!valid.contains(method)) {
            throw new PaymentFailedException("Unknown payment method: " + method);
        }
    }
}
