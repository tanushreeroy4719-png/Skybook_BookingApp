package skybook.web.servlet.passenger;

import skybook.dao.AirportDAO;
import skybook.exception.Exceptions.DatabaseException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/passenger/dashboard")
public class DashboardServlet extends HttpServlet {

    private final AirportDAO airportDAO = new AirportDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Search Flights");
        try {
            req.setAttribute("airports", airportDAO.findAll());
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Could not load airports: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/jsp/passenger/dashboard.jsp").forward(req, resp);
    }
}
