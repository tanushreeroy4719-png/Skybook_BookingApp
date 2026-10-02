package skybook.web.servlet.admin;

import skybook.exception.Exceptions.*;
import skybook.service.AuthService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/admin/airlines/deactivate")
public class DeactivateAirlineServlet extends HttpServlet {

    private final AuthService authService = new AuthService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String username = req.getParameter("username");
        HttpSession session = req.getSession();
        try {
            authService.deactivateAirline(username);
            session.setAttribute("flashSuccess", "Airline '" + username + "' deactivated.");
        } catch (AccountNotFoundException | DatabaseException e) {
            session.setAttribute("flashError", e.getMessage());
        } catch (SecurityException e) {
            session.setAttribute("flashError", "Access denied: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/dashboard");
    }
}
