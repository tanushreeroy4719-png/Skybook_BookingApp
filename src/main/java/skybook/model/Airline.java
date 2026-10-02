package skybook.model;

/**
 * Airline — maps to the Airlines table.
 * Java-II U6: Airlines loaded into HashMap<Integer,Airline> in AirlineDAO.
 */
public class Airline {

    private int     airlineId;
    private String  airlineName;
    private String  iataCode;
    private String  country;
    private String  contactEmail;
    private boolean isActive;

    public Airline() {}

    public Airline(String airlineName, String iataCode, String country,
                   String contactEmail, boolean isActive) {
        this.airlineName  = airlineName;
        this.iataCode     = iataCode;
        this.country      = country;
        this.contactEmail = contactEmail;
        this.isActive     = isActive;
    }

    // Getters & Setters
    public int getAirlineId()                  { return airlineId; }
    public void setAirlineId(int id)           { this.airlineId = id; }
    public String getAirlineName()             { return airlineName; }
    public void setAirlineName(String n)       { this.airlineName = n; }
    public String getIataCode()                { return iataCode; }
    public void setIataCode(String c)          { this.iataCode = c; }
    public String getCountry()                 { return country; }
    public void setCountry(String c)           { this.country = c; }
    public String getContactEmail()            { return contactEmail; }
    public void setContactEmail(String e)      { this.contactEmail = e; }
    public boolean isActive()                  { return isActive; }
    public void setActive(boolean b)           { this.isActive = b; }

    @Override
    public String toString() {
        return String.format("Airline[%d] %s (%s) %s",
                airlineId, airlineName, iataCode, isActive ? "Active" : "Inactive");
    }
}
