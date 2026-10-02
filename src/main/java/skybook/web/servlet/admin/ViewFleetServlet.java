package skybook.web.servlet.admin;

import skybook.dao.AircraftDAO;
import skybook.dao.AirlineDAO;
import skybook.exception.Exceptions.DatabaseException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/admin/fleet")
public class ViewFleetServlet extends HttpServlet {

    private final AirlineDAO airlineDAO = new AirlineDAO();
    private final AircraftDAO aircraftDAO = new AircraftDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Fleet");
        int airlineId = Integer.parseInt(req.getParameter("airlineId"));

        try {
            req.setAttribute("airline", airlineDAO.findById(airlineId));
            req.setAttribute("fleet", aircraftDAO.findByAirline(airlineId));
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/jsp/admin/fleet.jsp").forward(req, resp);
    }
}
