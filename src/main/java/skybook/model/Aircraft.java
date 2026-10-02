package skybook.model;

/**
 * Aircraft — maps to the Aircraft table.
 *
 * Each aircraft belongs to one Airline (AirlineID FK).
 * Seats are a weak entity keyed on (AircraftID, SeatNumber).
 *
 * Java-II U1: Encapsulation — private fields, public getters/setters.
 * DBMS       : Maps directly to Aircraft table in ER diagram.
 *              AircraftID is the FK used by Flights and Seats.
 */
public class Aircraft {

    private int    aircraftId;
    private int    airlineId;
    private String registrationNo;
    private String aircraftModel;
    private int    totalSeats;
    private String status;         // Active | Grounded | Retired
    private int    manufactureYear;
    // Joined display field
    private String airlineName;

    public Aircraft() {}

    public Aircraft(int airlineId, String registrationNo, String aircraftModel,
                    int totalSeats, String status, int manufactureYear) {
        this.airlineId      = airlineId;
        this.registrationNo = registrationNo;
        this.aircraftModel  = aircraftModel;
        this.totalSeats     = totalSeats;
        this.status         = status;
        this.manufactureYear = manufactureYear;
    }

    public int    getAircraftId()                    { return aircraftId; }
    public void   setAircraftId(int id)              { this.aircraftId = id; }
    public int    getAirlineId()                     { return airlineId; }
    public void   setAirlineId(int id)               { this.airlineId = id; }
    public String getRegistrationNo()                { return registrationNo; }
    public void   setRegistrationNo(String r)        { this.registrationNo = r; }
    public String getAircraftModel()                 { return aircraftModel; }
    public void   setAircraftModel(String m)         { this.aircraftModel = m; }
    public int    getTotalSeats()                    { return totalSeats; }
    public void   setTotalSeats(int s)               { this.totalSeats = s; }
    public String getStatus()                        { return status; }
    public void   setStatus(String s)                { this.status = s; }
    public int    getManufactureYear()               { return manufactureYear; }
    public void   setManufactureYear(int y)          { this.manufactureYear = y; }
    public String getAirlineName()                   { return airlineName; }
    public void   setAirlineName(String n)           { this.airlineName = n; }

    @Override
    public String toString() {
        return String.format("Aircraft[%d] %s | Reg:%s | Seats:%d | Status:%s",
                aircraftId, aircraftModel, registrationNo, totalSeats, status);
    }
}
