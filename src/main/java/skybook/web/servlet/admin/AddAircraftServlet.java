package skybook.web.servlet.admin;

import skybook.dao.AircraftDAO;
import skybook.dao.AirlineDAO;
import skybook.exception.Exceptions.DatabaseException;
import skybook.model.Aircraft;
import skybook.model.Airline;
import skybook.util.SeatGenerator;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/admin/aircraft/add")
public class AddAircraftServlet extends HttpServlet {

    private final AirlineDAO airlineDAO = new AirlineDAO();
    private final AircraftDAO aircraftDAO = new AircraftDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Add Aircraft");
        try {
            req.setAttribute("airlines", airlineDAO.findAll());
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/jsp/admin/addaircraft.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Add Aircraft");
        try {
            int airlineId   = Integer.parseInt(req.getParameter("airlineId"));
            String regNo    = req.getParameter("registrationNo");
            String model    = req.getParameter("aircraftModel");
            int totalSeats  = Integer.parseInt(req.getParameter("totalSeats"));
            String status   = req.getParameter("status");
            int year = 0;
            String yearParam = req.getParameter("manufactureYear");
            if (yearParam != null && !yearParam.isBlank()) year = Integer.parseInt(yearParam);

            Airline airline = airlineDAO.findById(airlineId);
            if (airline == null) {
                throw new IllegalArgumentException("Airline #" + airlineId + " not found.");
            }

            Aircraft aircraft = new Aircraft(airlineId, regNo, model, totalSeats, status, year);
            int newId = aircraftDAO.insert(aircraft);

            // Auto-generate the seat map so the aircraft is immediately bookable
            SeatGenerator.generate(newId, totalSeats, airlineId);

            req.getSession().setAttribute("flashSuccess",
                    "Aircraft #" + newId + " added to " + airline.getAirlineName()
                    + " with " + totalSeats + " seats generated.");
            resp.sendRedirect(req.getContextPath() + "/admin/dashboard");

        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            reload(req);
            req.getRequestDispatcher("/WEB-INF/jsp/admin/addaircraft.jsp").forward(req, resp);
        } catch (Exception e) {
            req.setAttribute("errorMessage", "Please check your inputs: " + e.getMessage());
            reload(req);
            req.getRequestDispatcher("/WEB-INF/jsp/admin/addaircraft.jsp").forward(req, resp);
        }
    }

    private void reload(HttpServletRequest req) {
        try {
            req.setAttribute("airlines", airlineDAO.findAll());
        } catch (DatabaseException ignored) {}
    }
}
