package skybook.web.servlet.admin;

import skybook.exception.Exceptions.*;
import skybook.service.AuthService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/admin/airlines/add")
public class RegisterAirlineServlet extends HttpServlet {

    private final AuthService authService = new AuthService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Register Airline");
        req.getRequestDispatcher("/WEB-INF/jsp/admin/addairline.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Register Airline");
        String username    = req.getParameter("username");
        String airlineName = req.getParameter("airlineName");
        String iataCode    = req.getParameter("iataCode");
        String country     = req.getParameter("country");
        String email       = req.getParameter("email");

        try {
            authService.registerAirline(username, airlineName, iataCode, country, email);
            req.getSession().setAttribute("flashSuccess",
                    "Airline '" + airlineName + "' registered. Login username: " + username
                    + " | Password: " + skybook.util.PasswordUtil.AIRLINE_PASSWORD);
            resp.sendRedirect(req.getContextPath() + "/admin/dashboard");

        } catch (DuplicateAccountException e) {
            req.setAttribute("errorMessage", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/admin/addairline.jsp").forward(req, resp);
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/admin/addairline.jsp").forward(req, resp);
        }
    }
}
