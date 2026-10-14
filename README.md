# SkyBook ✈️🏨

**A Booking.com-style flight and hotel booking web app built with Java Servlets, JSP and MySQL.**

![Java](https://img.shields.io/badge/Java-17%2B-orange)
![Jakarta EE](https://img.shields.io/badge/Jakarta%20EE-10-blue)
![Tomcat](https://img.shields.io/badge/Tomcat-11-yellow)
![MySQL](https://img.shields.io/badge/MySQL-8%2B-lightblue)
![Maven](https://img.shields.io/badge/Build-Maven-red)
![License](https://img.shields.io/badge/License-MIT-green)

SkyBook lets passengers search and book flights and hotel stays, airlines manage their own flights, and admins manage airlines and aircraft. The interface is inspired by Booking.com and works on phones. This is a student project (Computer Engineering, 2nd semester) and is not affiliated with Booking.com.

## Screenshots

_Add your screenshots to a `screenshots/` folder and link them here, for example:_
`![Home](screenshots/home.png)`

## Features

- **Three roles:** Passenger, Airline and Admin, each with its own dashboard and session-based access control
- **Flight search:** round trip, one way and direct-only options, filter by stops and meals, sort by price, duration or departure
- **Meals:** every flight shows whether meals are available, and the meal menu is hidden when they are not
- **Daily flights:** 4,000+ flights on 26 routes (Ahmedabad, Delhi, Kolkata, Mumbai, Dubai, London and more)
- **Booking:** live seat map, extra luggage, tickets you can print, booking history and cancellation
- **Stays:** search hotels by city, book, and cancel from "My Stays"
- **Airline tools:** add, edit and delete flights, and view bookings on your flights
- **Admin tools:** register or deactivate airlines, add aircraft with auto-generated seats
- **Booking.com-style UI:** navy and yellow theme, collapsible mobile footer, responsive layout

## Tech stack

| Layer | Technology |
|---|---|
| Language | Java 17+ |
| Web | Jakarta Servlet 6.0, JSP, JSTL 3.0, Bootstrap 5 |
| Server | Apache Tomcat 11 |
| Database | MySQL 8+ (XAMPP) with HikariCP connection pool |
| Build | Maven (WAR) |

## Setup

1. **Start MySQL** in XAMPP and open phpMyAdmin.
2. **Import the SQL files in this order** (from the `database/` folder):
   1. `skybook_complete_import.sql`
   2. `fix_keys_and_autoincrement.sql`
   3. `add_more_flights.sql`
   4. `add_daily_flights.sql`
   5. `add_stays.sql`
3. **Open the project** in NetBeans (or any IDE with Maven), set the server to **Tomcat 11** and the JDK to **17 or newer**.
4. If your MySQL root user has a password, set it in `src/main/java/skybook/util/DBConnection.java`.
5. **Clean and Build, then Run**, and open `http://localhost:8080/skybook-web/`.

Tip: search flights between 31 Oct and 7 Nov 2026, or any date from 2 Oct to 31 Dec 2026.

## Demo logins

| Role | Username | Password |
|---|---|---|
| Admin | `admin` | `admin123` |
| Airline | the airline's username | `airline@123` |
| Passenger | register your own account | your choice |

These are demo credentials for local use only. Change them before deploying anywhere public.

## Project layout

```
skybook-web/
  database/                 SQL files (schema, seed data, flights, stays)
  src/main/java/skybook/
    model/  dao/  service/  exception/  util/
    web/servlet/ (admin, airline, passenger)   web/filter/
  src/main/webapp/
    css/  images/  index.jsp
    WEB-INF/jsp/ (admin, airline, passenger, common)
  pom.xml
```

## Roadmap

- Meals checkbox in the airline Add/Edit Flight forms
- Hotel management for admins
- Online payment demo and email confirmations

## License

Released under the [MIT License](LICENSE).

## Author

Built by **Tanushree**, Computer Engineering student at LJ University.
