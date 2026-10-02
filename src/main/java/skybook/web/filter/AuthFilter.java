package skybook.web.filter;

import skybook.model.UserAccount;
import skybook.model.UserAccount.Role;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/**
 * AuthFilter — guards a URL prefix so only a logged-in user with the required
 * Role (set as an init-param in web.xml) can reach it. Anyone else is bounced
 * back to /login.
 *
 * This is the WEB replacement for the console app's static, single-user
 * AuthService.currentSession field: each browser gets its own HttpSession,
 * and this filter checks THAT session's user, so concurrent users never
 * interfere with each other.
 */
public class AuthFilter implements Filter {

    private Role requiredRole;

    @Override
    public void init(FilterConfig cfg) {
        String role = cfg.getInitParameter("requiredRole");
        this.requiredRole = Role.valueOf(role);
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest request   = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session          = request.getSession(false);

        UserAccount user = (session != null) ? (UserAccount) session.getAttribute("user") : null;

        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login?next="
                    + request.getRequestURI().substring(request.getContextPath().length()));
            return;
        }

        if (user.getRole() != requiredRole) {
            request.setAttribute("errorMessage",
                    "Access denied: this page requires a " + requiredRole + " account.");
            request.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(request, response);
            return;
        }

        chain.doFilter(req, res);
    }

    @Override
    public void destroy() {}
}
