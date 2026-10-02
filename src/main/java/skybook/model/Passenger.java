package skybook.model;

import java.time.LocalDate;
import java.time.Period;

/**
 * Passenger — maps to the Passengers table.
 * Age is virtual in DB (GENERATED ALWAYS AS) — we replicate the computation in Java.
 * Java-II: Java Date-Time API (LocalDate, Period).
 */
public class Passenger {
    private int       passengerId;
    private String    firstName;
    private String    lastName;
    private String    email;
    private String    contactNo;
    private LocalDate dateOfBirth;
    private String    passportNumber;

    public Passenger() {}

    public Passenger(String firstName, String lastName, String email,
                     String contactNo, LocalDate dateOfBirth, String passportNumber) {
        this.firstName      = firstName;
        this.lastName       = lastName;
        this.email          = email;
        this.contactNo      = contactNo;
        this.dateOfBirth    = dateOfBirth;
        this.passportNumber = passportNumber;
    }

    // ── Derived ───────────────────────────────────────────────────────────────

    /** Mirrors the VIRTUAL age column in MySQL */
    public int getAge() {
        if (dateOfBirth == null) return 0;
        return Period.between(dateOfBirth, LocalDate.now()).getYears();
    }

    public String getFullName() {
        return firstName + " " + lastName;
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public int getPassengerId()                       { return passengerId; }
    public void setPassengerId(int id)                { this.passengerId = id; }
    public String getFirstName()                      { return firstName; }
    public void setFirstName(String n)                { this.firstName = n; }
    public String getLastName()                       { return lastName; }
    public void setLastName(String n)                 { this.lastName = n; }
    public String getEmail()                          { return email; }
    public void setEmail(String e)                    { this.email = e; }
    public String getContactNo()                      { return contactNo; }
    public void setContactNo(String c)                { this.contactNo = c; }
    public LocalDate getDateOfBirth()                 { return dateOfBirth; }
    public void setDateOfBirth(LocalDate d)           { this.dateOfBirth = d; }
    public String getPassportNumber()                 { return passportNumber; }
    public void setPassportNumber(String p)           { this.passportNumber = p; }

    @Override
    public String toString() {
        return String.format("Passenger[%d] %s | DOB:%s | Age:%d | Email:%s",
                passengerId, getFullName(), dateOfBirth, getAge(), email);
    }
}
