package skybook.web.servlet.airline;

import skybook.exception.Exceptions.DatabaseException;
import skybook.model.UserAccount;
import skybook.service.AirlineService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/airline/dashboard")
public class AirlineDashboardServlet extends HttpServlet {

    private final AirlineService airlineService = new AirlineService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Airline Dashboard");
        UserAccount user = (UserAccount) req.getSession().getAttribute("user");
        int airlineId = user.getLinkedId();

        try {
            req.setAttribute("profile", airlineService.getMyProfile(airlineId));
            req.setAttribute("fleet", airlineService.myFleet(airlineId));
            req.setAttribute("flights", airlineService.myFlights(airlineId));
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/jsp/airline/dashboard.jsp").forward(req, resp);
    }
}
