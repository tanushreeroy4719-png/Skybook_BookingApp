package skybook.dao;

import skybook.exception.Exceptions.*;
import skybook.model.Payment;
import skybook.model.Payment.PaymentStatus;
import skybook.util.DBConnection;

import java.math.BigDecimal;
import java.sql.*;

/**
 * PaymentDAO — insert payments; update status for refunds.
 * Java-II U10: Transactions — all payment writes use a shared connection from BookingService.
 * DBMS U8:     ACID — payment row is written atomically with booking (same transaction).
 */
public class PaymentDAO {

    public int insertPayment(int ticketId, BigDecimal amount,
                             String method, Connection c) throws SQLException {
        String sql = "INSERT INTO Payments (TicketID, Amount, PaymentMethod, "
                   + "TransactionDate, PaymentStatus) VALUES (?, ?, ?, NOW(), 'Completed')";
        try (PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, ticketId);
            ps.setBigDecimal(2, amount);
            ps.setString(3, method);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        return -1;
    }

    public void updateStatus(int ticketId, PaymentStatus status, Connection c)
            throws SQLException {
        String sql = "UPDATE Payments SET PaymentStatus = ? WHERE TicketID = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status.name());
            ps.setInt(2, ticketId);
            ps.executeUpdate();
        }
    }

    public Payment findByTicket(int ticketId) throws DatabaseException {
        String sql = "SELECT * FROM Payments WHERE TicketID = ? "
                   + "ORDER BY PaymentID DESC LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Payment p = new Payment();
                    p.setPaymentId(rs.getInt("PaymentID"));
                    p.setTicketId(rs.getInt("TicketID"));
                    p.setAmount(rs.getBigDecimal("Amount"));
                    p.setPaymentMethod(rs.getString("PaymentMethod"));
                    Timestamp ts = rs.getTimestamp("TransactionDate");
                    if (ts != null) p.setTransactionDate(ts.toLocalDateTime());
                    try {
                        p.setPaymentStatus(PaymentStatus.valueOf(
                                rs.getString("PaymentStatus")));
                    } catch (IllegalArgumentException ignored) {}
                    return p;
                }
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("PaymentDAO.findByTicket", e);
        }
    }
}
