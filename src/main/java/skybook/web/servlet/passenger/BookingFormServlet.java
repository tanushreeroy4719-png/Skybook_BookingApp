package skybook.web.servlet.passenger;

import skybook.exception.Exceptions.*;
import skybook.model.Flight;
import skybook.model.Passenger;
import skybook.model.UserAccount;
import skybook.service.BookingService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/passenger/flight")
public class BookingFormServlet extends HttpServlet {

    private final BookingService bookingService = new BookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Book Flight");
        int flightId = Integer.parseInt(req.getParameter("flightId"));

        try {
            Flight flight = bookingService.getFlightById(flightId);
            req.setAttribute("flight", flight);
            req.setAttribute("seats", bookingService.getSeatsForFlight(flight.getAircraftId()));
            req.setAttribute("meals", flight.isMealsAvailable()
                    ? bookingService.getAvailableMeals(flight)
                    : new java.util.ArrayList<>());

            // Pre-fill traveler details from the logged-in passenger's profile
            UserAccount user = (UserAccount) req.getSession().getAttribute("user");
            Passenger p = bookingService.getPassengerById(user.getLinkedId());
            req.setAttribute("passenger", p);

            req.getRequestDispatcher("/WEB-INF/jsp/passenger/book.jsp").forward(req, resp);

        } catch (FlightNotFoundException e) {
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
        }
    }
}
