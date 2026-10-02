package skybook.web.servlet.passenger;

import skybook.exception.Exceptions.*;
import skybook.model.UserAccount;
import skybook.service.BookingService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;

@WebServlet("/passenger/cancel")
public class CancelBookingServlet extends HttpServlet {

    private final BookingService bookingService = new BookingService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int bookingId = Integer.parseInt(req.getParameter("bookingId"));
        UserAccount user = (UserAccount) req.getSession().getAttribute("user");
        HttpSession session = req.getSession();

        try {
            BigDecimal refund = bookingService.cancelBooking(bookingId, user.getLinkedId());
            session.setAttribute("flashSuccess",
                    "Booking #" + bookingId + " cancelled. Refund amount: \u20B9" + refund);
        } catch (BookingNotFoundException | AlreadyCancelledException
                 | CancellationWindowExpiredException | DatabaseException e) {
            session.setAttribute("flashError", e.getMessage());
        } catch (SecurityException e) {
            session.setAttribute("flashError", "You are not allowed to cancel this booking.");
        }

        resp.sendRedirect(req.getContextPath() + "/passenger/bookings");
    }
}
