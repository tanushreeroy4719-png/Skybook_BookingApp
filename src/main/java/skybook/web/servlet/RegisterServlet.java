package skybook.web.servlet;

import skybook.exception.Exceptions.*;
import skybook.model.UserAccount;
import skybook.service.AuthService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    private final AuthService authService = new AuthService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Create Account");
        req.getRequestDispatcher("/WEB-INF/jsp/register.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setAttribute("pageTitle", "Create Account");
        String username  = req.getParameter("username");
        String password  = req.getParameter("password");
        String firstName = req.getParameter("firstName");
        String lastName  = req.getParameter("lastName");
        String email     = req.getParameter("email");
        String contactNo = req.getParameter("contactNo");
        String dobStr    = req.getParameter("dob");
        String passport  = req.getParameter("passport");

        try {
            if (username == null || username.isBlank() || password == null || password.isBlank()
                    || firstName == null || firstName.isBlank() || email == null || email.isBlank()
                    || dobStr == null || dobStr.isBlank()) {
                throw new ValidationException("Form", "Please fill in all required fields.");
            }

            LocalDate dob = LocalDate.parse(dobStr);

            UserAccount ua = authService.registerPassenger(
                    username, password, firstName, lastName, email, contactNo, dob, passport);

            HttpSession session = req.getSession(true);
            session.setAttribute("user", ua);
            resp.sendRedirect(req.getContextPath() + "/passenger/dashboard");

        } catch (DuplicateAccountException | ValidationException e) {
            req.setAttribute("errorMessage", e.getMessage());
            echoBack(req, username, firstName, lastName, email, contactNo, dobStr, passport);
            req.getRequestDispatcher("/WEB-INF/jsp/register.jsp").forward(req, resp);
        } catch (DatabaseException e) {
            req.setAttribute("errorMessage", "Database error: " + e.getMessage());
            echoBack(req, username, firstName, lastName, email, contactNo, dobStr, passport);
            req.getRequestDispatcher("/WEB-INF/jsp/register.jsp").forward(req, resp);
        } catch (java.time.format.DateTimeParseException e) {
            req.setAttribute("errorMessage", "Please enter a valid date of birth.");
            echoBack(req, username, firstName, lastName, email, contactNo, dobStr, passport);
            req.getRequestDispatcher("/WEB-INF/jsp/register.jsp").forward(req, resp);
        }
    }

    private void echoBack(HttpServletRequest req, String username, String firstName, String lastName,
                           String email, String contactNo, String dobStr, String passport) {
        req.setAttribute("username", username);
        req.setAttribute("firstName", firstName);
        req.setAttribute("lastName", lastName);
        req.setAttribute("email", email);
        req.setAttribute("contactNo", contactNo);
        req.setAttribute("dob", dobStr);
        req.setAttribute("passport", passport);
    }
}
