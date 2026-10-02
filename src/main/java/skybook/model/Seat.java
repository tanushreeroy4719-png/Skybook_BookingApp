package skybook.model;

import java.math.BigDecimal;

/**
 * Seat — maps to the Seats table (weak entity, PK is AircraftID + SeatNumber).
 *
 * DS coverage: The seat layout is visualised as a 2-D array in SeatMapPrinter.
 * SeatPosition encodes surcharge tier (Window > Aisle > Middle).
 */
public class Seat {

    public enum SeatClass    { Economy, Business, First }
    public enum SeatPosition { Aisle, Window, Middle }

    private int          aircraftId;
    private String       seatNumber;    // e.g. "1W", "3A2", "5M"
    private SeatClass    seatClass;
    private SeatPosition seatPosition;
    private BigDecimal   seatSurcharge;
    private boolean      isAvailable;

    // Derived — set from joined booking passenger name
    private String bookedByName;

    public Seat() {}

    public Seat(int aircraftId, String seatNumber, SeatClass seatClass,
                SeatPosition seatPosition, BigDecimal seatSurcharge, boolean isAvailable) {
        this.aircraftId   = aircraftId;
        this.seatNumber   = seatNumber;
        this.seatClass    = seatClass;
        this.seatPosition = seatPosition;
        this.seatSurcharge = seatSurcharge;
        this.isAvailable  = isAvailable;
    }

    // ── Derived helpers ───────────────────────────────────────────────────────

    /** Single letter code used in seat map display: A/W/M */
    public String getPositionCode() {
        if (seatPosition == null) return "?";
        return switch (seatPosition) {
            case Aisle  -> "A";
            case Window -> "W";
            case Middle -> "M";
        };
    }

    /** Display label for surcharge: e.g. "+₹150" or "Free" */
    public String getSurchargeLabel() {
        if (seatSurcharge == null || seatSurcharge.compareTo(BigDecimal.ZERO) == 0) return "Free";
        return "+₹" + seatSurcharge.toPlainString();
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public int getAircraftId()                    { return aircraftId; }
    public void setAircraftId(int id)             { this.aircraftId = id; }
    public String getSeatNumber()                 { return seatNumber; }
    public void setSeatNumber(String n)           { this.seatNumber = n; }
    public SeatClass getSeatClass()               { return seatClass; }
    public void setSeatClass(SeatClass c)         { this.seatClass = c; }
    public SeatPosition getSeatPosition()         { return seatPosition; }
    public void setSeatPosition(SeatPosition p)   { this.seatPosition = p; }
    public BigDecimal getSeatSurcharge()          { return seatSurcharge; }
    public void setSeatSurcharge(BigDecimal s)    { this.seatSurcharge = s; }
    public boolean isAvailable()                  { return isAvailable; }
    public void setAvailable(boolean b)           { this.isAvailable = b; }
    public String getBookedByName()               { return bookedByName; }
    public void setBookedByName(String n)         { this.bookedByName = n; }

    @Override
    public String toString() {
        return String.format("Seat %-5s [%s / %s] Surcharge:%-7s Available:%s",
                seatNumber, seatClass, seatPosition, getSurchargeLabel(), isAvailable ? "YES" : "NO");
    }
}
