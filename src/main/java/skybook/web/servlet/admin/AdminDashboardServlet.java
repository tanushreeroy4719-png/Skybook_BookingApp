package skybook.web.servlet.admin;

import skybook.dao.AirlineDAO;
import skybook.exception.Exceptions.DatabaseException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/admin/dashboard")
public class AdminDashboardServlet extends HttpServlet {

    private final AirlineDAO airlineDAO = new AirlineDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Admin — Airlines");
        HttpSession session = req.getSession();
        Object flashSuccess = session.getAttribute("flashSuccess");
        Object flashError = session.getAttribute("flashError");
        if (flashSuccess != null) { req.setAttribute("successMessage", flashSuccess); session.removeAttribute("flashSuccess"); }
        if (flashError != null)   { req.setAttribute("errorMessage", flashError); session.removeAttribute("flashError"); }

        try {
            req.setAttribute("airlines", airlineDAO.findAll());
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
        }
        req.getRequestDispatcher("/WEB-INF/jsp/admin/dashboard.jsp").forward(req, resp);
    }
}
