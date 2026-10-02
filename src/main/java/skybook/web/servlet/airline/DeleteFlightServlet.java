package skybook.web.servlet.airline;

import skybook.exception.Exceptions.*;
import skybook.model.UserAccount;
import skybook.service.AirlineService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/airline/flights/delete")
public class DeleteFlightServlet extends HttpServlet {

    private final AirlineService airlineService = new AirlineService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        UserAccount user = (UserAccount) req.getSession().getAttribute("user");
        int flightId = Integer.parseInt(req.getParameter("flightId"));
        HttpSession session = req.getSession();

        try {
            airlineService.removeFlight(user.getLinkedId(), flightId);
            session.setAttribute("flashSuccess", "Flight #" + flightId + " removed.");
        } catch (FlightNotFoundException | ValidationException | DatabaseException e) {
            session.setAttribute("flashError", e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/airline/dashboard");
    }
}
