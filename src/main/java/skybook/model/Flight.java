package skybook.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.Duration;
import java.time.format.DateTimeFormatter;

/**
 * Flight — maps to the Flights table.
 * Java-II: Java Date-Time API (LocalDateTime, Duration, DateTimeFormatter)
 * DBMS: Entity with FK relationships, FlightCategory (Direct/Connecting)
 */
public class Flight {

    public enum FlightType     { National, International }
    public enum FlightCategory { Direct, Connecting }

    private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy HH:mm");

    private int            flightId;
    private int            aircraftId;
    private String         departureAirportId;
    private String         arrivalAirportId;
    private LocalDateTime  departureTime;
    private LocalDateTime  arrivalTime;
    private BigDecimal     stateTaxAmount;
    private BigDecimal     basePrice;
    private FlightType     flightType;
    private FlightCategory flightCategory;
    private Integer        connectingFlightId;   // null for Direct
    private boolean        mealsAvailable = true; // meal service on board?

    // Joined fields (for display — populated by DAO queries)
    private String airlineName;
    private String departureCity;
    private String arrivalCity;
    private String aircraftModel;
    private int    availableSeats;

    public Flight() {}

    // ── Derived helpers ────────────────────────────────────────────────────────

    /** Human-readable duration like "2h 15m" */
    public String getDuration() {
        if (departureTime == null || arrivalTime == null) return "N/A";
        Duration d = Duration.between(departureTime, arrivalTime);
        long hours = d.toHours();
        long mins  = d.toMinutesPart();
        return hours + "h " + mins + "m";
    }

    /** Total price = basePrice + stateTaxAmount */
    public BigDecimal getTotalPrice() {
        if (basePrice == null || stateTaxAmount == null) return BigDecimal.ZERO;
        return basePrice.add(stateTaxAmount);
    }

    public String getDepartureFormatted() {
        return departureTime == null ? "N/A" : departureTime.format(DT_FMT);
    }

    public String getArrivalFormatted() {
        return arrivalTime == null ? "N/A" : arrivalTime.format(DT_FMT);
    }

    // ── Getters & Setters ──────────────────────────────────────────────────────

    public int getFlightId()                      { return flightId; }
    public void setFlightId(int flightId)         { this.flightId = flightId; }
    public int getAircraftId()                    { return aircraftId; }
    public void setAircraftId(int aircraftId)     { this.aircraftId = aircraftId; }
    public String getDepartureAirportId()         { return departureAirportId; }
    public void setDepartureAirportId(String id)  { this.departureAirportId = id; }
    public String getArrivalAirportId()           { return arrivalAirportId; }
    public void setArrivalAirportId(String id)    { this.arrivalAirportId = id; }
    public LocalDateTime getDepartureTime()       { return departureTime; }
    public void setDepartureTime(LocalDateTime t) { this.departureTime = t; }
    public LocalDateTime getArrivalTime()         { return arrivalTime; }
    public void setArrivalTime(LocalDateTime t)   { this.arrivalTime = t; }
    public BigDecimal getStateTaxAmount()         { return stateTaxAmount; }
    public void setStateTaxAmount(BigDecimal a)   { this.stateTaxAmount = a; }
    public BigDecimal getBasePrice()              { return basePrice; }
    public void setBasePrice(BigDecimal p)        { this.basePrice = p; }
    public FlightType getFlightType()             { return flightType; }
    public void setFlightType(FlightType t)       { this.flightType = t; }
    public FlightCategory getFlightCategory()     { return flightCategory; }
    public void setFlightCategory(FlightCategory c) { this.flightCategory = c; }
    public Integer getConnectingFlightId()        { return connectingFlightId; }
    public void setConnectingFlightId(Integer id) { this.connectingFlightId = id; }
    public boolean isMealsAvailable()             { return mealsAvailable; }
    public void setMealsAvailable(boolean m)      { this.mealsAvailable = m; }
    public String getAirlineName()                { return airlineName; }
    public void setAirlineName(String n)          { this.airlineName = n; }
    public String getDepartureCity()              { return departureCity; }
    public void setDepartureCity(String c)        { this.departureCity = c; }
    public String getArrivalCity()                { return arrivalCity; }
    public void setArrivalCity(String c)          { this.arrivalCity = c; }
    public String getAircraftModel()              { return aircraftModel; }
    public void setAircraftModel(String m)        { this.aircraftModel = m; }
    public int getAvailableSeats()                { return availableSeats; }
    public void setAvailableSeats(int n)          { this.availableSeats = n; }

    @Override
    public String toString() {
        return String.format("Flight#%d | %s → %s | %s | %s | ₹%.0f",
                flightId, departureAirportId, arrivalAirportId,
                getDepartureFormatted(), flightCategory, getTotalPrice());
    }
}
