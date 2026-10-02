package skybook.model;

/**
 * Airport — maps to the Airports table.
 * DBMS: ER Model, Relational Model concept.
 */
public class Airport {
    private String airportCode;
    private String airportName;
    private String city;
    private String country;
    private String timeZone;

    public Airport() {}

    public Airport(String airportCode, String airportName, String city, String country, String timeZone) {
        this.airportCode = airportCode;
        this.airportName = airportName;
        this.city = city;
        this.country = country;
        this.timeZone = timeZone;
    }

    // Getters & Setters
    public String getAirportCode() { return airportCode; }
    public void setAirportCode(String airportCode) { this.airportCode = airportCode; }
    public String getAirportName() { return airportName; }
    public void setAirportName(String airportName) { this.airportName = airportName; }
    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
    public String getTimeZone() { return timeZone; }
    public void setTimeZone(String timeZone) { this.timeZone = timeZone; }

    @Override
    public String toString() {
        return airportCode + " – " + airportName + ", " + city + " (" + country + ") [" + timeZone + "]";
    }
}
