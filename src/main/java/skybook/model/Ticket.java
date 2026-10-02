package skybook.model;

import java.math.BigDecimal;

/**
 * Ticket — maps to the Tickets table (1:1 with Bookings).
 * PNR is a unique 10-char alphanumeric reference.
 */
public class Ticket {

    private int        ticketId;
    private int        bookingId;
    private int        aircraftId;
    private String     seatNumber;
    private BigDecimal pricePaid;
    private String     pnr;
    private BigDecimal extraLuggageKg;
    private BigDecimal extraLuggageCost;

    // Joined display fields
    private String passengerName;
    private String flightRoute;          // e.g. "DEL → BOM"
    private String departureTime;
    private String airlineName;
    private String seatClass;
    private String seatPosition;
    private BigDecimal mealCost;         // sum of meals for this booking

    public Ticket() {}

    public BigDecimal getTotalCost() {
        BigDecimal total = pricePaid == null ? BigDecimal.ZERO : pricePaid;
        if (extraLuggageCost != null) total = total.add(extraLuggageCost);
        if (mealCost != null)         total = total.add(mealCost);
        return total;
    }

    // Getters & Setters
    public int getTicketId()                          { return ticketId; }
    public void setTicketId(int id)                   { this.ticketId = id; }
    public int getBookingId()                         { return bookingId; }
    public void setBookingId(int id)                  { this.bookingId = id; }
    public int getAircraftId()                        { return aircraftId; }
    public void setAircraftId(int id)                 { this.aircraftId = id; }
    public String getSeatNumber()                     { return seatNumber; }
    public void setSeatNumber(String s)               { this.seatNumber = s; }
    public BigDecimal getPricePaid()                  { return pricePaid; }
    public void setPricePaid(BigDecimal p)            { this.pricePaid = p; }
    public String getPnr()                            { return pnr; }
    public void setPnr(String p)                      { this.pnr = p; }
    public BigDecimal getExtraLuggageKg()             { return extraLuggageKg; }
    public void setExtraLuggageKg(BigDecimal k)       { this.extraLuggageKg = k; }
    public BigDecimal getExtraLuggageCost()           { return extraLuggageCost; }
    public void setExtraLuggageCost(BigDecimal c)     { this.extraLuggageCost = c; }
    public String getPassengerName()                  { return passengerName; }
    public void setPassengerName(String n)            { this.passengerName = n; }
    public String getFlightRoute()                    { return flightRoute; }
    public void setFlightRoute(String r)              { this.flightRoute = r; }
    public String getDepartureTime()                  { return departureTime; }
    public void setDepartureTime(String t)            { this.departureTime = t; }
    public String getAirlineName()                    { return airlineName; }
    public void setAirlineName(String n)              { this.airlineName = n; }
    public String getSeatClass()                      { return seatClass; }
    public void setSeatClass(String c)                { this.seatClass = c; }
    public String getSeatPosition()                   { return seatPosition; }
    public void setSeatPosition(String p)             { this.seatPosition = p; }
    public BigDecimal getMealCost()                   { return mealCost; }
    public void setMealCost(BigDecimal c)             { this.mealCost = c; }
}
