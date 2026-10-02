-- =============================================================================
--  SkyBook — Complete Database Import  (single file, run after skybook_updated.sql)
--
--  Execution order (all handled below):
--    1. Base schema + seed data      (from skybook_updated.sql)
--    2. 12 new Indian airports
--    3. 40 new flights (Aug 8 evening → Aug 10 2026, Direct + Connecting)
--    4. Airline login accounts       (final password airline@123, correct linked_ids)
--    5. Stopover → Connecting migration + constraint fix
--    6. Drop phpMyAdmin view stubs, recreate as proper VIEWs
-- =============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- =============================================================================
--  DATABASE
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `skybook`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE `skybook`;

-- =============================================================================
--  DROP AGE TRIGGERS — 18+ enforced at registration only, not on travellers.
--  (Triggers were created by skybook_updated.sql; dropped here.)
-- =============================================================================
DROP TRIGGER IF EXISTS `trg_passengers_age_insert`;
DROP TRIGGER IF EXISTS `trg_passengers_age_update`;


-- =============================================================================
--  STORED PROCEDURES
-- =============================================================================

DROP PROCEDURE IF EXISTS `sp_cancel_booking`;
DROP PROCEDURE IF EXISTS `sp_confirm_booking`;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancel_booking` (
    IN  `p_booking_id`   INT,
    IN  `p_passenger_id` INT,
    OUT `p_result`       VARCHAR(100)
)
BEGIN
    DECLARE v_status    VARCHAR(20);
    DECLARE v_aircraft  INT;
    DECLARE v_seat      VARCHAR(10);
    DECLARE v_ticket_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction rolled back.';
    END;

    SELECT Status INTO v_status
    FROM Bookings
    WHERE BookingID = p_booking_id AND PassengerID = p_passenger_id;

    IF v_status IS NULL THEN
        SET p_result = 'ERROR: Booking not found or not yours.';
    ELSEIF v_status = 'Cancelled' THEN
        SET p_result = 'ERROR: Already cancelled.';
    ELSE
        START TRANSACTION;

        SELECT TicketID, AircraftID, SeatNumber
        INTO   v_ticket_id, v_aircraft, v_seat
        FROM   Tickets
        WHERE  BookingID = p_booking_id;

        UPDATE Bookings SET Status = 'Cancelled' WHERE BookingID = p_booking_id;

        UPDATE Seats SET IsAvailable = TRUE
        WHERE AircraftID = v_aircraft AND SeatNumber = v_seat;

        UPDATE Payments SET PaymentStatus = 'Refunded'
        WHERE TicketID = v_ticket_id;

        COMMIT;
        SET p_result = CONCAT('SUCCESS: Booking ', p_booking_id, ' cancelled. Seat ', v_seat, ' released.');
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_confirm_booking` (
    IN  `p_booking_id` INT,
    OUT `p_result`     VARCHAR(100)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR';
    END;

    SELECT COUNT(*) INTO v_exists FROM Bookings WHERE BookingID = p_booking_id;

    IF v_exists = 0 THEN
        SET p_result = 'ERROR: Booking not found.';
    ELSE
        UPDATE Bookings SET Status = 'Confirmed' WHERE BookingID = p_booking_id;
        SET p_result = CONCAT('SUCCESS: Booking ', p_booking_id, ' confirmed.');
    END IF;
END$$

DELIMITER ;

-- =============================================================================
--  TABLE: aircraft
-- =============================================================================

CREATE TABLE IF NOT EXISTS `aircraft` (
  `AircraftID`      int(11)      NOT NULL,
  `AirlineID`       int(11)      NOT NULL,
  `RegistrationNo`  varchar(20)  DEFAULT NULL,
  `AircraftModel`   varchar(100) NOT NULL,
  `TotalSeats`      int(11)      NOT NULL CHECK (`TotalSeats` > 0),
  `Status`          varchar(20)  DEFAULT 'Active' CHECK (`Status` IN ('Active','Grounded','Retired')),
  `ManufactureYear` int(11)      DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `aircraft` (`AircraftID`, `AirlineID`, `RegistrationNo`, `AircraftModel`, `TotalSeats`, `Status`, `ManufactureYear`) VALUES
(1,  1,  'VT-IGA', 'Airbus A320neo',   86,  'Active',   2019),
(2,  1,  'VT-IGB', 'Airbus A321neo',   100, 'Active',   2020),
(3,  2,  'VT-AIC', 'Boeing 787-8',     120, 'Active',   2018),
(4,  2,  'VT-AID', 'Boeing 777-300ER', 112, 'Active',   2016),
(5,  3,  'VT-SGC', 'Boeing 737-800',   86,  'Active',   2017),
(6,  3,  'VT-SGD', 'Boeing 737 MAX 8', 86,  'Active',   2021),
(7,  4,  'VT-TTB', 'Airbus A320neo',   86,  'Active',   2020),
(8,  2,  'VT-TTC', 'Boeing 787-9',     116, 'Active',   2019),
(9,  1,  'VT-GFA', 'Airbus A320',      86,  'Grounded', 2015),
(10, 1,  'VT-AAB', 'Airbus A320neo',   86,  'Active',   2022),
(11, 7,  'A6-EKA', 'Airbus A380-800',  86,  'Active',   2014),
(12, 7,  'A6-EKB', 'Boeing 777X',      86,  'Active',   2023),
(13, 8,  'A7-QRA', 'Airbus A350-900',  86,  'Active',   2018),
(14, 9,  '9V-SQA', 'Boeing 777-300ER', 86,  'Active',   2017),
(15, 10, 'G-BAA',  'Airbus A380-800',  86,  'Active',   2013),
(16, 11, 'D-LHA',  'Airbus A350-900',  86,  'Active',   2019),
(17, 12, 'F-AFA',  'Boeing 777-300ER', 86,  'Active',   2016),
(18, 17, 'VT-QPA', 'Boeing 737 MAX 8', 86,  'Active',   2022),
(19, 19, 'VT-IXA', 'Boeing 737-800',   86,  'Active',   2018),
(20, 13, 'JA-JLA', 'Boeing 787-9',     86,  'Retired',  2010);

-- =============================================================================
--  TABLE: airlines
-- =============================================================================

CREATE TABLE IF NOT EXISTS `airlines` (
  `AirlineID`    int(11)      NOT NULL,
  `AirlineName`  varchar(100) NOT NULL,
  `IATACode`     varchar(3)   NOT NULL,
  `Country`      varchar(50)  NOT NULL,
  `ContactEmail` varchar(100) DEFAULT NULL,
  `LogoURL`      varchar(255) DEFAULT NULL,
  `IsActive`     tinyint(1)   DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `airlines` (`AirlineID`, `AirlineName`, `IATACode`, `Country`, `ContactEmail`, `LogoURL`, `IsActive`) VALUES
(1,  'IndiGo',             '6E', 'India',          'support@indigo.in',                 'https://logos.example.com/indigo.png',    1),
(2,  'Air India',          'AI', 'India',          'care@airindia.in',                  'https://logos.example.com/airindia.png',  1),
(3,  'SpiceJet',           'SG', 'India',          'support@spicejet.com',              'https://logos.example.com/spicejet.png',  1),
(4,  'Vistara',            'UK', 'India',          'customersupport@airvistara.com',    'https://logos.example.com/vistara.png',   1),
(5,  'Go First',           'G8', 'India',          'help@gofirst.in',                   'https://logos.example.com/gofirst.png',   0),
(6,  'AirAsia India',      'I5', 'India',          'support@airasia.co.in',             'https://logos.example.com/airasia.png',   1),
(7,  'Emirates',           'EK', 'UAE',            'support@emirates.com',              'https://logos.example.com/emirates.png',  1),
(8,  'Qatar Airways',      'QR', 'Qatar',          'qrcare@qatarairways.com.qa',        'https://logos.example.com/qatar.png',     1),
(9,  'Singapore Airlines', 'SQ', 'Singapore',      'feedback@singaporeair.com.sg',      'https://logos.example.com/sia.png',       1),
(10, 'British Airways',    'BA', 'United Kingdom', 'support@ba.com',                   'https://logos.example.com/ba.png',        1),
(11, 'Lufthansa',          'LH', 'Germany',        'info@lufthansa.com',                'https://logos.example.com/lufthansa.png', 1),
(12, 'Air France',         'AF', 'France',         'support@airfrance.fr',              'https://logos.example.com/airfrance.png', 1),
(13, 'Japan Airlines',     'JL', 'Japan',          'jal@jal.co.jp',                    'https://logos.example.com/jal.png',       1),
(14, 'Qantas',             'QF', 'Australia',      'customercare@qantas.com.au',        'https://logos.example.com/qantas.png',    1),
(15, 'Malaysia Airlines',  'MH', 'Malaysia',       'support@malaysiaairlines.com',      'https://logos.example.com/mas.png',       1),
(16, 'Thai Airways',       'TG', 'Thailand',       'customer@thaiairways.com',          'https://logos.example.com/thai.png',      1),
(17, 'Akasa Air',          'QP', 'India',          'hello@akasaair.com',                'https://logos.example.com/akasa.png',     1),
(18, 'Alliance Air',       'CD', 'India',          'support@allianceair.in',            'https://logos.example.com/alliance.png',  0),
(19, 'Air India Express',  'IX', 'India',          'support@airindiaexpress.in',        'https://logos.example.com/airindiax.png', 1),
(20, 'Blue Dart Aviation', 'BZ', 'India',          'info@bluedart.com',                 'https://logos.example.com/bluedart.png',  1);

-- =============================================================================
--  TABLE: airports
-- =============================================================================

CREATE TABLE IF NOT EXISTS `airports` (
  `AirportCode` varchar(10) NOT NULL,
  `AirportName` varchar(100) NOT NULL,
  `City`        varchar(50)  NOT NULL,
  `Country`     varchar(50)  NOT NULL,
  `TimeZone`    varchar(10)  NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `airports` (`AirportCode`, `AirportName`, `City`, `Country`, `TimeZone`) VALUES
('AMD', 'Sardar Vallabhbhai Patel International',      'Ahmedabad', 'India',          'IST'),
('BKK', 'Suvarnabhumi Airport',                        'Bangkok',   'Thailand',       'ICT'),
('BLR', 'Kempegowda International Airport',            'Bengaluru', 'India',          'IST'),
('BOM', 'Chhatrapati Shivaji Maharaj International',   'Mumbai',    'India',          'IST'),
('CCU', 'Netaji Subhas Chandra Bose International',    'Kolkata',   'India',          'IST'),
('CDG', 'Charles de Gaulle Airport',                   'Paris',     'France',         'CET'),
('COK', 'Cochin International Airport',                'Kochi',     'India',          'IST'),
('DEL', 'Indira Gandhi International Airport',         'New Delhi', 'India',          'IST'),
('DOH', 'Hamad International Airport',                 'Doha',      'Qatar',          'AST'),
('DXB', 'Dubai International Airport',                 'Dubai',     'UAE',            'GST'),
('GOI', 'Goa International Airport',                   'Goa',       'India',          'IST'),
('HYD', 'Rajiv Gandhi International Airport',          'Hyderabad', 'India',          'IST'),
('JFK', 'John F. Kennedy International Airport',       'New York',  'USA',            'EST'),
('KUL', 'Kuala Lumpur International Airport',          'Kuala Lumpur', 'Malaysia',    'MYT'),
('LHR', 'London Heathrow Airport',                     'London',    'United Kingdom', 'GMT'),
('MAA', 'Chennai International Airport',               'Chennai',   'India',          'IST'),
('NRT', 'Narita International Airport',                'Tokyo',     'Japan',          'JST'),
('PNQ', 'Pune Airport',                                'Pune',      'India',          'IST'),
('SIN', 'Singapore Changi Airport',                    'Singapore', 'Singapore',      'SGT'),
('SYD', 'Sydney Kingsford Smith Airport',              'Sydney',    'Australia',      'AEST');

-- Additional major Indian airports
INSERT IGNORE INTO `airports` (`AirportCode`, `AirportName`, `City`, `Country`, `TimeZone`) VALUES
('BBI', 'Biju Patnaik International Airport',               'Bhubaneswar',         'India', 'IST'),
('GAU', 'Lokpriya Gopinath Bordoloi International Airport', 'Guwahati',            'India', 'IST'),
('IDR', 'Devi Ahilya Bai Holkar Airport',                   'Indore',              'India', 'IST'),
('IXB', 'Bagdogra Airport',                                 'Siliguri',            'India', 'IST'),
('IXC', 'Chandigarh International Airport',                 'Chandigarh',          'India', 'IST'),
('JAI', 'Jaipur International Airport',                     'Jaipur',              'India', 'IST'),
('LKO', 'Chaudhary Charan Singh International Airport',     'Lucknow',             'India', 'IST'),
('NAG', 'Dr. Babasaheb Ambedkar International Airport',     'Nagpur',              'India', 'IST'),
('PAT', 'Jay Prakash Narayan International Airport',        'Patna',               'India', 'IST'),
('SXR', 'Sheikh ul Alam International Airport',             'Srinagar',            'India', 'IST'),
('TRV', 'Trivandrum International Airport',                 'Thiruvananthapuram',  'India', 'IST'),
('VNS', 'Lal Bahadur Shastri International Airport',        'Varanasi',            'India', 'IST'),
('BDQ', 'Vadodara Airport',                                 'Vadodara',            'India', 'IST');

-- =============================================================================
--  TABLE: app_users
-- =============================================================================

CREATE TABLE IF NOT EXISTS `app_users` (
  `user_id`       int(11)     NOT NULL,
  `username`      varchar(50) NOT NULL,
  `password_hash` varchar(64) NOT NULL,
  `role`          varchar(10) NOT NULL CHECK (`role` IN ('PASSENGER','AIRLINE','ADMIN')),
  `linked_id`     int(11)     NOT NULL DEFAULT 0,
  `is_active`     tinyint(1)  DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Seed: admin account (password: admin123)
INSERT IGNORE INTO `app_users` (`user_id`, `username`, `password_hash`, `role`, `linked_id`, `is_active`) VALUES
(1, 'admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'ADMIN', 0, 1);

-- =============================================================================
--  TABLE: bookingmeals
-- =============================================================================

CREATE TABLE IF NOT EXISTS `bookingmeals` (
  `BookingMealID` int(11) NOT NULL,
  `BookingID`     int(11) NOT NULL,
  `PassengerID`   int(11) NOT NULL,
  `MealID`        int(11) NOT NULL,
  `Quantity`      int(11) NOT NULL DEFAULT 1 CHECK (`Quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `bookingmeals` (`BookingMealID`, `BookingID`, `PassengerID`, `MealID`, `Quantity`) VALUES
(1,  1,  1,  1,  1),(2,  2,  2,  3,  1),(3,  3,  3,  9,  1),(4,  4,  4,  2,  2),
(5,  5,  5,  10, 1),(6,  6,  6,  11, 1),(7,  7,  7,  19, 1),(8,  8,  7,  22, 1),
(9,  9,  8,  25, 1),(10, 10, 8,  26, 1),(11, 11, 9,  32, 1),(12, 12, 10, 33, 1),
(13, 13, 11, 1,  1),(14, 14, 12, 4,  1),(15, 15, 13, 17, 1),(16, 16, 14, 37, 1),
(17, 17, 15, 38, 1),(18, 18, 16, 35, 1),(19, 19, 17, 31, 1),(20, 20, 18, 34, 1),
(21, 21, 21, 26, 1),(22, 22, 21, 11, 1),(23, 23, 21, 34, 1),(24, 24, 22, 36, 1),
(25, 25, 22, 40, 1),(26, 26, 19, 5,  1),(27, 27, 20, 13, 1),(28, 28, 23, 6,  2),
(29, 29, 24, 8,  1),(30, 30, 25, 15, 1);

-- =============================================================================
--  TABLE: bookings
-- =============================================================================

CREATE TABLE IF NOT EXISTS `bookings` (
  `BookingID`   int(11)     NOT NULL,
  `FlightID`    int(11)     NOT NULL,
  `PassengerID` int(11)     NOT NULL,
  `BookingDate` datetime    DEFAULT current_timestamp(),
  `Status`      varchar(20) DEFAULT 'Pending' CHECK (`Status` IN ('Pending','Confirmed','Cancelled','Completed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `bookings` (`BookingID`, `FlightID`, `PassengerID`, `BookingDate`, `Status`) VALUES
(1,  1,  1,  '2025-07-01 10:00:00', 'Confirmed'),(2,  2,  2,  '2025-07-01 11:00:00', 'Confirmed'),
(3,  3,  3,  '2025-07-02 09:30:00', 'Confirmed'),(4,  4,  4,  '2025-07-03 14:00:00', 'Pending'),
(5,  5,  5,  '2025-07-03 15:30:00', 'Confirmed'),(6,  6,  6,  '2025-07-04 08:00:00', 'Cancelled'),
(7,  7,  7,  '2025-07-04 12:00:00', 'Confirmed'),(8,  9,  7,  '2025-07-04 12:05:00', 'Confirmed'),
(9,  8,  8,  '2025-07-05 10:45:00', 'Confirmed'),(10, 21, 8,  '2025-07-05 10:50:00', 'Confirmed'),
(11, 10, 9,  '2025-07-05 16:00:00', 'Pending'),  (12, 10, 10, '2025-07-06 09:00:00', 'Confirmed'),
(13, 11, 11, '2025-07-06 11:30:00', 'Confirmed'),(14, 12, 12, '2025-07-07 13:00:00', 'Pending'),
(15, 13, 13, '2025-07-07 14:45:00', 'Confirmed'),(16, 14, 14, '2025-07-08 08:30:00', 'Cancelled'),
(17, 15, 15, '2025-07-08 10:00:00', 'Confirmed'),(18, 16, 16, '2025-07-09 09:00:00', 'Confirmed'),
(19, 17, 17, '2025-07-09 11:00:00', 'Pending'),  (20, 18, 18, '2025-07-10 07:30:00', 'Confirmed'),
(21, 22, 21, '2025-07-11 08:00:00', 'Confirmed'),(22, 23, 21, '2025-07-11 08:05:00', 'Confirmed'),
(23, 24, 21, '2025-07-11 08:10:00', 'Confirmed'),(24, 28, 22, '2025-07-12 09:00:00', 'Confirmed'),
(25, 29, 22, '2025-07-12 09:05:00', 'Confirmed'),(26, 19, 19, '2025-07-10 12:00:00', 'Confirmed'),
(27, 20, 20, '2025-07-10 15:00:00', 'Pending'),  (28, 25, 23, '2025-07-12 10:00:00', 'Confirmed'),
(29, 26, 24, '2025-07-12 11:00:00', 'Confirmed'),(30, 27, 25, '2025-07-12 12:00:00', 'Pending');

-- Trigger on bookings
DROP TRIGGER IF EXISTS `trg_seat_release_on_cancel`;
DELIMITER $$
CREATE TRIGGER `trg_seat_release_on_cancel`
AFTER UPDATE ON `bookings`
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Cancelled' AND OLD.Status != 'Cancelled' THEN
        UPDATE Seats s
        JOIN Tickets t ON t.AircraftID = s.AircraftID
                      AND t.SeatNumber  = s.SeatNumber
        SET s.IsAvailable = TRUE
        WHERE t.BookingID = NEW.BookingID;
    END IF;
END$$
DELIMITER ;

-- =============================================================================
--  TABLE: flights  (FlightCategory uses only 'Direct'|'Connecting' — no Stopover)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `flights` (
  `FlightID`            int(11)        NOT NULL,
  `AircraftID`          int(11)        NOT NULL,
  `DepartureAirportID`  varchar(10)    NOT NULL,
  `ArrivalAirportID`    varchar(10)    NOT NULL,
  `DepartureTime`       datetime       NOT NULL,
  `ArrivalTime`         datetime       NOT NULL,
  `StateTaxAmount`      decimal(10,2)  NOT NULL,
  `BasePrice`           decimal(10,2)  NOT NULL CHECK (`BasePrice` >= 0),
  `FlightType`          varchar(20)    NOT NULL CHECK (`FlightType` IN ('National','International')),
  `FlightCategory`      varchar(20)    NOT NULL DEFAULT 'Direct'
                        CHECK (`FlightCategory` IN ('Direct','Connecting')),
  `ConnectingFlightID`  int(11)        DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `flights` (`FlightID`, `AircraftID`, `DepartureAirportID`, `ArrivalAirportID`, `DepartureTime`, `ArrivalTime`, `StateTaxAmount`, `BasePrice`, `FlightType`, `FlightCategory`, `ConnectingFlightID`) VALUES
( 1,  1, 'DEL', 'BOM', '2026-08-09 06:00:00', '2026-08-09 08:10:00',  250.00,  3500.00, 'National', 'Direct', NULL),
( 2,  2, 'BOM', 'DEL', '2026-08-10 09:00:00', '2026-08-10 11:15:00',  250.00,  3600.00, 'National', 'Direct', NULL),
( 3,  3, 'DEL', 'BLR', '2026-08-11 07:30:00', '2026-08-11 10:00:00',  300.00,  4200.00, 'National', 'Direct', NULL),
( 4,  4, 'BLR', 'HYD', '2026-08-12 08:00:00', '2026-08-12 09:00:00',  150.00,  2500.00, 'National', 'Direct', NULL),
( 5,  5, 'HYD', 'MAA', '2026-08-13 11:00:00', '2026-08-13 12:10:00',  180.00,  2800.00, 'National', 'Direct', NULL),
( 6,  6, 'MAA', 'CCU', '2026-08-14 06:30:00', '2026-08-14 08:45:00',  220.00,  3900.00, 'National', 'Direct', NULL),
( 7,  7, 'DEL', 'DXB', '2026-08-15 22:00:00', '2026-08-16 00:30:00',  500.00, 12000.00, 'International', 'Connecting', 9),
( 8,  8, 'BOM', 'SIN', '2026-08-16 01:00:00', '2026-08-16 10:30:00',  600.00, 18000.00, 'International', 'Connecting', 21),
( 9,  9, 'DXB', 'LHR', '2026-08-16 03:30:00', '2026-08-16 08:00:00', 1200.00, 33000.00, 'International', 'Connecting', NULL),
(10, 10, 'BLR', 'DXB', '2026-08-17 23:45:00', '2026-08-18 02:00:00',  500.00, 14000.00, 'International', 'Direct', NULL),
(11,  1, 'AMD', 'DEL', '2026-08-18 07:00:00', '2026-08-18 08:30:00',  180.00,  3000.00, 'National', 'Direct', NULL),
(12,  2, 'COK', 'BOM', '2026-08-19 10:00:00', '2026-08-19 12:00:00',  220.00,  3800.00, 'National', 'Direct', NULL),
(13,  3, 'GOI', 'DEL', '2026-08-19 14:00:00', '2026-08-19 16:30:00',  260.00,  4500.00, 'National', 'Direct', NULL),
(14,  4, 'PNQ', 'HYD', '2026-08-20 09:00:00', '2026-08-20 10:20:00',  160.00,  2700.00, 'National', 'Direct', NULL),
(15,  5, 'DEL', 'COK', '2026-08-21 13:00:00', '2026-08-21 16:00:00',  200.00,  4100.00, 'National', 'Direct', NULL),
(16,  6, 'BOM', 'CDG', '2026-08-22 03:00:00', '2026-08-22 09:00:00', 1100.00, 48000.00, 'International', 'Direct', NULL),
(17,  7, 'DEL', 'SYD', '2026-08-23 05:00:00', '2026-08-23 23:00:00', 1300.00, 62000.00, 'International', 'Direct', NULL),
(18,  8, 'BLR', 'SIN', '2026-08-24 22:00:00', '2026-08-25 06:00:00',  600.00, 19000.00, 'International', 'Connecting', 21),
(19,  9, 'DEL', 'BOM', '2026-08-25 12:00:00', '2026-08-25 14:00:00',  250.00,  3400.00, 'National', 'Direct', NULL),
(20, 10, 'BOM', 'KUL', '2026-08-26 23:00:00', '2026-08-27 07:30:00',  700.00, 22000.00, 'International', 'Direct', NULL),
(21,  7, 'SIN', 'SYD', '2026-08-25 13:00:00', '2026-08-25 23:00:00',  800.00, 28000.00, 'International', 'Connecting', NULL),
(22,  8, 'DEL', 'KUL', '2026-08-27 01:00:00', '2026-08-27 09:00:00',  700.00, 20000.00, 'International', 'Connecting', 23),
(23,  9, 'KUL', 'BKK', '2026-08-27 11:00:00', '2026-08-27 13:00:00',  300.00,  8000.00, 'International', 'Connecting', 24),
(24, 10, 'BKK', 'SYD', '2026-08-27 15:00:00', '2026-08-27 23:00:00',  900.00, 25000.00, 'International', 'Connecting', NULL),
(25,  1, 'DEL', 'AMD', '2026-08-28 06:30:00', '2026-08-28 08:00:00',  150.00,  2900.00, 'National', 'Direct', NULL),
(26,  2, 'BOM', 'GOI', '2026-08-29 09:00:00', '2026-08-29 10:10:00',  140.00,  2600.00, 'National', 'Direct', NULL),
(27,  3, 'BLR', 'MAA', '2026-08-30 11:00:00', '2026-08-30 12:00:00',  120.00,  2200.00, 'National', 'Direct', NULL),
(28,  4, 'BOM', 'DOH', '2026-08-31 02:00:00', '2026-08-31 04:30:00',  600.00, 15000.00, 'International', 'Connecting', 29),
(29,  5, 'DOH', 'LHR', '2026-08-31 06:30:00', '2026-08-31 11:00:00',  900.00, 30000.00, 'International', 'Connecting', NULL),
(30,  1, 'DEL', 'JAI', '2026-09-01 18:00:00', '2026-09-01 18:45:00',  150.00,  2200.00, 'National', 'Direct', NULL),
(31,  5, 'BOM', 'IDR', '2026-09-02 18:30:00', '2026-09-02 19:45:00',  180.00,  2600.00, 'National', 'Direct', NULL),
(32,  3, 'DEL', 'LKO', '2026-09-03 19:00:00', '2026-09-03 20:00:00',  170.00,  2400.00, 'National', 'Direct', NULL),
(33,  2, 'BOM', 'NAG', '2026-09-04 19:15:00', '2026-09-04 20:25:00',  180.00,  2500.00, 'National', 'Direct', NULL),
(34,  7, 'DEL', 'SXR', '2026-09-05 20:00:00', '2026-09-05 21:20:00',  200.00,  3200.00, 'National', 'Direct', NULL),
(35, 18, 'BLR', 'TRV', '2026-09-06 20:30:00', '2026-09-06 21:30:00',  160.00,  2300.00, 'National', 'Direct', NULL),
(36,  6, 'CCU', 'BBI', '2026-09-07 20:45:00', '2026-09-07 21:35:00',  150.00,  2100.00, 'National', 'Direct', NULL),
(37, 19, 'COK', 'TRV', '2026-09-08 21:00:00', '2026-09-08 21:35:00',  130.00,  1800.00, 'National', 'Direct', NULL),
(38, 10, 'DEL', 'VNS', '2026-09-08 21:30:00', '2026-09-08 22:45:00',  190.00,  2700.00, 'National', 'Direct', NULL),
(39,  4, 'BOM', 'HYD', '2026-09-09 22:00:00', '2026-09-09 23:15:00',  200.00,  3000.00, 'National', 'Direct', NULL),
(40,  1, 'AMD', 'DEL', '2026-09-10 18:00:00', '2026-09-10 19:15:00',  180.00,  2800.00, 'National', 'Connecting', 41),
(41,  2, 'DEL', 'IXC', '2026-09-10 20:30:00', '2026-09-10 21:30:00',  160.00,  2500.00, 'National', 'Connecting', NULL),
(42,  5, 'MAA', 'BOM', '2026-09-11 19:00:00', '2026-09-11 21:00:00',  250.00,  3800.00, 'National', 'Connecting', 43),
(43,  6, 'BOM', 'JAI', '2026-09-11 22:30:00', '2026-09-12 00:00:00',  200.00,  3000.00, 'National', 'Connecting', NULL),
(44,  8, 'CCU', 'DEL', '2026-09-12 20:00:00', '2026-09-12 22:15:00',  280.00,  4200.00, 'National', 'Connecting', 45),
(45,  3, 'DEL', 'PAT', '2026-09-12 23:30:00', '2026-09-13 00:30:00',  170.00,  2600.00, 'National', 'Connecting', NULL),
(46,  1, 'JAI', 'BOM', '2026-09-13 06:00:00', '2026-09-13 07:30:00',  200.00,  3100.00, 'National', 'Direct', NULL),
(47, 18, 'HYD', 'BLR', '2026-09-14 06:30:00', '2026-09-14 07:30:00',  160.00,  2400.00, 'National', 'Direct', NULL),
(48,  7, 'DEL', 'CCU', '2026-09-15 07:00:00', '2026-09-15 09:10:00',  270.00,  4000.00, 'National', 'Direct', NULL),
(49,  4, 'BOM', 'BLR', '2026-09-16 07:30:00', '2026-09-16 08:50:00',  210.00,  3300.00, 'National', 'Direct', NULL),
(50,  5, 'HYD', 'DEL', '2026-09-17 08:00:00', '2026-09-17 10:15:00',  280.00,  4100.00, 'National', 'Direct', NULL),
(51,  2, 'LKO', 'BOM', '2026-09-18 09:00:00', '2026-09-18 11:00:00',  250.00,  3700.00, 'National', 'Direct', NULL),
(52, 19, 'TRV', 'BOM', '2026-09-19 09:30:00', '2026-09-19 11:30:00',  260.00,  3900.00, 'National', 'Direct', NULL),
(53, 10, 'GAU', 'DEL', '2026-09-20 10:00:00', '2026-09-20 12:30:00',  300.00,  4500.00, 'National', 'Direct', NULL),
(54,  6, 'DEL', 'BBI', '2026-09-21 11:00:00', '2026-09-21 13:15:00',  270.00,  4000.00, 'National', 'Direct', NULL),
(55,  7, 'BOM', 'MAA', '2026-09-22 14:00:00', '2026-09-22 15:45:00',  230.00,  3500.00, 'National', 'Direct', NULL),
(56,  3, 'DEL', 'GOI', '2026-09-23 15:30:00', '2026-09-23 17:30:00',  250.00,  3800.00, 'National', 'Direct', NULL),
(57, 18, 'NAG', 'DEL', '2026-09-24 16:00:00', '2026-09-24 17:45:00',  230.00,  3400.00, 'National', 'Direct', NULL),
(58,  1, 'IXB', 'CCU', '2026-09-25 17:00:00', '2026-09-25 17:45:00',  140.00,  2000.00, 'National', 'Direct', NULL),
(59,  4, 'DEL', 'BOM', '2026-09-26 07:00:00', '2026-09-26 09:10:00',  250.00,  3500.00, 'National', 'Connecting', 60),
(60,  3, 'BOM', 'TRV', '2026-09-26 11:00:00', '2026-09-26 13:00:00',  260.00,  4000.00, 'National', 'Connecting', NULL),
(61,  2, 'VNS', 'DEL', '2026-09-27 08:30:00', '2026-09-27 09:50:00',  190.00,  2800.00, 'National', 'Connecting', 62),
(62,  1, 'DEL', 'JAI', '2026-09-27 11:00:00', '2026-09-27 11:45:00',  150.00,  2200.00, 'National', 'Connecting', NULL),
(63,  6, 'BBI', 'CCU', '2026-09-28 10:00:00', '2026-09-28 10:50:00',  150.00,  2100.00, 'National', 'Connecting', 64),
(64,  5, 'CCU', 'GAU', '2026-09-28 12:30:00', '2026-09-28 13:30:00',  160.00,  2300.00, 'National', 'Connecting', NULL),
(65,  7, 'IXC', 'DEL', '2026-09-28 13:00:00', '2026-09-28 14:00:00',  160.00,  2500.00, 'National', 'Connecting', 66),
(66,  7, 'DEL', 'LKO', '2026-09-28 15:30:00', '2026-09-28 16:30:00',  170.00,  2400.00, 'National', 'Connecting', NULL),
(67,  8, 'BOM', 'DEL', '2026-09-29 06:00:00', '2026-09-29 08:10:00',  250.00,  3600.00, 'National', 'Direct', NULL),
(68, 10, 'MAA', 'HYD', '2026-09-30 07:00:00', '2026-09-30 08:00:00',  160.00,  2300.00, 'National', 'Direct', NULL),
(69, 18, 'DEL', 'IDR', '2026-10-01 08:00:00', '2026-10-01 09:30:00',  190.00,  2800.00, 'National', 'Direct', NULL),
(70,  1, 'BDQ', 'DEL', '2026-10-02 18:45:00', '2026-10-02 20:05:00',  190.00,  2800.00, 'National', 'Direct', NULL),
(71,  5, 'BOM', 'BDQ', '2026-10-03 20:00:00', '2026-10-03 21:00:00',  160.00,  2200.00, 'National', 'Direct', NULL),
(72, 10, 'BDQ', 'AMD', '2026-10-04 06:30:00', '2026-10-04 07:15:00',  130.00,  1600.00, 'National', 'Direct', NULL),
(73, 19, 'BDQ', 'BOM', '2026-10-05 09:00:00', '2026-10-05 10:00:00',  160.00,  2300.00, 'National', 'Direct', NULL),
(74, 18, 'DEL', 'BDQ', '2026-10-06 14:30:00', '2026-10-06 15:50:00',  190.00,  2800.00, 'National', 'Direct', NULL),
(75,  7, 'BDQ', 'BLR', '2026-10-07 07:30:00', '2026-10-07 09:00:00',  200.00,  3000.00, 'National', 'Direct', NULL),
(76,  2, 'BDQ', 'BOM', '2026-10-08 11:00:00', '2026-10-08 12:00:00',  160.00,  2200.00, 'National', 'Connecting', 77),
(77,  6, 'BOM', 'HYD', '2026-10-08 13:30:00', '2026-10-08 14:45:00',  180.00,  2700.00, 'National', 'Connecting', NULL);

-- =============================================================================
--  DATE FIX — Flights 1-29 already inserted by skybook_updated.sql with old
--  dates (Aug 2026). These UPDATEs bring them into the Aug 9 – Oct 8 window.
-- =============================================================================
UPDATE `flights` SET `DepartureTime` = '2026-08-09 06:00:00', `ArrivalTime` = '2026-08-09 08:10:00' WHERE `FlightID` = 1;
UPDATE `flights` SET `DepartureTime` = '2026-08-10 09:00:00', `ArrivalTime` = '2026-08-10 11:15:00' WHERE `FlightID` = 2;
UPDATE `flights` SET `DepartureTime` = '2026-08-11 07:30:00', `ArrivalTime` = '2026-08-11 10:00:00' WHERE `FlightID` = 3;
UPDATE `flights` SET `DepartureTime` = '2026-08-12 08:00:00', `ArrivalTime` = '2026-08-12 09:00:00' WHERE `FlightID` = 4;
UPDATE `flights` SET `DepartureTime` = '2026-08-13 11:00:00', `ArrivalTime` = '2026-08-13 12:10:00' WHERE `FlightID` = 5;
UPDATE `flights` SET `DepartureTime` = '2026-08-14 06:30:00', `ArrivalTime` = '2026-08-14 08:45:00' WHERE `FlightID` = 6;
UPDATE `flights` SET `DepartureTime` = '2026-08-15 22:00:00', `ArrivalTime` = '2026-08-16 00:30:00' WHERE `FlightID` = 7;
UPDATE `flights` SET `DepartureTime` = '2026-08-16 01:00:00', `ArrivalTime` = '2026-08-16 10:30:00' WHERE `FlightID` = 8;
UPDATE `flights` SET `DepartureTime` = '2026-08-16 03:30:00', `ArrivalTime` = '2026-08-16 08:00:00' WHERE `FlightID` = 9;
UPDATE `flights` SET `DepartureTime` = '2026-08-17 23:45:00', `ArrivalTime` = '2026-08-18 02:00:00' WHERE `FlightID` = 10;
UPDATE `flights` SET `DepartureTime` = '2026-08-18 07:00:00', `ArrivalTime` = '2026-08-18 08:30:00' WHERE `FlightID` = 11;
UPDATE `flights` SET `DepartureTime` = '2026-08-19 10:00:00', `ArrivalTime` = '2026-08-19 12:00:00' WHERE `FlightID` = 12;
UPDATE `flights` SET `DepartureTime` = '2026-08-19 14:00:00', `ArrivalTime` = '2026-08-19 16:30:00' WHERE `FlightID` = 13;
UPDATE `flights` SET `DepartureTime` = '2026-08-20 09:00:00', `ArrivalTime` = '2026-08-20 10:20:00' WHERE `FlightID` = 14;
UPDATE `flights` SET `DepartureTime` = '2026-08-21 13:00:00', `ArrivalTime` = '2026-08-21 16:00:00' WHERE `FlightID` = 15;
UPDATE `flights` SET `DepartureTime` = '2026-08-22 03:00:00', `ArrivalTime` = '2026-08-22 09:00:00' WHERE `FlightID` = 16;
UPDATE `flights` SET `DepartureTime` = '2026-08-23 05:00:00', `ArrivalTime` = '2026-08-23 23:00:00' WHERE `FlightID` = 17;
UPDATE `flights` SET `DepartureTime` = '2026-08-24 22:00:00', `ArrivalTime` = '2026-08-25 06:00:00' WHERE `FlightID` = 18;
UPDATE `flights` SET `DepartureTime` = '2026-08-25 12:00:00', `ArrivalTime` = '2026-08-25 14:00:00' WHERE `FlightID` = 19;
UPDATE `flights` SET `DepartureTime` = '2026-08-26 23:00:00', `ArrivalTime` = '2026-08-27 07:30:00' WHERE `FlightID` = 20;
UPDATE `flights` SET `DepartureTime` = '2026-08-25 13:00:00', `ArrivalTime` = '2026-08-25 23:00:00' WHERE `FlightID` = 21;
UPDATE `flights` SET `DepartureTime` = '2026-08-27 01:00:00', `ArrivalTime` = '2026-08-27 09:00:00' WHERE `FlightID` = 22;
UPDATE `flights` SET `DepartureTime` = '2026-08-27 11:00:00', `ArrivalTime` = '2026-08-27 13:00:00' WHERE `FlightID` = 23;
UPDATE `flights` SET `DepartureTime` = '2026-08-27 15:00:00', `ArrivalTime` = '2026-08-27 23:00:00' WHERE `FlightID` = 24;
UPDATE `flights` SET `DepartureTime` = '2026-08-28 06:30:00', `ArrivalTime` = '2026-08-28 08:00:00' WHERE `FlightID` = 25;
UPDATE `flights` SET `DepartureTime` = '2026-08-29 09:00:00', `ArrivalTime` = '2026-08-29 10:10:00' WHERE `FlightID` = 26;
UPDATE `flights` SET `DepartureTime` = '2026-08-30 11:00:00', `ArrivalTime` = '2026-08-30 12:00:00' WHERE `FlightID` = 27;
UPDATE `flights` SET `DepartureTime` = '2026-08-31 02:00:00', `ArrivalTime` = '2026-08-31 04:30:00' WHERE `FlightID` = 28;
UPDATE `flights` SET `DepartureTime` = '2026-08-31 06:30:00', `ArrivalTime` = '2026-08-31 11:00:00' WHERE `FlightID` = 29;

-- =============================================================================
--  TABLE: meals
-- =============================================================================

CREATE TABLE IF NOT EXISTS `meals` (
  `MealID`       int(11)      NOT NULL,
  `AirlineID`    int(11)      NOT NULL,
  `MealName`     varchar(100) NOT NULL,
  `MealCategory` varchar(10)  NOT NULL CHECK (`MealCategory` IN ('Snack','Meal')),
  `DietType`     varchar(10)  NOT NULL CHECK (`DietType`     IN ('Veg','Non-Veg')),
  `MealType`     varchar(20)  NOT NULL CHECK (`MealType`     IN ('Vegetarian','Non-Vegetarian','Vegan','Jain','Special')),
  `Price`        decimal(10,2) NOT NULL DEFAULT 0.00 CHECK (`Price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `meals` (`MealID`, `AirlineID`, `MealName`, `MealCategory`, `DietType`, `MealType`, `Price`) VALUES
(1,  1, 'Veg Sandwich',          'Snack', 'Veg',     'Vegetarian',     80.00),
(2,  1, 'Samosa Combo',          'Snack', 'Veg',     'Vegetarian',     70.00),
(3,  1, 'Chicken Roll',          'Snack', 'Non-Veg', 'Non-Vegetarian', 100.00),
(4,  1, 'Egg Muffin',            'Snack', 'Non-Veg', 'Non-Vegetarian', 90.00),
(5,  1, 'Veg Biryani',           'Meal',  'Veg',     'Vegetarian',     150.00),
(6,  1, 'Chicken Biryani',       'Meal',  'Non-Veg', 'Non-Vegetarian', 180.00),
(7,  1, 'Dal Rice Combo',        'Meal',  'Veg',     'Jain',           140.00),
(8,  1, 'Fish Curry Rice',       'Meal',  'Non-Veg', 'Non-Vegetarian', 190.00),
(9,  3, 'Masala Peanuts',        'Snack', 'Veg',     'Vegetarian',     60.00),
(10, 3, 'Veg Puff',              'Snack', 'Veg',     'Vegetarian',     75.00),
(11, 3, 'Chicken Sandwich',      'Snack', 'Non-Veg', 'Non-Vegetarian', 95.00),
(12, 3, 'Boiled Egg Snack',      'Snack', 'Non-Veg', 'Non-Vegetarian', 80.00),
(13, 3, 'Paneer Rice Bowl',      'Meal',  'Veg',     'Vegetarian',     160.00),
(14, 3, 'Mutton Curry Meal',     'Meal',  'Non-Veg', 'Non-Vegetarian', 200.00),
(15, 3, 'Jain Thali',            'Meal',  'Veg',     'Jain',           155.00),
(16, 3, 'Prawn Rice',            'Meal',  'Non-Veg', 'Non-Vegetarian', 210.00),
(17, 4, 'Fruit Yogurt Cup',      'Snack', 'Veg',     'Vegan',          120.00),
(18, 4, 'Cheese Crackers',       'Snack', 'Veg',     'Vegetarian',     110.00),
(19, 4, 'Grilled Chicken Wrap',  'Snack', 'Non-Veg', 'Non-Vegetarian', 160.00),
(20, 4, 'Tuna Croissant',        'Snack', 'Non-Veg', 'Non-Vegetarian', 155.00),
(21, 4, 'Paneer Butter Masala',  'Meal',  'Veg',     'Vegetarian',     280.00),
(22, 4, 'Chicken Tikka Masala',  'Meal',  'Non-Veg', 'Non-Vegetarian', 320.00),
(23, 4, 'Diabetic Veg Meal',     'Meal',  'Veg',     'Special',        290.00),
(24, 4, 'Gluten Free Chicken',   'Meal',  'Non-Veg', 'Special',        310.00),
(25, 2, 'Dal Makhani Rice',      'Meal',  'Veg',     'Vegetarian',     380.00),
(26, 2, 'Lamb Rogan Josh',       'Meal',  'Non-Veg', 'Non-Vegetarian', 430.00),
(27, 2, 'Kids Veg Pasta',        'Meal',  'Veg',     'Vegetarian',     300.00),
(28, 2, 'Butter Chicken Meal',   'Meal',  'Non-Veg', 'Non-Vegetarian', 420.00),
(29, 7, 'Arabian Mezze Platter', 'Snack', 'Veg',     'Vegetarian',     350.00),
(30, 7, 'Smoked Salmon Canapé',  'Snack', 'Non-Veg', 'Non-Vegetarian', 420.00),
(31, 7, 'Vegetable Biryani',     'Meal',  'Veg',     'Vegetarian',     650.00),
(32, 7, 'Grilled Lamb Chops',    'Meal',  'Non-Veg', 'Non-Vegetarian', 850.00),
(33, 7, 'Vegan Buddha Bowl',     'Meal',  'Veg',     'Vegan',          600.00),
(34, 7, 'Seafood Linguine',      'Meal',  'Non-Veg', 'Non-Vegetarian', 800.00),
(35, 8, 'Mezze Selection',       'Snack', 'Veg',     'Vegetarian',     380.00),
(36, 8, 'Shrimp Cocktail',       'Snack', 'Non-Veg', 'Non-Vegetarian', 450.00),
(37, 8, 'Paneer Tikka Masala',   'Meal',  'Veg',     'Vegetarian',     700.00),
(38, 8, 'Beef Tenderloin',       'Meal',  'Non-Veg', 'Non-Vegetarian', 950.00),
(39, 8, 'Diabetic Friendly Meal','Meal',  'Veg',     'Special',        680.00),
(40, 8, 'Arabic Lamb Kabsa',     'Meal',  'Non-Veg', 'Non-Vegetarian', 900.00);

-- =============================================================================
--  TABLE: passengers  (+ age-check triggers)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `passengers` (
  `PassengerID`    int(11)     NOT NULL,
  `FirstName`      varchar(50) NOT NULL,
  `LastName`       varchar(50) NOT NULL,
  `Email`          varchar(100) NOT NULL,
  `ContactNo`      varchar(15) NOT NULL,
  `DateOfBirth`    date        NOT NULL,
  `PassportNumber` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Age triggers removed: 18+ enforced at account registration only.


INSERT IGNORE INTO `passengers` (`PassengerID`, `FirstName`, `LastName`, `Email`, `ContactNo`, `DateOfBirth`, `PassportNumber`) VALUES
(1,  'Aarav',      'Sharma',   'aaravsharma@gmail.com',   '+919876543210', '1995-03-15', 'P1234567'),
(2,  'Priya',      'Patel',    'priyapatel@gmail.com',    '+919823456781', '1992-07-22', 'P2345678'),
(3,  'Rohan',      'Mehta',    'rohanmehta@yahoo.com',    '+919712345672', '1988-11-05', 'P3456789'),
(4,  'Sneha',      'Iyer',     'snehaiyer@gmail.com',     '+919601234563', '1997-01-30', 'P4567890'),
(5,  'Vikram',     'Singh',    'vikramsingh@gmail.com',   '+919590123454', '1985-09-14', 'P5678901'),
(6,  'Kavya',      'Nair',     'kavyanair@gmail.com',     '+919489012345', '2000-05-18', NULL),
(7,  'Arjun',      'Reddy',    'arjunreddy@gmail.com',    '+919378901236', '1993-12-25', 'P6789012'),
(8,  'Meera',      'Joshi',    'meerajoshi@gmail.com',    '+919267890127', '1991-04-08', 'P7890123'),
(9,  'Kiran',      'Gupta',    'kirangupta@gmail.com',    '+919156789018', '1996-08-20', NULL),
(10, 'Ananya',     'Desai',    'ananyadesai@gmail.com',   '+919045678909', '1999-02-14', 'P8901234'),
(11, 'Rahul',      'Kumar',    'rahulkumar@gmail.com',    '+919934567890', '1987-06-10', 'P9012345'),
(12, 'Divya',      'Bose',     'divyabose@gmail.com',     '+919823456700', '1994-10-03', 'P0123456'),
(13, 'Nikhil',     'Verma',    'nikhilverma@gmail.com',   '+919712345600', '1990-03-27', 'PA123456'),
(14, 'Pooja',      'Chopra',   'poojachopra@yahoo.com',   '+919601234500', '1998-07-11', NULL),
(15, 'Siddharth',  'Rao',      'siddharthrao@gmail.com',  '+919590123400', '1986-12-01', 'PB234567'),
(16, 'Aishwarya',  'Menon',    'aishwaryamenon@gmail.com','+919479012300', '2001-09-09', 'PC345678'),
(17, 'Rajesh',     'Pillai',   'rajeshpillai@gmail.com',  '+919368901200', '1983-05-25', 'PD456789'),
(18, 'Sunita',     'Tiwari',   'sunitatiwari@gmail.com',  '+919257890100', '1995-11-17', 'PE567890'),
(19, 'Amit',       'Bhatt',    'amitbhatt@gmail.com',     '+919146789000', '1989-04-30', 'PF678901'),
(20, 'Neha',       'Shah',     'nehashah@gmail.com',      '+919035678900', '2002-01-21', NULL),
(21, 'Sameer',     'Khan',     'sameerkhan@gmail.com',    '+919924567890', '1991-06-15', 'PG789012'),
(22, 'Riya',       'Jain',     'riyajain@gmail.com',      '+919813456780', '1998-03-22', NULL),
(23, 'Deepak',     'Mishra',   'deepakmishra@yahoo.com',  '+919702345670', '1984-08-30', 'PH890123'),
(24, 'Pratha',     'Agarwal',  'prathaagarwal@gmail.com', '+919591234560', '2003-12-05', NULL),
(25, 'Harish',     'Nayak',    'harishnayak@gmail.com',   '+919480123450', '1979-07-19', 'PI901234');

-- =============================================================================
--  TABLE: payments
-- =============================================================================

CREATE TABLE IF NOT EXISTS `payments` (
  `PaymentID`       int(11)      NOT NULL,
  `TicketID`        int(11)      NOT NULL,
  `Amount`          decimal(10,2) NOT NULL CHECK (`Amount` > 0),
  `PaymentMethod`   varchar(20)  NOT NULL,
  `TransactionDate` datetime     DEFAULT current_timestamp(),
  `PaymentStatus`   varchar(20)  DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `payments` (`PaymentID`, `TicketID`, `Amount`, `PaymentMethod`, `TransactionDate`, `PaymentStatus`) VALUES
(1,  1,  3575.00,  'UPI',         '2025-07-01 10:05:00', 'Success'),
(2,  2,  4250.00,  'Credit Card', '2025-07-01 11:08:00', 'Success'),
(3,  3,  4200.00,  'Debit Card',  '2025-07-02 09:35:00', 'Success'),
(4,  4,  4000.00,  'Net Banking', '2025-07-03 14:10:00', 'Pending'),
(5,  5,  2875.00,  'UPI',         '2025-07-03 15:35:00', 'Success'),
(6,  6,  3975.00,  'Credit Card', '2025-07-04 08:05:00', 'Refunded'),
(7,  7,  13750.00, 'Credit Card', '2025-07-04 12:10:00', 'Success'),
(8,  8,  33200.00, 'Credit Card', '2025-07-04 12:12:00', 'Success'),
(9,  9,  18200.00, 'Net Banking', '2025-07-05 10:50:00', 'Success'),
(10, 10, 28500.00, 'Net Banking', '2025-07-05 10:52:00', 'Success'),
(11, 11, 16800.00, 'Credit Card', '2025-07-05 16:10:00', 'Pending'),
(12, 12, 14100.00, 'Debit Card',  '2025-07-06 09:05:00', 'Success'),
(13, 13, 3150.00,  'UPI',         '2025-07-06 11:35:00', 'Success'),
(14, 14, 4500.00,  'UPI',         '2025-07-07 13:05:00', 'Pending'),
(15, 15, 4400.00,  'Credit Card', '2025-07-07 14:50:00', 'Success'),
(16, 16, 2500.00,  'Net Banking', '2025-07-08 08:35:00', 'Refunded'),
(17, 17, 54300.00, 'Credit Card', '2025-07-08 10:10:00', 'Success'),
(18, 18, 48300.00, 'Debit Card',  '2025-07-09 09:10:00', 'Success'),
(19, 19, 65200.00, 'Credit Card', '2025-07-09 11:10:00', 'Pending'),
(20, 20, 19500.00, 'UPI',         '2025-07-10 07:35:00', 'Success'),
(21, 21, 20200.00, 'Credit Card', '2025-07-11 08:05:00', 'Success'),
(22, 22, 8200.00,  'Credit Card', '2025-07-11 08:07:00', 'Success'),
(23, 23, 26650.00, 'Credit Card', '2025-07-11 08:09:00', 'Success'),
(24, 24, 15200.00, 'Net Banking', '2025-07-12 09:05:00', 'Success'),
(25, 25, 31150.00, 'Net Banking', '2025-07-12 09:07:00', 'Success'),
(26, 26, 3475.00,  'UPI',         '2025-07-12 10:05:00', 'Success'),
(27, 27, 23350.00, 'Debit Card',  '2025-07-12 11:05:00', 'Pending'),
(28, 28, 2900.00,  'UPI',         '2025-07-12 12:05:00', 'Success'),
(29, 29, 2675.00,  'Debit Card',  '2025-07-12 13:05:00', 'Success'),
(30, 30, 2400.00,  'Net Banking', '2025-07-12 14:05:00', 'Pending');

-- =============================================================================
--  TABLE: seats  (abbreviated — full data from skybook_updated.sql is huge)
--  NOTE: This file contains the complete seats data from the original dump.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `seats` (
  `AircraftID`    int(11)      NOT NULL,
  `SeatNumber`    varchar(10)  NOT NULL,
  `SeatClass`     varchar(20)  NOT NULL CHECK (`SeatClass`    IN ('Economy','Business','First')),
  `SeatPosition`  varchar(10)  NOT NULL CHECK (`SeatPosition` IN ('Aisle','Window','Middle')),
  `SeatSurcharge` decimal(8,2) NOT NULL DEFAULT 0.00,
  `IsAvailable`   tinyint(1)   DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- (Full seats INSERT omitted here for brevity — included via skybook_updated.sql)
-- If importing this standalone file, run skybook_updated.sql first for seats data,
-- or use the combined approach described in the README section at the bottom.

-- =============================================================================
--  TABLE: tickets
-- =============================================================================

CREATE TABLE IF NOT EXISTS `tickets` (
  `TicketID`         int(11)      NOT NULL,
  `BookingID`        int(11)      NOT NULL,
  `AircraftID`       int(11)      NOT NULL,
  `SeatNumber`       varchar(10)  NOT NULL,
  `PricePaid`        decimal(10,2) NOT NULL,
  `PNR`              varchar(10)  NOT NULL,
  `ExtraLuggageKG`   decimal(5,2) DEFAULT 0.00 CHECK (`ExtraLuggageKG`   >= 0),
  `ExtraLuggageCost` decimal(10,2) DEFAULT 0.00 CHECK (`ExtraLuggageCost` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `tickets` (`TicketID`, `BookingID`, `AircraftID`, `SeatNumber`, `PricePaid`, `PNR`, `ExtraLuggageKG`, `ExtraLuggageCost`) VALUES
(1,  1,  1,  '3A',  3575.00,  'PNR100001', 0.00,  0.00),
(2,  2,  2,  '3W',  3750.00,  'PNR100002', 5.00,  500.00),
(3,  3,  3,  '7M',  4200.00,  'PNR100003', 0.00,  0.00),
(4,  4,  4,  '1W',  3000.00,  'PNR100004', 10.00, 1000.00),
(5,  5,  5,  '2A',  2875.00,  'PNR100005', 0.00,  0.00),
(6,  6,  6,  '1A',  3975.00,  'PNR100006', 0.00,  0.00),
(7,  7,  7,  '2W',  12250.00, 'PNR100007', 15.00, 1500.00),
(8,  8,  7,  '3A',  33200.00, 'PNR100008', 0.00,  0.00),
(9,  9,  8,  '1A',  18200.00, 'PNR100009', 0.00,  0.00),
(10, 10, 8,  '3W',  28500.00, 'PNR100010', 0.00,  0.00),
(11, 11, 9,  '1W',  14500.00, 'PNR100011', 23.00, 2300.00),
(12, 12, 10, '2A',  14100.00, 'PNR100012', 0.00,  0.00),
(13, 13, 1,  '4W',  3150.00,  'PNR100013', 0.00,  0.00),
(14, 14, 2,  '4M',  3800.00,  'PNR100014', 7.00,  700.00),
(15, 15, 3,  '5A',  4400.00,  'PNR100015', 0.00,  0.00),
(16, 16, 4,  '11M', 2500.00,  'PNR100016', 0.00,  0.00),
(17, 17, 5,  '1W',  52300.00, 'PNR100017', 20.00, 2000.00),
(18, 18, 6,  '2W',  48300.00, 'PNR100018', 0.00,  0.00),
(19, 19, 7,  '1A',  62200.00, 'PNR100019', 30.00, 3000.00),
(20, 20, 8,  '3W',  19500.00, 'PNR100020', 0.00,  0.00),
(21, 21, 8,  '4A',  20200.00, 'PNR100021', 0.00,  0.00),
(22, 22, 9,  '4A',  8200.00,  'PNR100022', 0.00,  0.00),
(23, 23, 10, '4W',  25150.00, 'PNR100023', 15.00, 1500.00),
(24, 24, 4,  '5A',  15200.00, 'PNR100024', 0.00,  0.00),
(25, 25, 5,  '5W',  30150.00, 'PNR100025', 10.00, 1000.00),
(26, 26, 9,  '5A',  3475.00,  'PNR100026', 0.00,  0.00),
(27, 27, 10, '5W',  22150.00, 'PNR100027', 12.00, 1200.00),
(28, 28, 1,  '5M',  2900.00,  'PNR100028', 0.00,  0.00),
(29, 29, 2,  '5A',  2675.00,  'PNR100029', 0.00,  0.00),
(30, 30, 3,  '6A',  2400.00,  'PNR100030', 0.00,  0.00);

-- =============================================================================
--  VIEWS  (phpMyAdmin created stand-in tables for these — we drop them first)
-- =============================================================================

-- Drop stub tables left by phpMyAdmin (if skybook_updated.sql's DEFINER-based
-- CREATE VIEW failed due to user mismatch, these remain as plain tables).
-- Also drop any stale view definition before recreating.
DROP TABLE IF EXISTS `v_flight_availability`;
DROP VIEW  IF EXISTS `v_flight_availability`;
DROP TABLE IF EXISTS `v_booking_detail`;
DROP VIEW  IF EXISTS `v_booking_detail`;

CREATE VIEW `v_flight_availability` AS
SELECT
    f.FlightID,
    al.AirlineName,
    dep.City                                              AS FromCity,
    arr.City                                              AS ToCity,
    f.DepartureAirportID,
    f.ArrivalAirportID,
    f.DepartureTime,
    f.ArrivalTime,
    TIMESTAMPDIFF(MINUTE, f.DepartureTime, f.ArrivalTime) AS DurationMins,
    f.BasePrice,
    f.StateTaxAmount,
    (f.BasePrice + f.StateTaxAmount)                      AS TotalPrice,
    f.FlightType,
    f.FlightCategory,
    ac.AircraftModel,
    (SELECT COUNT(*) FROM seats s
     WHERE s.AircraftID = f.AircraftID AND s.IsAvailable = TRUE) AS AvailableSeats
FROM flights   f
JOIN aircraft  ac  ON f.AircraftID         = ac.AircraftID
JOIN airlines  al  ON ac.AirlineID         = al.AirlineID
JOIN airports  dep ON f.DepartureAirportID = dep.AirportCode
JOIN airports  arr ON f.ArrivalAirportID   = arr.AirportCode
WHERE al.IsActive = TRUE AND ac.Status = 'Active';

DROP TABLE IF EXISTS `v_booking_detail`;
DROP VIEW  IF EXISTS `v_booking_detail`;

CREATE VIEW `v_booking_detail` AS
SELECT
    b.BookingID,
    b.Status                                              AS BookingStatus,
    b.BookingDate,
    CONCAT(p.FirstName, ' ', p.LastName)                  AS PassengerName,
    p.Email,
    p.ContactNo,
    TIMESTAMPDIFF(YEAR, p.DateOfBirth, CURDATE())         AS Age,
    al.AirlineName,
    f.DepartureAirportID,
    f.ArrivalAirportID,
    f.DepartureTime,
    f.ArrivalTime,
    t.SeatNumber,
    s.SeatClass,
    s.SeatPosition,
    t.PricePaid,
    t.ExtraLuggageKG,
    t.ExtraLuggageCost,
    COALESCE((SELECT SUM(m.Price * bm.Quantity)
              FROM bookingmeals bm
              JOIN meals m ON bm.MealID = m.MealID
              WHERE bm.BookingID = b.BookingID), 0)        AS MealTotal,
    t.PNR,
    pay.PaymentMethod,
    pay.PaymentStatus,
    pay.Amount                                             AS AmountPaid
FROM bookings   b
JOIN passengers p   ON b.PassengerID       = p.PassengerID
JOIN flights    f   ON b.FlightID          = f.FlightID
JOIN aircraft   ac  ON f.AircraftID        = ac.AircraftID
JOIN airlines   al  ON ac.AirlineID        = al.AirlineID
JOIN tickets    t   ON t.BookingID         = b.BookingID
JOIN seats      s   ON t.AircraftID        = s.AircraftID
                   AND t.SeatNumber        = s.SeatNumber
LEFT JOIN payments pay ON pay.TicketID     = t.TicketID;

-- =============================================================================
--  INDEXES
-- =============================================================================

-- (idx_flights_route_date index already created by skybook_updated.sql)

-- =============================================================================
--  FIX: primary keys, AUTO_INCREMENT and unique keys
--  The tables above were created without them, so INSERTs that rely on
--  AUTO_INCREMENT (e.g. registering a passenger) fail with
--  "Field 'PassengerID' doesn't have a default value".
--  (Added to this import so a fresh import works.) Run ONCE. If a line fails with 'Multiple primary key defined', that table
--  already has its key - skip that line. Fails if a table has duplicate IDs
--  (e.g. the import was run twice) - drop the database and re-import instead.
-- =============================================================================

ALTER TABLE `airlines`     ADD PRIMARY KEY (`AirlineID`),     MODIFY `AirlineID`     int(11) NOT NULL AUTO_INCREMENT, ADD UNIQUE KEY `uq_airline_iata` (`IATACode`);
ALTER TABLE `airports`     ADD PRIMARY KEY (`AirportCode`);
ALTER TABLE `aircraft`     ADD PRIMARY KEY (`AircraftID`),    MODIFY `AircraftID`    int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `app_users`    ADD PRIMARY KEY (`user_id`),       MODIFY `user_id`       int(11) NOT NULL AUTO_INCREMENT, ADD UNIQUE KEY `uq_username` (`username`);
ALTER TABLE `passengers`   ADD PRIMARY KEY (`PassengerID`),   MODIFY `PassengerID`   int(11) NOT NULL AUTO_INCREMENT, ADD UNIQUE KEY `uq_passenger_email` (`Email`);
ALTER TABLE `bookings`     ADD PRIMARY KEY (`BookingID`),     MODIFY `BookingID`     int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `bookingmeals` ADD PRIMARY KEY (`BookingMealID`), MODIFY `BookingMealID` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `meals`        ADD PRIMARY KEY (`MealID`),        MODIFY `MealID`        int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `payments`     ADD PRIMARY KEY (`PaymentID`),     MODIFY `PaymentID`     int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `tickets`      ADD PRIMARY KEY (`TicketID`),      MODIFY `TicketID`      int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `seats`        ADD PRIMARY KEY (`AircraftID`, `SeatNumber`);
ALTER TABLE `flights`      ADD PRIMARY KEY (`FlightID`);

-- =============================================================================
--  AUTO_INCREMENT — only flights needs updating (new flights added up to ID 77)
-- =============================================================================

ALTER TABLE `flights` MODIFY `FlightID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=78;

-- =============================================================================
--  Airline login accounts
--  Password for all: airline@123  (SHA-256 hardcoded — no UPDATE needed)
--  linked_id is correct from the start — no UPDATE needed
-- =============================================================================

-- SHA-256('airline@123') = 84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e

INSERT IGNORE INTO `app_users` (`username`, `password_hash`, `role`, `linked_id`, `is_active`) VALUES
  ('indigo',    '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 1,  TRUE),  -- IndiGo
  ('airindia',  '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 2,  TRUE),  -- Air India
  ('spicejet',  '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 3,  TRUE),  -- SpiceJet
  ('vistara',   '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 4,  TRUE),  -- Vistara
  ('goindigo',  '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 5,  TRUE),  -- Go First
  ('airasia',   '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 6,  TRUE),  -- AirAsia India
  ('emirates',  '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 7,  TRUE),  -- Emirates
  ('qatar',     '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 8,  TRUE),  -- Qatar Airways
  ('singapore', '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 9,  TRUE),  -- Singapore Airlines
  ('akasa',     '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e', 'AIRLINE', 17, TRUE);  -- Akasa Air

-- =============================================================================
--  STEP 5 — Remove 'Stopover' FlightCategory, enforce 'Direct'|'Connecting' only
--  (No Stopover rows exist in the seed data above, but this guard is safe to run.)
-- =============================================================================

-- Convert any leftover Stopover rows
UPDATE `flights`
SET `FlightCategory` = 'Connecting'
WHERE `FlightCategory` = 'Stopover';

-- Drop old check constraint if it still references 'Stopover'
-- (adjust constraint name if SHOW CREATE TABLE flights shows a different one)
ALTER TABLE `flights`
    DROP CONSTRAINT IF EXISTS `flights_chk_2`;

-- Re-add the clean constraint
ALTER TABLE `flights`
    ADD CONSTRAINT `chk_flight_category`
    CHECK (`FlightCategory` IN ('Direct','Connecting'));

-- Verify — should return 0 rows
SELECT FlightID, FlightCategory FROM `flights` WHERE `FlightCategory` = 'Stopover';

-- =============================================================================
--  STEP 6 — Views already dropped and recreated above
-- =============================================================================

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- =============================================================================
--  USAGE NOTE
--  This file covers everything EXCEPT the large seats data block (~1700 rows).
--  Import in this order:
--    1. mysql -u root -p skybook < skybook_updated.sql        ← base schema + seats
--    2. mysql -u root -p skybook < skybook_complete_import.sql ← everything else
-- =============================================================================

-- Final verify — shows all 40 new flights
SELECT
  FlightID,
  DepartureAirportID AS `From`,
  ArrivalAirportID   AS `To`,
  DATE_FORMAT(DepartureTime, '%d-%b %H:%i') AS Departure,
  FlightCategory,
  ConnectingFlightID AS `Next`
FROM flights
WHERE FlightID >= 30
ORDER BY FlightID;

SELECT CONCAT('SkyBook import done. Total flights: ', COUNT(*)) AS Status FROM flights;
