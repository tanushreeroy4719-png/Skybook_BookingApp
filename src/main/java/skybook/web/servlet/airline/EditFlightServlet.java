package skybook.web.servlet.airline;

import skybook.exception.Exceptions.*;
import skybook.model.Flight;
import skybook.model.UserAccount;
import skybook.service.AirlineService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@WebServlet("/airline/flights/edit")
public class EditFlightServlet extends HttpServlet {

    private final AirlineService airlineService = new AirlineService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Edit Flight");
        int flightId = Integer.parseInt(req.getParameter("flightId"));
        try {
            Flight flight = airlineService.getFlightById(flightId);
            req.setAttribute("flight", flight);
            req.getRequestDispatcher("/WEB-INF/jsp/airline/editflight.jsp").forward(req, resp);
        } catch (FlightNotFoundException | DatabaseException e) {
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Edit Flight");
        UserAccount user = (UserAccount) req.getSession().getAttribute("user");
        int airlineId = user.getLinkedId();
        int flightId = Integer.parseInt(req.getParameter("flightId"));

        try {
            LocalDateTime newDep = LocalDateTime.parse(req.getParameter("depTime"));
            LocalDateTime newArr = LocalDateTime.parse(req.getParameter("arrTime"));
            BigDecimal newPrice = new BigDecimal(req.getParameter("basePrice"));

            airlineService.updateFlightTime(airlineId, flightId, newDep, newArr);
            airlineService.updateFlightPrice(airlineId, flightId, newPrice);

            req.getSession().setAttribute("flashSuccess", "Flight #" + flightId + " updated.");
            resp.sendRedirect(req.getContextPath() + "/airline/dashboard");

        } catch (ValidationException | FlightNotFoundException | DatabaseException e) {
            req.setAttribute("errorMessage", e.getMessage());
            try { req.setAttribute("flight", airlineService.getFlightById(flightId)); } catch (Exception ignored) {}
            req.getRequestDispatcher("/WEB-INF/jsp/airline/editflight.jsp").forward(req, resp);
        }
    }
}
