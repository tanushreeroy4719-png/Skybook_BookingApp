package skybook.web.servlet;

import skybook.exception.Exceptions.*;
import skybook.model.UserAccount;
import skybook.service.AuthService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private final AuthService authService = new AuthService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Login");
        req.getRequestDispatcher("/WEB-INF/jsp/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String username = req.getParameter("username");
        String password = req.getParameter("password");
        String next     = req.getParameter("next");

        try {
            UserAccount user = authService.login(username, password);

            // Store in THIS browser's session only — each user gets their own.
            HttpSession session = req.getSession(true);
            session.setAttribute("user", user);

            String target;
            switch (user.getRole()) {
                case PASSENGER: target = "/passenger/dashboard"; break;
                case AIRLINE:   target = "/airline/dashboard"; break;
                case ADMIN:     target = "/admin/dashboard"; break;
                default:        target = "/";
            }
            if (next != null && !next.isEmpty()) target = next;

            resp.sendRedirect(req.getContextPath() + target);

        } catch (InvalidCredentialsException | AccountInactiveException e) {
            req.setAttribute("pageTitle", "Login");
            req.setAttribute("errorMessage", e.getMessage());
            req.setAttribute("username", username);
            req.getRequestDispatcher("/WEB-INF/jsp/login.jsp").forward(req, resp);
        } catch (DatabaseException e) {
            req.setAttribute("pageTitle", "Login");
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/login.jsp").forward(req, resp);
        }
    }
}
