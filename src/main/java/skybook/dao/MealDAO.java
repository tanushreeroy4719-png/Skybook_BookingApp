package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Meal;
import skybook.model.Meal.MealCategory;
import skybook.model.Meal.DietType;
import skybook.model.Meal.MealType;
import skybook.util.DBConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * MealDAO — reads Meals table; inserts BookingMeals.
 *
 * Java-II U6: ArrayList for meal lists.
 * DBMS U7:    JOIN between BookingMeals and Meals for history display.
 *             Subquery for total meal cost per booking.
 */
public class MealDAO {

    public List<Meal> findByAirline(int airlineId) throws DatabaseException {
        String sql = """
                SELECT m.*, al.AirlineName
                FROM Meals m
                JOIN Airlines al ON m.AirlineID = al.AirlineID
                WHERE m.AirlineID = ?
                ORDER BY m.MealCategory, m.Price
                """;
        List<Meal> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, airlineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapMeal(rs));
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("MealDAO.findByAirline", e);
        }
    }

    public Meal findById(int mealId) throws DatabaseException {
        String sql = "SELECT m.*, al.AirlineName FROM Meals m "
                   + "JOIN Airlines al ON m.AirlineID = al.AirlineID "
                   + "WHERE m.MealID = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, mealId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapMeal(rs);
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("MealDAO.findById", e);
        }
    }

    /**
     * Records a meal choice for a booking.
     * Uses shared Connection so it participates in the booking transaction.
     * Java-II U10: Transactional participation.
     */
    public void insertBookingMeal(int bookingId, int passengerId,
                                  int mealId, int qty, Connection c)
            throws SQLException {
        String sql = "INSERT INTO BookingMeals "
                   + "(BookingID, PassengerID, MealID, Quantity) VALUES (?, ?, ?, ?)";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            ps.setInt(2, passengerId);
            ps.setInt(3, mealId);
            ps.setInt(4, qty);
            ps.executeUpdate();
        }
    }

    /**
     * Returns total meal cost for a booking.
     * DBMS U4: Aggregate function SUM with COALESCE for null safety.
     */
    public BigDecimal totalMealCost(int bookingId) throws DatabaseException {
        String sql = """
                SELECT COALESCE(SUM(m.Price * bm.Quantity), 0)
                FROM BookingMeals bm
                JOIN Meals m ON bm.MealID = m.MealID
                WHERE bm.BookingID = ?
                """;
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
            return BigDecimal.ZERO;
        } catch (SQLException e) {
            throw new DatabaseException("MealDAO.totalMealCost", e);
        }
    }

    private Meal mapMeal(ResultSet rs) throws SQLException {
        Meal m = new Meal();
        m.setMealId(rs.getInt("MealID"));
        m.setAirlineId(rs.getInt("AirlineID"));
        m.setMealName(rs.getString("MealName"));
        try {
            m.setMealCategory(MealCategory.valueOf(rs.getString("MealCategory")));
        } catch (IllegalArgumentException ignored) {}
        try {
            // DB has "Non-Veg" — strip hyphen for enum matching
            String dt = rs.getString("DietType").replace("-", "");
            m.setDietType(DietType.valueOf(dt));
        } catch (IllegalArgumentException ignored) {}
        try {
            String mt = rs.getString("MealType").replace("-", "");
            m.setMealType(MealType.valueOf(mt));
        } catch (IllegalArgumentException ignored) {}
        m.setPrice(rs.getBigDecimal("Price"));
        m.setAirlineName(rs.getString("AirlineName"));
        return m;
    }
}
