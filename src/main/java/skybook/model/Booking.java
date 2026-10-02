package skybook.model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Booking — maps to the Bookings table.
 * Status: Pending | Confirmed | Cancelled
 */
public class Booking {

    public enum Status { Pending, Confirmed, Cancelled, Completed }

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy HH:mm");

    private int           bookingId;
    private int           flightId;
    private int           passengerId;
    private LocalDateTime bookingDate;
    private Status        status;

    // Joined display fields
    private String passengerName;
    private String flightInfo;

    public Booking() {}

    public Booking(int flightId, int passengerId, Status status) {
        this.flightId    = flightId;
        this.passengerId = passengerId;
        this.status      = status;
        this.bookingDate = LocalDateTime.now();
    }

    public String getBookingDateFormatted() {
        return bookingDate == null ? "N/A" : bookingDate.format(FMT);
    }

    // Getters & Setters
    public int getBookingId()                    { return bookingId; }
    public void setBookingId(int id)             { this.bookingId = id; }
    public int getFlightId()                     { return flightId; }
    public void setFlightId(int id)              { this.flightId = id; }
    public int getPassengerId()                  { return passengerId; }
    public void setPassengerId(int id)           { this.passengerId = id; }
    public LocalDateTime getBookingDate()        { return bookingDate; }
    public void setBookingDate(LocalDateTime d)  { this.bookingDate = d; }
    public Status getStatus()                    { return status; }
    public void setStatus(Status s)              { this.status = s; }
    public String getPassengerName()             { return passengerName; }
    public void setPassengerName(String n)       { this.passengerName = n; }
    public String getFlightInfo()                { return flightInfo; }
    public void setFlightInfo(String f)          { this.flightInfo = f; }

    @Override
    public String toString() {
        return String.format("Booking[%d] Flight:%d Passenger:%d Status:%s Date:%s",
                bookingId, flightId, passengerId, status, getBookingDateFormatted());
    }
}
