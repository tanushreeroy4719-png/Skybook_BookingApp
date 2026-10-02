package skybook.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Payment — maps to the Payments table.
 * PaymentStatus: Pending | Completed | Refunded | Failed
 *
 * Java-II U10: JDBC Advanced — Transactions: payment insert uses
 *              setAutoCommit(false) + commit/rollback in PaymentService.
 */
public class Payment {

    public enum PaymentStatus { Pending, Completed, Refunded, Failed }

    private static final DateTimeFormatter FMT =
            DateTimeFormatter.ofPattern("dd-MMM-yyyy HH:mm:ss");

    private int           paymentId;
    private int           ticketId;
    private BigDecimal    amount;
    private String        paymentMethod;   // UPI | Card | NetBanking | Wallet | Cash
    private LocalDateTime transactionDate;
    private PaymentStatus paymentStatus;

    // Joined
    private String pnr;

    public Payment() {}

    public Payment(int ticketId, BigDecimal amount, String paymentMethod) {
        this.ticketId        = ticketId;
        this.amount          = amount;
        this.paymentMethod   = paymentMethod;
        this.transactionDate = LocalDateTime.now();
        this.paymentStatus   = PaymentStatus.Pending;
    }

    public String getTransactionDateFormatted() {
        return transactionDate == null ? "N/A" : transactionDate.format(FMT);
    }

    // Getters & Setters
    public int getPaymentId()                       { return paymentId; }
    public void setPaymentId(int id)                { this.paymentId = id; }
    public int getTicketId()                        { return ticketId; }
    public void setTicketId(int id)                 { this.ticketId = id; }
    public BigDecimal getAmount()                   { return amount; }
    public void setAmount(BigDecimal a)             { this.amount = a; }
    public String getPaymentMethod()                { return paymentMethod; }
    public void setPaymentMethod(String m)          { this.paymentMethod = m; }
    public LocalDateTime getTransactionDate()       { return transactionDate; }
    public void setTransactionDate(LocalDateTime d) { this.transactionDate = d; }
    public PaymentStatus getPaymentStatus()         { return paymentStatus; }
    public void setPaymentStatus(PaymentStatus s)   { this.paymentStatus = s; }
    public String getPnr()                          { return pnr; }
    public void setPnr(String p)                    { this.pnr = p; }

    @Override
    public String toString() {
        return String.format("Payment[%d] Ticket:%d ₹%.2f via %s Status:%s",
                paymentId, ticketId, amount, paymentMethod, paymentStatus);
    }
}
