package skybook.web.servlet.passenger;

import skybook.dao.SeatDAO;
import skybook.exception.Exceptions.*;
import skybook.model.*;
import skybook.service.BookingService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/passenger/book")
public class BookFlightServlet extends HttpServlet {

    private final BookingService bookingService = new BookingService();
    private final SeatDAO seatDAO = new SeatDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Booking");
        int flightId = Integer.parseInt(req.getParameter("flightId"));
        String seatNumber = req.getParameter("seatNumber");
        String paymentMethod = req.getParameter("paymentMethod");

        try {
            Flight flight = bookingService.getFlightById(flightId);

            if (seatNumber == null || seatNumber.isBlank()) {
                throw new ValidationException("Seat", "Please choose a seat.");
            }
            Seat seat = seatDAO.findSeat(flight.getAircraftId(), seatNumber);
            if (seat == null) {
                throw new SeatUnavailableException(seatNumber);
            }

            // ── Traveler details ────────────────────────────────────────────
            Passenger passenger = new Passenger(
                    req.getParameter("firstName"),
                    req.getParameter("lastName"),
                    req.getParameter("email"),
                    req.getParameter("contactNo"),
                    LocalDate.parse(req.getParameter("dob")),
                    req.getParameter("passport")
            );

            // ── Extra luggage ───────────────────────────────────────────────
            BigDecimal extraKg = BigDecimal.ZERO;
            String extraKgParam = req.getParameter("extraKg");
            if (extraKgParam != null && !extraKgParam.isBlank()) {
                extraKg = new BigDecimal(extraKgParam);
            }

            // ── Meals: form fields named meal_<mealId> with a quantity ─────
            Map<Integer, Integer> mealChoices = new HashMap<>();
            Enumeration<String> paramNames = req.getParameterNames();
            while (paramNames.hasMoreElements()) {
                String name = paramNames.nextElement();
                if (name.startsWith("meal_")) {
                    int mealId = Integer.parseInt(name.substring("meal_".length()));
                    int qty = 0;
                    try { qty = Integer.parseInt(req.getParameter(name)); } catch (Exception ignored) {}
                    if (qty > 0) mealChoices.put(mealId, qty);
                }
            }

            // ── Compute authoritative total (server-side, never trust the client) ──
            BigDecimal total = flight.getTotalPrice();
            if (seat.getSeatSurcharge() != null) total = total.add(seat.getSeatSurcharge());
            total = total.add(extraKg.multiply(new BigDecimal("300")));
            for (Map.Entry<Integer, Integer> entry : mealChoices.entrySet()) {
                skybook.model.Meal meal = new skybook.dao.MealDAO().findById(entry.getKey());
                if (meal != null) {
                    total = total.add(meal.getPrice().multiply(new BigDecimal(entry.getValue())));
                }
            }

            Ticket ticket = bookingService.bookFlight(
                    flightId, passenger, seatNumber, extraKg, mealChoices, paymentMethod, total);

            resp.sendRedirect(req.getContextPath() + "/passenger/ticket?bookingId=" + ticket.getBookingId());

        } catch (SeatUnavailableException | PaymentFailedException | ValidationException e) {
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/passenger/flight?flightId=" + flightId).forward(req, resp);
        } catch (FlightNotFoundException | DatabaseException e) {
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
        }
    }
}
