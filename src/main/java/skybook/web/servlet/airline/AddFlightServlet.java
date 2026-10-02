package skybook.web.servlet.airline;

import skybook.dao.AirportDAO;
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

@WebServlet("/airline/flights/add")
public class AddFlightServlet extends HttpServlet {

    private final AirlineService airlineService = new AirlineService();
    private final AirportDAO airportDAO = new AirportDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Add Flight");
        loadFormData(req);
        req.getRequestDispatcher("/WEB-INF/jsp/airline/addflight.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Add Flight");
        UserAccount user = (UserAccount) req.getSession().getAttribute("user");
        int airlineId = user.getLinkedId();

        try {
            int aircraftId = Integer.parseInt(req.getParameter("aircraftId"));
            String depAirport = req.getParameter("depAirport");
            String arrAirport = req.getParameter("arrAirport");
            LocalDateTime depTime = LocalDateTime.parse(req.getParameter("depTime"));
            LocalDateTime arrTime = LocalDateTime.parse(req.getParameter("arrTime"));
            BigDecimal basePrice = new BigDecimal(req.getParameter("basePrice"));
            BigDecimal stateTax = new BigDecimal(req.getParameter("stateTax"));
            Flight.FlightType flightType = Flight.FlightType.valueOf(req.getParameter("flightType"));
            Flight.FlightCategory flightCategory = Flight.FlightCategory.valueOf(req.getParameter("flightCategory"));

            Integer connectingFlightId = null;
            String connParam = req.getParameter("connectingFlightId");
            if (flightCategory == Flight.FlightCategory.Connecting && connParam != null && !connParam.isBlank()) {
                connectingFlightId = Integer.parseInt(connParam);
            }

            int newId = airlineService.addFlight(airlineId, aircraftId, depAirport, arrAirport,
                    depTime, arrTime, basePrice, stateTax, flightType, flightCategory, connectingFlightId);

            req.getSession().setAttribute("flashSuccess", "Flight #" + newId + " added.");
            resp.sendRedirect(req.getContextPath() + "/airline/dashboard");

        } catch (ValidationException e) {
            req.setAttribute("errorMessage", e.getMessage());
            loadFormData(req);
            req.getRequestDispatcher("/WEB-INF/jsp/airline/addflight.jsp").forward(req, resp);
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            loadFormData(req);
            req.getRequestDispatcher("/WEB-INF/jsp/airline/addflight.jsp").forward(req, resp);
        } catch (Exception e) {
            req.setAttribute("errorMessage", "Please check your inputs: " + e.getMessage());
            loadFormData(req);
            req.getRequestDispatcher("/WEB-INF/jsp/airline/addflight.jsp").forward(req, resp);
        }
    }

    private void loadFormData(HttpServletRequest req) throws IOException {
        UserAccount user = (UserAccount) req.getSession().getAttribute("user");
        try {
            req.setAttribute("fleet", airlineService.myFleet(user.getLinkedId()));
            req.setAttribute("airports", airportDAO.findAll());
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Could not load form data: " + e.getMessage());
        }
    }
}
