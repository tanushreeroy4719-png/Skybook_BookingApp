package skybook.model;

/**
 * UserAccount — application-level login credentials.
 * Role: PASSENGER | AIRLINE | ADMIN
 *
 * Passwords are stored as SHA-256 hex hashes (via PasswordUtil).
 * Java-II U2: Packages & Access Modifiers — role field uses enum scoped to this class.
 * DBMS U8: Security & Access Control — role-based access enforced at service layer.
 *
 * NOTE: This maps to the app_users table (created separately in setup SQL,
 *       not part of the SkyBook flight schema but in the same DB).
 */
public class UserAccount {

    public enum Role { PASSENGER, AIRLINE, ADMIN }

    private int    userId;
    private String username;       // unique login ID
    private String passwordHash;   // SHA-256 hex
    private Role   role;
    private int    linkedId;       // PassengerID or AirlineID; 0 for ADMIN
    private boolean isActive;

    public UserAccount() {}

    public UserAccount(String username, String passwordHash, Role role,
                       int linkedId, boolean isActive) {
        this.username     = username;
        this.passwordHash = passwordHash;
        this.role         = role;
        this.linkedId     = linkedId;
        this.isActive     = isActive;
    }

    // Getters & Setters
    public int getUserId()                    { return userId; }
    public void setUserId(int id)             { this.userId = id; }
    public String getUsername()               { return username; }
    public void setUsername(String u)         { this.username = u; }
    public String getPasswordHash()           { return passwordHash; }
    public void setPasswordHash(String h)     { this.passwordHash = h; }
    public Role getRole()                     { return role; }
    public void setRole(Role r)               { this.role = r; }
    public int getLinkedId()                  { return linkedId; }
    public void setLinkedId(int id)           { this.linkedId = id; }
    public boolean isActive()                 { return isActive; }
    public void setActive(boolean b)          { this.isActive = b; }

    @Override
    public String toString() {
        return String.format("User[%d] %s Role:%s LinkedId:%d Active:%s",
                userId, username, role, linkedId, isActive);
    }
}
