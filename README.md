# SkyBook ✈️🏨

**A Booking.com-style flight and hotel booking web app built with Java Servlets, JSP and MySQL.**

![Java](https://img.shields.io/badge/Java-17%2B-orange)
![Jakarta EE](https://img.shields.io/badge/Jakarta%20EE-10-blue)
![Tomcat](https://img.shields.io/badge/Tomcat-11-yellow)
![MySQL](https://img.shields.io/badge/MySQL-8%2B-lightblue)
![Maven](https://img.shields.io/badge/Build-Maven-red)
![License](https://img.shields.io/badge/License-MIT-green)

SkyBook lets passengers search and book flights and hotel stays, airlines manage their own flights, and admins manage airlines and aircraft. The interface is inspired by Booking.com and works on phones. This is a student project (Computer Engineering, 2nd semester) and is not affiliated with Booking.com.
 About

SkyBook is a full-stack booking platform where passengers search and book flights and hotel stays, airlines manage their own flights, and admins manage airlines and aircraft. The interface is inspired by Booking.com (navy and yellow theme) and is responsive on phones.

It is a student project built to practise MVC, the DAO pattern, JDBC with connection pooling, and role-based access control. It is not affiliated with Booking.com.

Features

Passenger

Search flights: round trip, one way, direct-only; filter by stops and meals; sort by price, duration or departure time
Each flight shows whether meals are available (the meal menu is hidden when they are not)
Live seat map, extra luggage option, printable ticket
Booking history and cancellation with airline-specific refund rules
Search, book and cancel hotel stays ("My Stays")

Airline

Add, edit and delete flights
View bookings made on the airline's flights

Admin

Register or deactivate airlines
Add aircraft with automatically generated seats and view the fleet

General

Session-based login with three roles, protected by a servlet filter
Daily flight schedule across many Indian and international routes (Ahmedabad, Delhi, Kolkata, Mumbai, Dubai, London and more)
Booking.com-style responsive UI
Tech stack
Layer	Technology
Language	Java 17+
Web	Jakarta Servlet 6.0, JSP, JSTL 3.0, Bootstrap 5
Server	Apache Tomcat 11
Database	MySQL 8+ (XAMPP) with HikariCP connection pool
Build	Maven (WAR)
Architecture
Browser -> JSP views -> Servlets (controllers) -> Services -> DAOs -> MySQL
                              ^
                         AuthFilter (role guard for /passenger, /airline, /admin)
model: entities such as Flight, Booking, Seat, Passenger, Airline, Aircraft
dao: one DAO per table (JDBC, try-with-resources, pooled connections)
service: business logic such as booking, authentication and per-airline cancellation policies
web/servlet: controllers grouped by role (admin, airline, passenger)
web/filter: AuthFilter checks the session user's role before allowing access
Getting started
Prerequisites
JDK 17 or newer
Apache Tomcat 11
XAMPP (MySQL 8+) or any MySQL server
NetBeans or any IDE with Maven support
Setup
Start MySQL in XAMPP and open phpMyAdmin.
Import the SQL files in this order (from the database/ folder):
skybook_complete_import.sql
fix_keys_and_autoincrement.sql
add_more_flights.sql
add_daily_flights.sql
add_stays.sql
Open the project in your IDE, set the server to Tomcat 11 and the JDK to 17+.
If your MySQL root user has a password, set it in src/main/java/skybook/util/DBConnection.java.
Clean and Build, then Run, and open http://localhost:8080/skybook-web/.

Tip: search flights between 31 Oct and 7 Nov 2026, or any date from 2 Oct to 31 Dec 2026.

Demo logins
Role	Username	Password
Admin	admin	admin123
Airline	the airline's username	airline@123
Passenger	register your own account	your choice

These are demo credentials for local use only. Change them before deploying anywhere public.

Project structure
skybook-web/
  database/                 SQL files (schema, seed data, flights, stays)
  src/main/java/skybook/
    model/  dao/  service/  exception/  util/
    web/servlet/ (admin, airline, passenger)   web/filter/
  src/main/webapp/
    css/  images/  index.jsp
    WEB-INF/jsp/ (admin, airline, passenger, common)
  pom.xml
Roadmap
Meals checkbox in the airline Add/Edit Flight forms
Hotel management for admins
Online payment demo and email confirmations
Screenshots section in this README
License

Released under the MIT License.

Author

Built by Tanushree, Computer Engineering student at LJ University.
