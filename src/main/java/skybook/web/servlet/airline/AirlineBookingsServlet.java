package skybook.web.servlet.airline;

import skybook.exception.Exceptions.DatabaseException;
import skybook.model.UserAccount;
import skybook.service.AirlineService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/airline/bookings")
public class AirlineBookingsServlet extends HttpServlet {

    private final AirlineService airlineService = new AirlineService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Bookings");
        UserAccount user = (UserAccount) req.getSession().getAttribute("user");

        try {
            req.setAttribute("bookings", airlineService.myBookingHistory(user.getLinkedId()));
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/jsp/airline/bookings.jsp").forward(req, resp);
    }
}
