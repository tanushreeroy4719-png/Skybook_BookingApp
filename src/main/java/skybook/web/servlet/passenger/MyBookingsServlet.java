package skybook.web.servlet.passenger;

import skybook.exception.Exceptions.DatabaseException;
import skybook.model.UserAccount;
import skybook.service.BookingService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/passenger/bookings")
public class MyBookingsServlet extends HttpServlet {

    private final BookingService bookingService = new BookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "My Bookings");
        HttpSession session = req.getSession();
        UserAccount user = (UserAccount) session.getAttribute("user");

        Object flashSuccess = session.getAttribute("flashSuccess");
        Object flashError = session.getAttribute("flashError");
        if (flashSuccess != null) { req.setAttribute("successMessage", flashSuccess); session.removeAttribute("flashSuccess"); }
        if (flashError != null)   { req.setAttribute("errorMessage", flashError); session.removeAttribute("flashError"); }

        try {
            req.setAttribute("bookings", bookingService.getHistory(user.getLinkedId()));
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/jsp/passenger/mybookings.jsp").forward(req, resp);
    }
}
