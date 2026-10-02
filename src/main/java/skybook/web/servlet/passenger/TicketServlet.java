package skybook.web.servlet.passenger;

import skybook.exception.Exceptions.DatabaseException;
import skybook.model.Payment;
import skybook.model.Ticket;
import skybook.service.BookingService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/passenger/ticket")
public class TicketServlet extends HttpServlet {

    private final BookingService bookingService = new BookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Your Ticket");
        int bookingId = Integer.parseInt(req.getParameter("bookingId"));

        try {
            Ticket ticket = bookingService.getTicket(bookingId);
            if (ticket == null) {
                req.setAttribute("errorMessage", "Ticket not found for booking #" + bookingId);
                req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
                return;
            }
            Payment payment = bookingService.getPayment(ticket.getTicketId());
            req.setAttribute("ticket", ticket);
            req.setAttribute("payment", payment);
            req.setAttribute("bookingId", bookingId);
            req.getRequestDispatcher("/WEB-INF/jsp/passenger/ticket.jsp").forward(req, resp);

        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
        }
    }
}
