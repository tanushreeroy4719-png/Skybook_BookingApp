package skybook.web.servlet.passenger;

import skybook.model.UserAccount;
import skybook.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/** Booking.com-style Stays: search (GET), hotel page (GET ?id=), book (POST), my stays (GET ?view=mine). */
@WebServlet("/passenger/stays")
public class StaysServlet extends HttpServlet {

    private static final String BASE = "/WEB-INF/jsp/passenger/";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setAttribute("pageTitle", "Stays");
        try (Connection c = DBConnection.getConnection()) {
            String id = req.getParameter("id");
            if ("mine".equals(req.getParameter("view"))) { myStays(req, c); forward(req, resp, "mystays.jsp"); return; }
            if (id != null) { hotelPage(req, c, Integer.parseInt(id)); forward(req, resp, "stay-book.jsp"); return; }

            String city = req.getParameter("city");
            req.setAttribute("cities", cities(c));
            req.setAttribute("city", city);
            req.setAttribute("checkIn", req.getParameter("checkIn"));
            req.setAttribute("checkOut", req.getParameter("checkOut"));
            req.setAttribute("guests", req.getParameter("guests"));
            req.setAttribute("rooms", req.getParameter("rooms"));
            if (city != null && !city.isEmpty()) {
                List<Map<String, Object>> list = new ArrayList<>();
                try (PreparedStatement ps = c.prepareStatement("SELECT * FROM hotels WHERE City = ? ORDER BY Rating DESC")) {
                    ps.setString(1, city);
                    try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(row(rs)); }
                }
                req.setAttribute("hotels", list);
            }
        } catch (Exception e) {
            req.setAttribute("errorMessage", "Stays error: " + e.getMessage() + " (did you run database/add_stays.sql?)");
        }
        forward(req, resp, "stays.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        UserAccount u = (UserAccount) req.getSession().getAttribute("user");
        try (Connection c = DBConnection.getConnection()) {
            if (req.getParameter("cancelId") != null) {
                try (PreparedStatement ps = c.prepareStatement("UPDATE hotel_bookings SET Status='Cancelled' WHERE StayID=? AND PassengerID=?")) {
                    ps.setInt(1, Integer.parseInt(req.getParameter("cancelId"))); ps.setInt(2, u.getLinkedId()); ps.executeUpdate();
                }
                resp.sendRedirect(req.getContextPath() + "/passenger/stays?view=mine"); return;
            }
            int hotelId = Integer.parseInt(req.getParameter("hotelId"));
            LocalDate in = LocalDate.parse(req.getParameter("checkIn")), out = LocalDate.parse(req.getParameter("checkOut"));
            long nights = ChronoUnit.DAYS.between(in, out);
            if (nights < 1) throw new IllegalArgumentException("Check-out must be after check-in.");
            int rooms = Math.max(1, Integer.parseInt(req.getParameter("rooms")));
            int guests = Math.max(1, Integer.parseInt(req.getParameter("guests")));
            double price;
            try (PreparedStatement ps = c.prepareStatement("SELECT PricePerNight FROM hotels WHERE HotelID=?")) {
                ps.setInt(1, hotelId);
                try (ResultSet rs = ps.executeQuery()) { if (!rs.next()) throw new IllegalArgumentException("Hotel not found."); price = rs.getDouble(1); }
            }
            double total = price * nights * rooms * 1.12; // 12% GST
            try (PreparedStatement ps = c.prepareStatement(
                    "INSERT INTO hotel_bookings (HotelID,PassengerID,CheckIn,CheckOut,Guests,Rooms,TotalPrice) VALUES (?,?,?,?,?,?,?)")) {
                ps.setInt(1, hotelId); ps.setInt(2, u.getLinkedId()); ps.setDate(3, java.sql.Date.valueOf(in));
                ps.setDate(4, java.sql.Date.valueOf(out)); ps.setInt(5, guests); ps.setInt(6, rooms); ps.setDouble(7, total);
                ps.executeUpdate();
            }
            resp.sendRedirect(req.getContextPath() + "/passenger/stays?view=mine");
        } catch (Exception e) {
            req.setAttribute("errorMessage", "Could not book: " + e.getMessage());
            forward(req, resp, "stays.jsp");
        }
    }

    private void hotelPage(HttpServletRequest req, Connection c, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT * FROM hotels WHERE HotelID=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) req.setAttribute("hotel", row(rs)); }
        }
        req.setAttribute("checkIn", req.getParameter("checkIn"));
        req.setAttribute("checkOut", req.getParameter("checkOut"));
        req.setAttribute("guests", req.getParameter("guests"));
        req.setAttribute("rooms", req.getParameter("rooms"));
    }

    private void myStays(HttpServletRequest req, Connection c) throws SQLException {
        UserAccount u = (UserAccount) req.getSession().getAttribute("user");
        List<Map<String, Object>> list = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT b.*, h.HotelName, h.City FROM hotel_bookings b JOIN hotels h ON b.HotelID=h.HotelID WHERE b.PassengerID=? ORDER BY b.StayID DESC")) {
            ps.setInt(1, u.getLinkedId());
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(row(rs)); }
        }
        req.setAttribute("stays", list);
    }

    private List<String> cities(Connection c) throws SQLException {
        List<String> l = new ArrayList<>();
        try (Statement s = c.createStatement(); ResultSet rs = s.executeQuery("SELECT DISTINCT City FROM hotels ORDER BY City")) { while (rs.next()) l.add(rs.getString(1)); }
        return l;
    }

    /** Column-name -> value map so JSPs can use ${h.HotelName} without a model class. */
    private Map<String, Object> row(ResultSet rs) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        ResultSetMetaData md = rs.getMetaData();
        for (int i = 1; i <= md.getColumnCount(); i++) m.put(md.getColumnLabel(i), rs.getObject(i));
        return m;
    }

    private void forward(HttpServletRequest req, HttpServletResponse resp, String jsp) throws ServletException, IOException {
        req.getRequestDispatcher(BASE + jsp).forward(req, resp);
    }
}
