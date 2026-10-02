package skybook.web.servlet.passenger;

import skybook.dao.AirportDAO;
import skybook.exception.Exceptions.*;
import skybook.service.BookingService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;

@WebServlet("/passenger/search")
public class SearchServlet extends HttpServlet {

    private final BookingService bookingService = new BookingService();
    private final AirportDAO airportDAO = new AirportDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Search Results");
        String from = req.getParameter("from");
        String to   = req.getParameter("to");
        String date = req.getParameter("date");

        req.setAttribute("from", from);
        req.setAttribute("to", to);
        req.setAttribute("date", date);

        try {
            LocalDate searchDate = LocalDate.parse(date);
            req.setAttribute("flights", bookingService.searchFlights(from, to, searchDate));
        } catch (NoFlightsFoundException e) {
            req.setAttribute("infoMessage", e.getMessage());
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
        } catch (Exception e) {
            req.setAttribute("errorMessage", "Please choose valid airports and a date.");
        }

        try {
            req.setAttribute("airports", airportDAO.findAll());
        } catch (DatabaseException ignored) {}

        req.getRequestDispatcher("/WEB-INF/jsp/passenger/results.jsp").forward(req, resp);
    }
}
