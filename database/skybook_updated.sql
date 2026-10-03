-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 03, 2026 at 07:14 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `skybook`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancel_booking` (IN `p_booking_id` INT, IN `p_passenger_id` INT, OUT `p_result` VARCHAR(100))   BEGIN
    DECLARE v_status    VARCHAR(20);
    DECLARE v_aircraft  INT;
    DECLARE v_seat      VARCHAR(10);
    DECLARE v_ticket_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction rolled back.';
    END;

    -- Validate booking belongs to passenger
    SELECT Status INTO v_status
    FROM Bookings
    WHERE BookingID = p_booking_id AND PassengerID = p_passenger_id;

    IF v_status IS NULL THEN
        SET p_result = 'ERROR: Booking not found or not yours.';
    ELSEIF v_status = 'Cancelled' THEN
        SET p_result = 'ERROR: Already cancelled.';
    ELSE
        START TRANSACTION;

        -- Get ticket info
        SELECT TicketID, AircraftID, SeatNumber
        INTO   v_ticket_id, v_aircraft, v_seat
        FROM   Tickets
        WHERE  BookingID = p_booking_id;

        -- Cancel booking
        UPDATE Bookings SET Status = 'Cancelled' WHERE BookingID = p_booking_id;

        -- Release seat
        UPDATE Seats SET IsAvailable = TRUE
        WHERE AircraftID = v_aircraft AND SeatNumber = v_seat;

        -- Mark payment as Refunded
        UPDATE Payments SET PaymentStatus = 'Refunded'
        WHERE TicketID = v_ticket_id;

        COMMIT;
        SET p_result = CONCAT('SUCCESS: Booking ', p_booking_id, ' cancelled. Seat ', v_seat, ' released.');
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_confirm_booking` (IN `p_booking_id` INT, OUT `p_result` VARCHAR(100))   BEGIN
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

-- --------------------------------------------------------

--
-- Table structure for table `aircraft`
--

CREATE TABLE `aircraft` (
  `AircraftID` int(11) NOT NULL,
  `AirlineID` int(11) NOT NULL,
  `RegistrationNo` varchar(20) DEFAULT NULL,
  `AircraftModel` varchar(100) NOT NULL,
  `TotalSeats` int(11) NOT NULL CHECK (`TotalSeats` > 0),
  `Status` varchar(20) DEFAULT 'Active' CHECK (`Status` in ('Active','Grounded','Retired')),
  `ManufactureYear` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `aircraft`
--

INSERT INTO `aircraft` (`AircraftID`, `AirlineID`, `RegistrationNo`, `AircraftModel`, `TotalSeats`, `Status`, `ManufactureYear`) VALUES
(1, 1, 'VT-IGA', 'Airbus A320neo', 86, 'Active', 2019),
(2, 1, 'VT-IGB', 'Airbus A321neo', 100, 'Active', 2020),
(3, 2, 'VT-AIC', 'Boeing 787-8', 120, 'Active', 2018),
(4, 2, 'VT-AID', 'Boeing 777-300ER', 112, 'Active', 2016),
(5, 3, 'VT-SGC', 'Boeing 737-800', 86, 'Active', 2017),
(6, 3, 'VT-SGD', 'Boeing 737 MAX 8', 86, 'Active', 2021),
(7, 4, 'VT-TTB', 'Airbus A320neo', 86, 'Active', 2020),
(8, 2, 'VT-TTC', 'Boeing 787-9', 116, 'Active', 2019),
(9, 1, 'VT-GFA', 'Airbus A320', 86, 'Grounded', 2015),
(10, 1, 'VT-AAB', 'Airbus A320neo', 86, 'Active', 2022),
(11, 7, 'A6-EKA', 'Airbus A380-800', 86, 'Active', 2014),
(12, 7, 'A6-EKB', 'Boeing 777X', 86, 'Active', 2023),
(13, 8, 'A7-QRA', 'Airbus A350-900', 86, 'Active', 2018),
(14, 9, '9V-SQA', 'Boeing 777-300ER', 86, 'Active', 2017),
(15, 10, 'G-BAA', 'Airbus A380-800', 86, 'Active', 2013),
(16, 11, 'D-LHA', 'Airbus A350-900', 86, 'Active', 2019),
(17, 12, 'F-AFA', 'Boeing 777-300ER', 86, 'Active', 2016),
(18, 17, 'VT-QPA', 'Boeing 737 MAX 8', 86, 'Active', 2022),
(19, 19, 'VT-IXA', 'Boeing 737-800', 86, 'Active', 2018),
(20, 13, 'JA-JLA', 'Boeing 787-9', 86, 'Retired', 2010);

-- --------------------------------------------------------

--
-- Table structure for table `airlines`
--

CREATE TABLE `airlines` (
  `AirlineID` int(11) NOT NULL,
  `AirlineName` varchar(100) NOT NULL,
  `IATACode` varchar(3) NOT NULL,
  `Country` varchar(50) NOT NULL,
  `ContactEmail` varchar(100) DEFAULT NULL,
  `LogoURL` varchar(255) DEFAULT NULL,
  `IsActive` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `airlines`
--

INSERT INTO `airlines` (`AirlineID`, `AirlineName`, `IATACode`, `Country`, `ContactEmail`, `LogoURL`, `IsActive`) VALUES
(1, 'IndiGo', '6E', 'India', 'support@indigo.in', 'https://logos.example.com/indigo.png', 1),
(2, 'Air India', 'AI', 'India', 'care@airindia.in', 'https://logos.example.com/airindia.png', 1),
(3, 'SpiceJet', 'SG', 'India', 'support@spicejet.com', 'https://logos.example.com/spicejet.png', 1),
(4, 'Vistara', 'UK', 'India', 'customersupport@airvistara.com', 'https://logos.example.com/vistara.png', 1),
(5, 'Go First', 'G8', 'India', 'help@gofirst.in', 'https://logos.example.com/gofirst.png', 0),
(6, 'AirAsia India', 'I5', 'India', 'support@airasia.co.in', 'https://logos.example.com/airasia.png', 1),
(7, 'Emirates', 'EK', 'UAE', 'support@emirates.com', 'https://logos.example.com/emirates.png', 1),
(8, 'Qatar Airways', 'QR', 'Qatar', 'qrcare@qatarairways.com.qa', 'https://logos.example.com/qatar.png', 1),
(9, 'Singapore Airlines', 'SQ', 'Singapore', 'feedback@singaporeair.com.sg', 'https://logos.example.com/sia.png', 1),
(10, 'British Airways', 'BA', 'United Kingdom', 'support@ba.com', 'https://logos.example.com/ba.png', 1),
(11, 'Lufthansa', 'LH', 'Germany', 'info@lufthansa.com', 'https://logos.example.com/lufthansa.png', 1),
(12, 'Air France', 'AF', 'France', 'support@airfrance.fr', 'https://logos.example.com/airfrance.png', 1),
(13, 'Japan Airlines', 'JL', 'Japan', 'jal@jal.co.jp', 'https://logos.example.com/jal.png', 1),
(14, 'Qantas', 'QF', 'Australia', 'customercare@qantas.com.au', 'https://logos.example.com/qantas.png', 1),
(15, 'Malaysia Airlines', 'MH', 'Malaysia', 'support@malaysiaairlines.com', 'https://logos.example.com/mas.png', 1),
(16, 'Thai Airways', 'TG', 'Thailand', 'customer@thaiairways.com', 'https://logos.example.com/thai.png', 1),
(17, 'Akasa Air', 'QP', 'India', 'hello@akasaair.com', 'https://logos.example.com/akasa.png', 1),
(18, 'Alliance Air', 'CD', 'India', 'support@allianceair.in', 'https://logos.example.com/alliance.png', 0),
(19, 'Air India Express', 'IX', 'India', 'support@airindiaexpress.in', 'https://logos.example.com/airindiax.png', 1),
(20, 'Blue Dart Aviation', 'BZ', 'India', 'info@bluedart.com', 'https://logos.example.com/bluedart.png', 1);

-- --------------------------------------------------------

--
-- Table structure for table `airports`
--

CREATE TABLE `airports` (
  `AirportCode` varchar(10) NOT NULL,
  `AirportName` varchar(100) NOT NULL,
  `City` varchar(50) NOT NULL,
  `Country` varchar(50) NOT NULL,
  `TimeZone` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `airports`
--

INSERT INTO `airports` (`AirportCode`, `AirportName`, `City`, `Country`, `TimeZone`) VALUES
('AMD', 'Sardar Vallabhbhai Patel International', 'Ahmedabad', 'India', 'IST'),
('BKK', 'Suvarnabhumi Airport', 'Bangkok', 'Thailand', 'ICT'),
('BLR', 'Kempegowda International Airport', 'Bengaluru', 'India', 'IST'),
('BOM', 'Chhatrapati Shivaji Maharaj International', 'Mumbai', 'India', 'IST'),
('CCU', 'Netaji Subhas Chandra Bose International', 'Kolkata', 'India', 'IST'),
('CDG', 'Charles de Gaulle Airport', 'Paris', 'France', 'CET'),
('COK', 'Cochin International Airport', 'Kochi', 'India', 'IST'),
('DEL', 'Indira Gandhi International Airport', 'New Delhi', 'India', 'IST'),
('DOH', 'Hamad International Airport', 'Doha', 'Qatar', 'AST'),
('DXB', 'Dubai International Airport', 'Dubai', 'UAE', 'GST'),
('GOI', 'Goa International Airport', 'Goa', 'India', 'IST'),
('HYD', 'Rajiv Gandhi International Airport', 'Hyderabad', 'India', 'IST'),
('JFK', 'John F. Kennedy International Airport', 'New York', 'USA', 'EST'),
('KUL', 'Kuala Lumpur International Airport', 'Kuala Lumpur', 'Malaysia', 'MYT'),
('LHR', 'London Heathrow Airport', 'London', 'United Kingdom', 'GMT'),
('MAA', 'Chennai International Airport', 'Chennai', 'India', 'IST'),
('NRT', 'Narita International Airport', 'Tokyo', 'Japan', 'JST'),
('PNQ', 'Pune Airport', 'Pune', 'India', 'IST'),
('SIN', 'Singapore Changi Airport', 'Singapore', 'Singapore', 'SGT'),
('SYD', 'Sydney Kingsford Smith Airport', 'Sydney', 'Australia', 'AEST');

-- --------------------------------------------------------

--
-- Table structure for table `app_users`
--

CREATE TABLE `app_users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(64) NOT NULL,
  `role` varchar(10) NOT NULL CHECK (`role` in ('PASSENGER','AIRLINE','ADMIN')),
  `linked_id` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `app_users`
--

INSERT INTO `app_users` (`user_id`, `username`, `password_hash`, `role`, `linked_id`, `is_active`) VALUES
(1, 'admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'ADMIN', 0, 1),
(2, 'indigo', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 1, 1),
(3, 'spicejet', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 2, 1),
(4, 'vistara', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 3, 1),
(5, 'airindia', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 4, 1),
(6, 'goindigo', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 5, 1),
(7, 'akasa', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 6, 1),
(8, 'emirates', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 7, 1),
(9, 'qatar', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 8, 1),
(10, 'singapore', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 9, 1),
(11, 'airasia', 'e51b0d321f9d0f60f9221ba005eabe2834c3ca2f473727492b01bb5a22c247f7', 'AIRLINE', 10, 1);

-- --------------------------------------------------------

--
-- Table structure for table `bookingmeals`
--

CREATE TABLE `bookingmeals` (
  `BookingMealID` int(11) NOT NULL,
  `BookingID` int(11) NOT NULL,
  `PassengerID` int(11) NOT NULL,
  `MealID` int(11) NOT NULL,
  `Quantity` int(11) NOT NULL DEFAULT 1 CHECK (`Quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookingmeals`
--

INSERT INTO `bookingmeals` (`BookingMealID`, `BookingID`, `PassengerID`, `MealID`, `Quantity`) VALUES
(1, 1, 1, 1, 1),
(2, 2, 2, 3, 1),
(3, 3, 3, 9, 1),
(4, 4, 4, 2, 2),
(5, 5, 5, 10, 1),
(6, 6, 6, 11, 1),
(7, 7, 7, 19, 1),
(8, 8, 7, 22, 1),
(9, 9, 8, 25, 1),
(10, 10, 8, 26, 1),
(11, 11, 9, 32, 1),
(12, 12, 10, 33, 1),
(13, 13, 11, 1, 1),
(14, 14, 12, 4, 1),
(15, 15, 13, 17, 1),
(16, 16, 14, 37, 1),
(17, 17, 15, 38, 1),
(18, 18, 16, 35, 1),
(19, 19, 17, 31, 1),
(20, 20, 18, 34, 1),
(21, 21, 21, 26, 1),
(22, 22, 21, 11, 1),
(23, 23, 21, 34, 1),
(24, 24, 22, 36, 1),
(25, 25, 22, 40, 1),
(26, 26, 19, 5, 1),
(27, 27, 20, 13, 1),
(28, 28, 23, 6, 2),
(29, 29, 24, 8, 1),
(30, 30, 25, 15, 1);

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `BookingID` int(11) NOT NULL,
  `FlightID` int(11) NOT NULL,
  `PassengerID` int(11) NOT NULL,
  `BookingDate` datetime DEFAULT current_timestamp(),
  `Status` varchar(20) DEFAULT 'Pending' CHECK (`Status` in ('Pending','Confirmed','Cancelled','Completed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`BookingID`, `FlightID`, `PassengerID`, `BookingDate`, `Status`) VALUES
(1, 1, 1, '2025-07-01 10:00:00', 'Confirmed'),
(2, 2, 2, '2025-07-01 11:00:00', 'Confirmed'),
(3, 3, 3, '2025-07-02 09:30:00', 'Confirmed'),
(4, 4, 4, '2025-07-03 14:00:00', 'Pending'),
(5, 5, 5, '2025-07-03 15:30:00', 'Confirmed'),
(6, 6, 6, '2025-07-04 08:00:00', 'Cancelled'),
(7, 7, 7, '2025-07-04 12:00:00', 'Confirmed'),
(8, 9, 7, '2025-07-04 12:05:00', 'Confirmed'),
(9, 8, 8, '2025-07-05 10:45:00', 'Confirmed'),
(10, 21, 8, '2025-07-05 10:50:00', 'Confirmed'),
(11, 10, 9, '2025-07-05 16:00:00', 'Pending'),
(12, 10, 10, '2025-07-06 09:00:00', 'Confirmed'),
(13, 11, 11, '2025-07-06 11:30:00', 'Confirmed'),
(14, 12, 12, '2025-07-07 13:00:00', 'Pending'),
(15, 13, 13, '2025-07-07 14:45:00', 'Confirmed'),
(16, 14, 14, '2025-07-08 08:30:00', 'Cancelled'),
(17, 15, 15, '2025-07-08 10:00:00', 'Confirmed'),
(18, 16, 16, '2025-07-09 09:00:00', 'Confirmed'),
(19, 17, 17, '2025-07-09 11:00:00', 'Pending'),
(20, 18, 18, '2025-07-10 07:30:00', 'Confirmed'),
(21, 22, 21, '2025-07-11 08:00:00', 'Confirmed'),
(22, 23, 21, '2025-07-11 08:05:00', 'Confirmed'),
(23, 24, 21, '2025-07-11 08:10:00', 'Confirmed'),
(24, 28, 22, '2025-07-12 09:00:00', 'Confirmed'),
(25, 29, 22, '2025-07-12 09:05:00', 'Confirmed'),
(26, 19, 19, '2025-07-10 12:00:00', 'Confirmed'),
(27, 20, 20, '2025-07-10 15:00:00', 'Pending'),
(28, 25, 23, '2025-07-12 10:00:00', 'Confirmed'),
(29, 26, 24, '2025-07-12 11:00:00', 'Confirmed'),
(30, 27, 25, '2025-07-12 12:00:00', 'Pending');

--
-- Triggers `bookings`
--
DELIMITER $$
CREATE TRIGGER `trg_seat_release_on_cancel` AFTER UPDATE ON `bookings` FOR EACH ROW BEGIN
    IF NEW.Status = 'Cancelled' AND OLD.Status != 'Cancelled' THEN
        UPDATE Seats s
        JOIN Tickets t ON t.AircraftID = s.AircraftID
                      AND t.SeatNumber  = s.SeatNumber
        SET s.IsAvailable = TRUE
        WHERE t.BookingID = NEW.BookingID;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `flights`
--

CREATE TABLE `flights` (
  `FlightID` int(11) NOT NULL,
  `AircraftID` int(11) NOT NULL,
  `DepartureAirportID` varchar(10) NOT NULL,
  `ArrivalAirportID` varchar(10) NOT NULL,
  `DepartureTime` datetime NOT NULL,
  `ArrivalTime` datetime NOT NULL,
  `StateTaxAmount` decimal(10,2) NOT NULL,
  `BasePrice` decimal(10,2) NOT NULL CHECK (`BasePrice` >= 0),
  `FlightType` varchar(20) NOT NULL CHECK (`FlightType` in ('National','International')),
  `FlightCategory` varchar(20) NOT NULL DEFAULT 'Direct' CHECK (`FlightCategory` in ('Direct','Connecting')),
  `ConnectingFlightID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `flights`
--

INSERT INTO `flights` (`FlightID`, `AircraftID`, `DepartureAirportID`, `ArrivalAirportID`, `DepartureTime`, `ArrivalTime`, `StateTaxAmount`, `BasePrice`, `FlightType`, `FlightCategory`, `ConnectingFlightID`) VALUES
(1, 1, 'DEL', 'BOM', '2026-08-05 06:00:00', '2026-08-05 08:10:00', 250.00, 3500.00, 'National', 'Direct', NULL),
(2, 2, 'BOM', 'DEL', '2026-08-05 09:00:00', '2026-08-05 11:15:00', 250.00, 3600.00, 'National', 'Direct', NULL),
(3, 3, 'DEL', 'BLR', '2026-08-05 07:30:00', '2026-08-05 10:00:00', 300.00, 4200.00, 'National', 'Direct', NULL),
(4, 4, 'BLR', 'HYD', '2026-08-06 08:00:00', '2026-08-06 09:00:00', 150.00, 2500.00, 'National', 'Direct', NULL),
(5, 5, 'HYD', 'MAA', '2026-08-06 11:00:00', '2026-08-06 12:10:00', 180.00, 2800.00, 'National', 'Direct', NULL),
(6, 6, 'MAA', 'CCU', '2026-08-06 06:30:00', '2026-08-06 08:45:00', 220.00, 3900.00, 'National', 'Direct', NULL),
(7, 7, 'DEL', 'DXB', '2026-08-07 22:00:00', '2026-08-08 00:30:00', 500.00, 12000.00, 'International', 'Connecting', 9),
(8, 8, 'BOM', 'SIN', '2026-08-08 01:00:00', '2026-08-08 10:30:00', 600.00, 18000.00, 'International', 'Connecting', 21),
(9, 9, 'DXB', 'LHR', '2026-08-08 03:30:00', '2026-08-08 08:00:00', 1200.00, 33000.00, 'International', 'Connecting', NULL),
(10, 10, 'BLR', 'DXB', '2026-08-09 23:45:00', '2026-08-10 02:00:00', 500.00, 14000.00, 'International', 'Direct', NULL),
(11, 1, 'AMD', 'DEL', '2026-08-06 07:00:00', '2026-08-06 08:30:00', 180.00, 3000.00, 'National', 'Direct', NULL),
(12, 2, 'COK', 'BOM', '2026-08-06 10:00:00', '2026-08-06 12:00:00', 220.00, 3800.00, 'National', 'Direct', NULL),
(13, 3, 'GOI', 'DEL', '2026-08-07 14:00:00', '2026-08-07 16:30:00', 260.00, 4500.00, 'National', 'Direct', NULL),
(14, 4, 'PNQ', 'HYD', '2026-08-07 09:00:00', '2026-08-07 10:20:00', 160.00, 2700.00, 'National', 'Direct', NULL),
(15, 5, 'DEL', 'COK', '2026-08-07 13:00:00', '2026-08-07 16:00:00', 200.00, 4100.00, 'National', 'Direct', NULL),
(16, 6, 'BOM', 'CDG', '2026-08-08 03:00:00', '2026-08-08 09:00:00', 1100.00, 48000.00, 'International', 'Direct', NULL),
(17, 7, 'DEL', 'SYD', '2026-08-09 05:00:00', '2026-08-09 23:00:00', 1300.00, 62000.00, 'International', 'Direct', NULL),
(18, 8, 'BLR', 'SIN', '2026-08-09 22:00:00', '2026-08-10 06:00:00', 600.00, 19000.00, 'International', 'Connecting', 21),
(19, 9, 'DEL', 'BOM', '2026-08-10 12:00:00', '2026-08-10 14:00:00', 250.00, 3400.00, 'National', 'Direct', NULL),
(20, 10, 'BOM', 'KUL', '2026-08-10 23:00:00', '2026-08-11 07:30:00', 700.00, 22000.00, 'International', 'Direct', NULL),
(21, 7, 'SIN', 'SYD', '2026-08-08 13:00:00', '2026-08-08 23:00:00', 800.00, 28000.00, 'International', 'Connecting', NULL),
(22, 8, 'DEL', 'KUL', '2026-08-11 01:00:00', '2026-08-11 09:00:00', 700.00, 20000.00, 'International', 'Connecting', 23),
(23, 9, 'KUL', 'BKK', '2026-08-11 11:00:00', '2026-08-11 13:00:00', 300.00, 8000.00, 'International', 'Connecting', 24),
(24, 10, 'BKK', 'SYD', '2026-08-11 15:00:00', '2026-08-11 23:00:00', 900.00, 25000.00, 'International', 'Connecting', NULL),
(25, 1, 'DEL', 'AMD', '2026-08-12 06:30:00', '2026-08-12 08:00:00', 150.00, 2900.00, 'National', 'Direct', NULL),
(26, 2, 'BOM', 'GOI', '2026-08-12 09:00:00', '2026-08-12 10:10:00', 140.00, 2600.00, 'National', 'Direct', NULL),
(27, 3, 'BLR', 'MAA', '2026-08-12 11:00:00', '2026-08-12 12:00:00', 120.00, 2200.00, 'National', 'Direct', NULL),
(28, 4, 'BOM', 'DOH', '2026-08-13 02:00:00', '2026-08-13 04:30:00', 600.00, 15000.00, 'International', 'Connecting', 29),
(29, 5, 'DOH', 'LHR', '2026-08-13 06:30:00', '2026-08-13 11:00:00', 900.00, 30000.00, 'International', 'Connecting', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `meals`
--

CREATE TABLE `meals` (
  `MealID` int(11) NOT NULL,
  `AirlineID` int(11) NOT NULL,
  `MealName` varchar(100) NOT NULL,
  `MealCategory` varchar(10) NOT NULL CHECK (`MealCategory` in ('Snack','Meal')),
  `DietType` varchar(10) NOT NULL CHECK (`DietType` in ('Veg','Non-Veg')),
  `MealType` varchar(20) NOT NULL CHECK (`MealType` in ('Vegetarian','Non-Vegetarian','Vegan','Jain','Special')),
  `Price` decimal(10,2) NOT NULL DEFAULT 0.00 CHECK (`Price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `meals`
--

INSERT INTO `meals` (`MealID`, `AirlineID`, `MealName`, `MealCategory`, `DietType`, `MealType`, `Price`) VALUES
(1, 1, 'Veg Sandwich', 'Snack', 'Veg', 'Vegetarian', 80.00),
(2, 1, 'Samosa Combo', 'Snack', 'Veg', 'Vegetarian', 70.00),
(3, 1, 'Chicken Roll', 'Snack', 'Non-Veg', 'Non-Vegetarian', 100.00),
(4, 1, 'Egg Muffin', 'Snack', 'Non-Veg', 'Non-Vegetarian', 90.00),
(5, 1, 'Veg Biryani', 'Meal', 'Veg', 'Vegetarian', 150.00),
(6, 1, 'Chicken Biryani', 'Meal', 'Non-Veg', 'Non-Vegetarian', 180.00),
(7, 1, 'Dal Rice Combo', 'Meal', 'Veg', 'Jain', 140.00),
(8, 1, 'Fish Curry Rice', 'Meal', 'Non-Veg', 'Non-Vegetarian', 190.00),
(9, 3, 'Masala Peanuts', 'Snack', 'Veg', 'Vegetarian', 60.00),
(10, 3, 'Veg Puff', 'Snack', 'Veg', 'Vegetarian', 75.00),
(11, 3, 'Chicken Sandwich', 'Snack', 'Non-Veg', 'Non-Vegetarian', 95.00),
(12, 3, 'Boiled Egg Snack', 'Snack', 'Non-Veg', 'Non-Vegetarian', 80.00),
(13, 3, 'Paneer Rice Bowl', 'Meal', 'Veg', 'Vegetarian', 160.00),
(14, 3, 'Mutton Curry Meal', 'Meal', 'Non-Veg', 'Non-Vegetarian', 200.00),
(15, 3, 'Jain Thali', 'Meal', 'Veg', 'Jain', 155.00),
(16, 3, 'Prawn Rice', 'Meal', 'Non-Veg', 'Non-Vegetarian', 210.00),
(17, 4, 'Fruit Yogurt Cup', 'Snack', 'Veg', 'Vegan', 120.00),
(18, 4, 'Cheese Crackers', 'Snack', 'Veg', 'Vegetarian', 110.00),
(19, 4, 'Grilled Chicken Wrap', 'Snack', 'Non-Veg', 'Non-Vegetarian', 160.00),
(20, 4, 'Tuna Croissant', 'Snack', 'Non-Veg', 'Non-Vegetarian', 155.00),
(21, 4, 'Paneer Butter Masala', 'Meal', 'Veg', 'Vegetarian', 280.00),
(22, 4, 'Chicken Tikka Masala', 'Meal', 'Non-Veg', 'Non-Vegetarian', 320.00),
(23, 4, 'Diabetic Veg Meal', 'Meal', 'Veg', 'Special', 290.00),
(24, 4, 'Gluten Free Chicken', 'Meal', 'Non-Veg', 'Special', 310.00),
(25, 2, 'Dal Makhani Rice', 'Meal', 'Veg', 'Vegetarian', 380.00),
(26, 2, 'Lamb Rogan Josh', 'Meal', 'Non-Veg', 'Non-Vegetarian', 430.00),
(27, 2, 'Kids Veg Pasta', 'Meal', 'Veg', 'Vegetarian', 300.00),
(28, 2, 'Butter Chicken Meal', 'Meal', 'Non-Veg', 'Non-Vegetarian', 420.00),
(29, 7, 'Arabian Mezze Platter', 'Snack', 'Veg', 'Vegetarian', 350.00),
(30, 7, 'Smoked Salmon Canapé', 'Snack', 'Non-Veg', 'Non-Vegetarian', 420.00),
(31, 7, 'Vegetable Biryani', 'Meal', 'Veg', 'Vegetarian', 650.00),
(32, 7, 'Grilled Lamb Chops', 'Meal', 'Non-Veg', 'Non-Vegetarian', 850.00),
(33, 7, 'Vegan Buddha Bowl', 'Meal', 'Veg', 'Vegan', 600.00),
(34, 7, 'Seafood Linguine', 'Meal', 'Non-Veg', 'Non-Vegetarian', 800.00),
(35, 8, 'Mezze Selection', 'Snack', 'Veg', 'Vegetarian', 380.00),
(36, 8, 'Shrimp Cocktail', 'Snack', 'Non-Veg', 'Non-Vegetarian', 450.00),
(37, 8, 'Paneer Tikka Masala', 'Meal', 'Veg', 'Vegetarian', 700.00),
(38, 8, 'Beef Tenderloin', 'Meal', 'Non-Veg', 'Non-Vegetarian', 950.00),
(39, 8, 'Diabetic Friendly Meal', 'Meal', 'Veg', 'Special', 680.00),
(40, 8, 'Arabic Lamb Kabsa', 'Meal', 'Non-Veg', 'Non-Vegetarian', 900.00);

-- --------------------------------------------------------

--
-- Table structure for table `passengers`
--

CREATE TABLE `passengers` (
  `PassengerID` int(11) NOT NULL,
  `FirstName` varchar(50) NOT NULL,
  `LastName` varchar(50) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `ContactNo` varchar(15) NOT NULL,
  `DateOfBirth` date NOT NULL,
  `PassportNumber` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Age check triggers removed: the 18+ minimum age is enforced at
-- ACCOUNT REGISTRATION in Java (AuthService), not at the passenger row level.
-- Children and infants must be insertable as travelling passengers.

--
-- Dumping data for table `passengers`
--

INSERT INTO `passengers` (`PassengerID`, `FirstName`, `LastName`, `Email`, `ContactNo`, `DateOfBirth`, `PassportNumber`) VALUES
(1, 'Aarav', 'Sharma', 'aaravsharma@gmail.com', '+919876543210', '1995-03-15', 'P1234567'),
(2, 'Priya', 'Patel', 'priyapatel@gmail.com', '+919823456781', '1992-07-22', 'P2345678'),
(3, 'Rohan', 'Mehta', 'rohanmehta@yahoo.com', '+919712345672', '1988-11-05', 'P3456789'),
(4, 'Sneha', 'Iyer', 'snehaiyer@gmail.com', '+919601234563', '1997-01-30', 'P4567890'),
(5, 'Vikram', 'Singh', 'vikramsingh@gmail.com', '+919590123454', '1985-09-14', 'P5678901'),
(6, 'Kavya', 'Nair', 'kavyanair@gmail.com', '+919489012345', '2000-05-18', NULL),
(7, 'Arjun', 'Reddy', 'arjunreddy@gmail.com', '+919378901236', '1993-12-25', 'P6789012'),
(8, 'Meera', 'Joshi', 'meerajoshi@gmail.com', '+919267890127', '1991-04-08', 'P7890123'),
(9, 'Kiran', 'Gupta', 'kirangupta@gmail.com', '+919156789018', '1996-08-20', NULL),
(10, 'Ananya', 'Desai', 'ananyadesai@gmail.com', '+919045678909', '1999-02-14', 'P8901234'),
(11, 'Rahul', 'Kumar', 'rahulkumar@gmail.com', '+919934567890', '1987-06-10', 'P9012345'),
(12, 'Divya', 'Bose', 'divyabose@gmail.com', '+919823456700', '1994-10-03', 'P0123456'),
(13, 'Nikhil', 'Verma', 'nikhilverma@gmail.com', '+919712345600', '1990-03-27', 'PA123456'),
(14, 'Pooja', 'Chopra', 'poojachopra@yahoo.com', '+919601234500', '1998-07-11', NULL),
(15, 'Siddharth', 'Rao', 'siddharthrao@gmail.com', '+919590123400', '1986-12-01', 'PB234567'),
(16, 'Aishwarya', 'Menon', 'aishwaryamenon@gmail.com', '+919479012300', '2001-09-09', 'PC345678'),
(17, 'Rajesh', 'Pillai', 'rajeshpillai@gmail.com', '+919368901200', '1983-05-25', 'PD456789'),
(18, 'Sunita', 'Tiwari', 'sunitatiwari@gmail.com', '+919257890100', '1995-11-17', 'PE567890'),
(19, 'Amit', 'Bhatt', 'amitbhatt@gmail.com', '+919146789000', '1989-04-30', 'PF678901'),
(20, 'Neha', 'Shah', 'nehashah@gmail.com', '+919035678900', '2002-01-21', NULL),
(21, 'Sameer', 'Khan', 'sameerkhan@gmail.com', '+919924567890', '1991-06-15', 'PG789012'),
(22, 'Riya', 'Jain', 'riyajain@gmail.com', '+919813456780', '1998-03-22', NULL),
(23, 'Deepak', 'Mishra', 'deepakmishra@yahoo.com', '+919702345670', '1984-08-30', 'PH890123'),
(24, 'Pratha', 'Agarwal', 'prathaagarwal@gmail.com', '+919591234560', '2003-12-05', NULL),
(25, 'Harish', 'Nayak', 'harishnayak@gmail.com', '+919480123450', '1979-07-19', 'PI901234');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `PaymentID` int(11) NOT NULL,
  `TicketID` int(11) NOT NULL,
  `Amount` decimal(10,2) NOT NULL CHECK (`Amount` > 0),
  `PaymentMethod` varchar(20) NOT NULL,
  `TransactionDate` datetime DEFAULT current_timestamp(),
  `PaymentStatus` varchar(20) DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`PaymentID`, `TicketID`, `Amount`, `PaymentMethod`, `TransactionDate`, `PaymentStatus`) VALUES
(1, 1, 3575.00, 'UPI', '2025-07-01 10:05:00', 'Success'),
(2, 2, 4250.00, 'Credit Card', '2025-07-01 11:08:00', 'Success'),
(3, 3, 4200.00, 'Debit Card', '2025-07-02 09:35:00', 'Success'),
(4, 4, 4000.00, 'Net Banking', '2025-07-03 14:10:00', 'Pending'),
(5, 5, 2875.00, 'UPI', '2025-07-03 15:35:00', 'Success'),
(6, 6, 3975.00, 'Credit Card', '2025-07-04 08:05:00', 'Refunded'),
(7, 7, 13750.00, 'Credit Card', '2025-07-04 12:10:00', 'Success'),
(8, 8, 33200.00, 'Credit Card', '2025-07-04 12:12:00', 'Success'),
(9, 9, 18200.00, 'Net Banking', '2025-07-05 10:50:00', 'Success'),
(10, 10, 28500.00, 'Net Banking', '2025-07-05 10:52:00', 'Success'),
(11, 11, 16800.00, 'Credit Card', '2025-07-05 16:10:00', 'Pending'),
(12, 12, 14100.00, 'Debit Card', '2025-07-06 09:05:00', 'Success'),
(13, 13, 3150.00, 'UPI', '2025-07-06 11:35:00', 'Success'),
(14, 14, 4500.00, 'UPI', '2025-07-07 13:05:00', 'Pending'),
(15, 15, 4400.00, 'Credit Card', '2025-07-07 14:50:00', 'Success'),
(16, 16, 2500.00, 'Net Banking', '2025-07-08 08:35:00', 'Refunded'),
(17, 17, 54300.00, 'Credit Card', '2025-07-08 10:10:00', 'Success'),
(18, 18, 48300.00, 'Debit Card', '2025-07-09 09:10:00', 'Success'),
(19, 19, 65200.00, 'Credit Card', '2025-07-09 11:10:00', 'Pending'),
(20, 20, 19500.00, 'UPI', '2025-07-10 07:35:00', 'Success'),
(21, 21, 20200.00, 'Credit Card', '2025-07-11 08:05:00', 'Success'),
(22, 22, 8200.00, 'Credit Card', '2025-07-11 08:07:00', 'Success'),
(23, 23, 26650.00, 'Credit Card', '2025-07-11 08:09:00', 'Success'),
(24, 24, 15200.00, 'Net Banking', '2025-07-12 09:05:00', 'Success'),
(25, 25, 31150.00, 'Net Banking', '2025-07-12 09:07:00', 'Success'),
(26, 26, 3475.00, 'UPI', '2025-07-12 10:05:00', 'Success'),
(27, 27, 23350.00, 'Debit Card', '2025-07-12 11:05:00', 'Pending'),
(28, 28, 2900.00, 'UPI', '2025-07-12 12:05:00', 'Success'),
(29, 29, 2675.00, 'Debit Card', '2025-07-12 13:05:00', 'Success'),
(30, 30, 2400.00, 'Net Banking', '2025-07-12 14:05:00', 'Pending');

-- --------------------------------------------------------

--
-- Table structure for table `seats`
--

CREATE TABLE `seats` (
  `AircraftID` int(11) NOT NULL,
  `SeatNumber` varchar(10) NOT NULL,
  `SeatClass` varchar(20) NOT NULL CHECK (`SeatClass` in ('Economy','Business','First')),
  `SeatPosition` varchar(10) NOT NULL CHECK (`SeatPosition` in ('Aisle','Window','Middle')),
  `SeatSurcharge` decimal(8,2) NOT NULL DEFAULT 0.00,
  `IsAvailable` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `seats`
--

INSERT INTO `seats` (`AircraftID`, `SeatNumber`, `SeatClass`, `SeatPosition`, `SeatSurcharge`, `IsAvailable`) VALUES
(1, '10A', 'Economy', 'Aisle', 75.00, 0),
(1, '10A2', 'Economy', 'Aisle', 75.00, 1),
(1, '10M', 'Economy', 'Middle', 0.00, 1),
(1, '10M2', 'Economy', 'Middle', 0.00, 0),
(1, '10W', 'Economy', 'Window', 150.00, 1),
(1, '10W2', 'Economy', 'Window', 150.00, 1),
(1, '11A', 'Economy', 'Aisle', 75.00, 1),
(1, '11A2', 'Economy', 'Aisle', 75.00, 1),
(1, '11M', 'Economy', 'Middle', 0.00, 1),
(1, '11M2', 'Economy', 'Middle', 0.00, 1),
(1, '11W', 'Economy', 'Window', 150.00, 1),
(1, '11W2', 'Economy', 'Window', 150.00, 1),
(1, '12A', 'Economy', 'Aisle', 75.00, 1),
(1, '12A2', 'Economy', 'Aisle', 75.00, 0),
(1, '12M', 'Economy', 'Middle', 0.00, 1),
(1, '12M2', 'Economy', 'Middle', 0.00, 0),
(1, '12W', 'Economy', 'Window', 150.00, 1),
(1, '12W2', 'Economy', 'Window', 150.00, 1),
(1, '13A', 'Economy', 'Aisle', 75.00, 1),
(1, '13A2', 'Economy', 'Aisle', 75.00, 1),
(1, '13M', 'Economy', 'Middle', 0.00, 1),
(1, '13M2', 'Economy', 'Middle', 0.00, 1),
(1, '13W', 'Economy', 'Window', 150.00, 1),
(1, '13W2', 'Economy', 'Window', 150.00, 1),
(1, '14A', 'Economy', 'Aisle', 75.00, 1),
(1, '14A2', 'Economy', 'Aisle', 75.00, 1),
(1, '14M', 'Economy', 'Middle', 0.00, 1),
(1, '14M2', 'Economy', 'Middle', 0.00, 1),
(1, '14W', 'Economy', 'Window', 150.00, 0),
(1, '14W2', 'Economy', 'Window', 150.00, 1),
(1, '15A', 'Economy', 'Aisle', 75.00, 0),
(1, '15A2', 'Economy', 'Aisle', 75.00, 1),
(1, '15M', 'Economy', 'Middle', 0.00, 0),
(1, '15M2', 'Economy', 'Middle', 0.00, 1),
(1, '15W', 'Economy', 'Window', 150.00, 0),
(1, '15W2', 'Economy', 'Window', 150.00, 1),
(1, '1A', 'Business', 'Aisle', 75.00, 1),
(1, '1W', 'Business', 'Window', 150.00, 1),
(1, '2A', 'Economy', 'Aisle', 75.00, 1),
(1, '2A2', 'Economy', 'Aisle', 75.00, 1),
(1, '2M', 'Economy', 'Middle', 0.00, 1),
(1, '2M2', 'Economy', 'Middle', 0.00, 1),
(1, '2W', 'Economy', 'Window', 150.00, 1),
(1, '2W2', 'Economy', 'Window', 150.00, 1),
(1, '3A', 'Economy', 'Aisle', 75.00, 0),
(1, '3A2', 'Economy', 'Aisle', 75.00, 1),
(1, '3M', 'Economy', 'Middle', 0.00, 1),
(1, '3M2', 'Economy', 'Middle', 0.00, 1),
(1, '3W', 'Economy', 'Window', 150.00, 0),
(1, '3W2', 'Economy', 'Window', 150.00, 1),
(1, '4A', 'Economy', 'Aisle', 75.00, 1),
(1, '4A2', 'Economy', 'Aisle', 75.00, 1),
(1, '4M', 'Economy', 'Middle', 0.00, 1),
(1, '4M2', 'Economy', 'Middle', 0.00, 0),
(1, '4W', 'Economy', 'Window', 150.00, 0),
(1, '4W2', 'Economy', 'Window', 150.00, 1),
(1, '5A', 'Economy', 'Aisle', 75.00, 1),
(1, '5A2', 'Economy', 'Aisle', 75.00, 1),
(1, '5M', 'Economy', 'Middle', 0.00, 1),
(1, '5M2', 'Economy', 'Middle', 0.00, 0),
(1, '5W', 'Economy', 'Window', 150.00, 0),
(1, '5W2', 'Economy', 'Window', 150.00, 1),
(1, '6A', 'Economy', 'Aisle', 75.00, 1),
(1, '6A2', 'Economy', 'Aisle', 75.00, 1),
(1, '6M', 'Economy', 'Middle', 0.00, 1),
(1, '6M2', 'Economy', 'Middle', 0.00, 1),
(1, '6W', 'Economy', 'Window', 150.00, 1),
(1, '6W2', 'Economy', 'Window', 150.00, 1),
(1, '7A', 'Economy', 'Aisle', 75.00, 1),
(1, '7A2', 'Economy', 'Aisle', 75.00, 1),
(1, '7M', 'Economy', 'Middle', 0.00, 1),
(1, '7M2', 'Economy', 'Middle', 0.00, 1),
(1, '7W', 'Economy', 'Window', 150.00, 0),
(1, '7W2', 'Economy', 'Window', 150.00, 1),
(1, '8A', 'Economy', 'Aisle', 75.00, 0),
(1, '8A2', 'Economy', 'Aisle', 75.00, 1),
(1, '8M', 'Economy', 'Middle', 0.00, 1),
(1, '8M2', 'Economy', 'Middle', 0.00, 1),
(1, '8W', 'Economy', 'Window', 150.00, 0),
(1, '8W2', 'Economy', 'Window', 150.00, 1),
(1, '9A', 'Economy', 'Aisle', 75.00, 1),
(1, '9A2', 'Economy', 'Aisle', 75.00, 1),
(1, '9M', 'Economy', 'Middle', 0.00, 1),
(1, '9M2', 'Economy', 'Middle', 0.00, 1),
(1, '9W', 'Economy', 'Window', 150.00, 1),
(1, '9W2', 'Economy', 'Window', 150.00, 1),
(2, '10A', 'Economy', 'Aisle', 75.00, 1),
(2, '10A2', 'Economy', 'Aisle', 75.00, 1),
(2, '10M', 'Economy', 'Middle', 0.00, 1),
(2, '10M2', 'Economy', 'Middle', 0.00, 1),
(2, '10W', 'Economy', 'Window', 150.00, 1),
(2, '10W2', 'Economy', 'Window', 150.00, 0),
(2, '11A', 'Economy', 'Aisle', 75.00, 1),
(2, '11A2', 'Economy', 'Aisle', 75.00, 0),
(2, '11M', 'Economy', 'Middle', 0.00, 1),
(2, '11M2', 'Economy', 'Middle', 0.00, 1),
(2, '11W', 'Economy', 'Window', 150.00, 1),
(2, '11W2', 'Economy', 'Window', 150.00, 1),
(2, '12A', 'Economy', 'Aisle', 75.00, 1),
(2, '12A2', 'Economy', 'Aisle', 75.00, 1),
(2, '12M', 'Economy', 'Middle', 0.00, 1),
(2, '12M2', 'Economy', 'Middle', 0.00, 0),
(2, '12W', 'Economy', 'Window', 150.00, 0),
(2, '12W2', 'Economy', 'Window', 150.00, 1),
(2, '13A', 'Economy', 'Aisle', 75.00, 1),
(2, '13A2', 'Economy', 'Aisle', 75.00, 1),
(2, '13M', 'Economy', 'Middle', 0.00, 0),
(2, '13M2', 'Economy', 'Middle', 0.00, 1),
(2, '13W', 'Economy', 'Window', 150.00, 0),
(2, '13W2', 'Economy', 'Window', 150.00, 1),
(2, '14A', 'Economy', 'Aisle', 75.00, 1),
(2, '14A2', 'Economy', 'Aisle', 75.00, 1),
(2, '14M', 'Economy', 'Middle', 0.00, 1),
(2, '14M2', 'Economy', 'Middle', 0.00, 1),
(2, '14W', 'Economy', 'Window', 150.00, 1),
(2, '14W2', 'Economy', 'Window', 150.00, 1),
(2, '15A', 'Economy', 'Aisle', 75.00, 1),
(2, '15A2', 'Economy', 'Aisle', 75.00, 1),
(2, '15M', 'Economy', 'Middle', 0.00, 1),
(2, '15M2', 'Economy', 'Middle', 0.00, 1),
(2, '15W', 'Economy', 'Window', 150.00, 1),
(2, '15W2', 'Economy', 'Window', 150.00, 1),
(2, '16A', 'Economy', 'Aisle', 75.00, 0),
(2, '16A2', 'Economy', 'Aisle', 75.00, 1),
(2, '16M', 'Economy', 'Middle', 0.00, 1),
(2, '16M2', 'Economy', 'Middle', 0.00, 1),
(2, '16W', 'Economy', 'Window', 150.00, 1),
(2, '16W2', 'Economy', 'Window', 150.00, 0),
(2, '17A', 'Economy', 'Aisle', 75.00, 0),
(2, '17A2', 'Economy', 'Aisle', 75.00, 1),
(2, '17M', 'Economy', 'Middle', 0.00, 0),
(2, '17M2', 'Economy', 'Middle', 0.00, 1),
(2, '17W', 'Economy', 'Window', 150.00, 1),
(2, '17W2', 'Economy', 'Window', 150.00, 1),
(2, '18A', 'Economy', 'Aisle', 75.00, 0),
(2, '18A2', 'Economy', 'Aisle', 75.00, 0),
(2, '18M', 'Economy', 'Middle', 0.00, 1),
(2, '18M2', 'Economy', 'Middle', 0.00, 0),
(2, '18W', 'Economy', 'Window', 150.00, 0),
(2, '18W2', 'Economy', 'Window', 150.00, 1),
(2, '1A', 'Business', 'Aisle', 75.00, 1),
(2, '1W', 'Business', 'Window', 150.00, 1),
(2, '2A', 'Business', 'Aisle', 75.00, 0),
(2, '2W', 'Business', 'Window', 150.00, 0),
(2, '3A', 'Economy', 'Aisle', 75.00, 1),
(2, '3A2', 'Economy', 'Aisle', 75.00, 1),
(2, '3M', 'Economy', 'Middle', 0.00, 1),
(2, '3M2', 'Economy', 'Middle', 0.00, 0),
(2, '3W', 'Economy', 'Window', 150.00, 0),
(2, '3W2', 'Economy', 'Window', 150.00, 1),
(2, '4A', 'Economy', 'Aisle', 75.00, 1),
(2, '4A2', 'Economy', 'Aisle', 75.00, 1),
(2, '4M', 'Economy', 'Middle', 0.00, 0),
(2, '4M2', 'Economy', 'Middle', 0.00, 1),
(2, '4W', 'Economy', 'Window', 150.00, 1),
(2, '4W2', 'Economy', 'Window', 150.00, 0),
(2, '5A', 'Economy', 'Aisle', 75.00, 0),
(2, '5A2', 'Economy', 'Aisle', 75.00, 0),
(2, '5M', 'Economy', 'Middle', 0.00, 0),
(2, '5M2', 'Economy', 'Middle', 0.00, 1),
(2, '5W', 'Economy', 'Window', 150.00, 1),
(2, '5W2', 'Economy', 'Window', 150.00, 1),
(2, '6A', 'Economy', 'Aisle', 75.00, 1),
(2, '6A2', 'Economy', 'Aisle', 75.00, 1),
(2, '6M', 'Economy', 'Middle', 0.00, 1),
(2, '6M2', 'Economy', 'Middle', 0.00, 1),
(2, '6W', 'Economy', 'Window', 150.00, 1),
(2, '6W2', 'Economy', 'Window', 150.00, 0),
(2, '7A', 'Economy', 'Aisle', 75.00, 1),
(2, '7A2', 'Economy', 'Aisle', 75.00, 1),
(2, '7M', 'Economy', 'Middle', 0.00, 0),
(2, '7M2', 'Economy', 'Middle', 0.00, 1),
(2, '7W', 'Economy', 'Window', 150.00, 1),
(2, '7W2', 'Economy', 'Window', 150.00, 1),
(2, '8A', 'Economy', 'Aisle', 75.00, 1),
(2, '8A2', 'Economy', 'Aisle', 75.00, 1),
(2, '8M', 'Economy', 'Middle', 0.00, 1),
(2, '8M2', 'Economy', 'Middle', 0.00, 1),
(2, '8W', 'Economy', 'Window', 150.00, 1),
(2, '8W2', 'Economy', 'Window', 150.00, 1),
(2, '9A', 'Economy', 'Aisle', 75.00, 1),
(2, '9A2', 'Economy', 'Aisle', 75.00, 1),
(2, '9M', 'Economy', 'Middle', 0.00, 0),
(2, '9M2', 'Economy', 'Middle', 0.00, 1),
(2, '9W', 'Economy', 'Window', 150.00, 1),
(2, '9W2', 'Economy', 'Window', 150.00, 1),
(3, '10A', 'Economy', 'Aisle', 200.00, 1),
(3, '10A2', 'Economy', 'Aisle', 200.00, 1),
(3, '10M', 'Economy', 'Middle', 0.00, 1),
(3, '10M2', 'Economy', 'Middle', 0.00, 1),
(3, '10W', 'Economy', 'Window', 500.00, 1),
(3, '10W2', 'Economy', 'Window', 500.00, 1),
(3, '11A', 'Economy', 'Aisle', 200.00, 0),
(3, '11A2', 'Economy', 'Aisle', 200.00, 1),
(3, '11M', 'Economy', 'Middle', 0.00, 1),
(3, '11M2', 'Economy', 'Middle', 0.00, 1),
(3, '11W', 'Economy', 'Window', 500.00, 1),
(3, '11W2', 'Economy', 'Window', 500.00, 1),
(3, '12A', 'Economy', 'Aisle', 200.00, 1),
(3, '12A2', 'Economy', 'Aisle', 200.00, 1),
(3, '12M', 'Economy', 'Middle', 0.00, 1),
(3, '12M2', 'Economy', 'Middle', 0.00, 0),
(3, '12W', 'Economy', 'Window', 500.00, 1),
(3, '12W2', 'Economy', 'Window', 500.00, 1),
(3, '13A', 'Economy', 'Aisle', 200.00, 1),
(3, '13A2', 'Economy', 'Aisle', 200.00, 1),
(3, '13M', 'Economy', 'Middle', 0.00, 0),
(3, '13M2', 'Economy', 'Middle', 0.00, 1),
(3, '13W', 'Economy', 'Window', 500.00, 1),
(3, '13W2', 'Economy', 'Window', 500.00, 1),
(3, '14A', 'Economy', 'Aisle', 200.00, 1),
(3, '14A2', 'Economy', 'Aisle', 200.00, 1),
(3, '14M', 'Economy', 'Middle', 0.00, 1),
(3, '14M2', 'Economy', 'Middle', 0.00, 0),
(3, '14W', 'Economy', 'Window', 500.00, 1),
(3, '14W2', 'Economy', 'Window', 500.00, 1),
(3, '15A', 'Economy', 'Aisle', 200.00, 1),
(3, '15A2', 'Economy', 'Aisle', 200.00, 0),
(3, '15M', 'Economy', 'Middle', 0.00, 1),
(3, '15M2', 'Economy', 'Middle', 0.00, 1),
(3, '15W', 'Economy', 'Window', 500.00, 0),
(3, '15W2', 'Economy', 'Window', 500.00, 1),
(3, '16A', 'Economy', 'Aisle', 200.00, 1),
(3, '16A2', 'Economy', 'Aisle', 200.00, 1),
(3, '16M', 'Economy', 'Middle', 0.00, 1),
(3, '16M2', 'Economy', 'Middle', 0.00, 1),
(3, '16W', 'Economy', 'Window', 500.00, 1),
(3, '16W2', 'Economy', 'Window', 500.00, 1),
(3, '17A', 'Economy', 'Aisle', 200.00, 1),
(3, '17A2', 'Economy', 'Aisle', 200.00, 0),
(3, '17M', 'Economy', 'Middle', 0.00, 1),
(3, '17M2', 'Economy', 'Middle', 0.00, 1),
(3, '17W', 'Economy', 'Window', 500.00, 1),
(3, '17W2', 'Economy', 'Window', 500.00, 1),
(3, '18A', 'Economy', 'Aisle', 200.00, 1),
(3, '18A2', 'Economy', 'Aisle', 200.00, 1),
(3, '18M', 'Economy', 'Middle', 0.00, 1),
(3, '18M2', 'Economy', 'Middle', 0.00, 1),
(3, '18W', 'Economy', 'Window', 500.00, 1),
(3, '18W2', 'Economy', 'Window', 500.00, 1),
(3, '19A', 'Economy', 'Aisle', 200.00, 1),
(3, '19A2', 'Economy', 'Aisle', 200.00, 1),
(3, '19M', 'Economy', 'Middle', 0.00, 1),
(3, '19M2', 'Economy', 'Middle', 0.00, 1),
(3, '19W', 'Economy', 'Window', 500.00, 1),
(3, '19W2', 'Economy', 'Window', 500.00, 1),
(3, '1A', 'First', 'Aisle', 200.00, 1),
(3, '1W', 'First', 'Window', 500.00, 1),
(3, '20A', 'Economy', 'Aisle', 200.00, 1),
(3, '20A2', 'Economy', 'Aisle', 200.00, 1),
(3, '20M', 'Economy', 'Middle', 0.00, 0),
(3, '20M2', 'Economy', 'Middle', 0.00, 1),
(3, '20W', 'Economy', 'Window', 500.00, 1),
(3, '20W2', 'Economy', 'Window', 500.00, 1),
(3, '21A', 'Economy', 'Aisle', 200.00, 1),
(3, '21A2', 'Economy', 'Aisle', 200.00, 1),
(3, '21M', 'Economy', 'Middle', 0.00, 1),
(3, '21M2', 'Economy', 'Middle', 0.00, 1),
(3, '21W', 'Economy', 'Window', 500.00, 0),
(3, '21W2', 'Economy', 'Window', 500.00, 1),
(3, '22A', 'Economy', 'Aisle', 200.00, 1),
(3, '22A2', 'Economy', 'Aisle', 200.00, 1),
(3, '22M', 'Economy', 'Middle', 0.00, 0),
(3, '22M2', 'Economy', 'Middle', 0.00, 0),
(3, '22W', 'Economy', 'Window', 500.00, 1),
(3, '22W2', 'Economy', 'Window', 500.00, 1),
(3, '2A', 'Business', 'Aisle', 200.00, 1),
(3, '2W', 'Business', 'Window', 500.00, 0),
(3, '3A', 'Business', 'Aisle', 200.00, 1),
(3, '3W', 'Business', 'Window', 500.00, 1),
(3, '4A', 'Economy', 'Aisle', 200.00, 1),
(3, '4A2', 'Economy', 'Aisle', 200.00, 0),
(3, '4M', 'Economy', 'Middle', 0.00, 0),
(3, '4M2', 'Economy', 'Middle', 0.00, 1),
(3, '4W', 'Economy', 'Window', 500.00, 1),
(3, '4W2', 'Economy', 'Window', 500.00, 1),
(3, '5A', 'Economy', 'Aisle', 200.00, 0),
(3, '5A2', 'Economy', 'Aisle', 200.00, 1),
(3, '5M', 'Economy', 'Middle', 0.00, 0),
(3, '5M2', 'Economy', 'Middle', 0.00, 1),
(3, '5W', 'Economy', 'Window', 500.00, 1),
(3, '5W2', 'Economy', 'Window', 500.00, 0),
(3, '6A', 'Economy', 'Aisle', 200.00, 1),
(3, '6A2', 'Economy', 'Aisle', 200.00, 1),
(3, '6M', 'Economy', 'Middle', 0.00, 1),
(3, '6M2', 'Economy', 'Middle', 0.00, 1),
(3, '6W', 'Economy', 'Window', 500.00, 1),
(3, '6W2', 'Economy', 'Window', 500.00, 1),
(3, '7A', 'Economy', 'Aisle', 200.00, 0),
(3, '7A2', 'Economy', 'Aisle', 200.00, 1),
(3, '7M', 'Economy', 'Middle', 0.00, 0),
(3, '7M2', 'Economy', 'Middle', 0.00, 0),
(3, '7W', 'Economy', 'Window', 500.00, 0),
(3, '7W2', 'Economy', 'Window', 500.00, 0),
(3, '8A', 'Economy', 'Aisle', 200.00, 1),
(3, '8A2', 'Economy', 'Aisle', 200.00, 0),
(3, '8M', 'Economy', 'Middle', 0.00, 0),
(3, '8M2', 'Economy', 'Middle', 0.00, 1),
(3, '8W', 'Economy', 'Window', 500.00, 1),
(3, '8W2', 'Economy', 'Window', 500.00, 1),
(3, '9A', 'Economy', 'Aisle', 200.00, 1),
(3, '9A2', 'Economy', 'Aisle', 200.00, 1),
(3, '9M', 'Economy', 'Middle', 0.00, 0),
(3, '9M2', 'Economy', 'Middle', 0.00, 0),
(3, '9W', 'Economy', 'Window', 500.00, 0),
(3, '9W2', 'Economy', 'Window', 500.00, 1),
(4, '10A', 'Economy', 'Aisle', 200.00, 1),
(4, '10A2', 'Economy', 'Aisle', 200.00, 1),
(4, '10M', 'Economy', 'Middle', 0.00, 0),
(4, '10M2', 'Economy', 'Middle', 0.00, 1),
(4, '10W', 'Economy', 'Window', 500.00, 1),
(4, '10W2', 'Economy', 'Window', 500.00, 1),
(4, '11A', 'Economy', 'Aisle', 200.00, 1),
(4, '11A2', 'Economy', 'Aisle', 200.00, 0),
(4, '11M', 'Economy', 'Middle', 0.00, 0),
(4, '11M2', 'Economy', 'Middle', 0.00, 1),
(4, '11W', 'Economy', 'Window', 500.00, 1),
(4, '11W2', 'Economy', 'Window', 500.00, 1),
(4, '12A', 'Economy', 'Aisle', 200.00, 1),
(4, '12A2', 'Economy', 'Aisle', 200.00, 0),
(4, '12M', 'Economy', 'Middle', 0.00, 1),
(4, '12M2', 'Economy', 'Middle', 0.00, 1),
(4, '12W', 'Economy', 'Window', 500.00, 1),
(4, '12W2', 'Economy', 'Window', 500.00, 1),
(4, '13A', 'Economy', 'Aisle', 200.00, 1),
(4, '13A2', 'Economy', 'Aisle', 200.00, 1),
(4, '13M', 'Economy', 'Middle', 0.00, 1),
(4, '13M2', 'Economy', 'Middle', 0.00, 1),
(4, '13W', 'Economy', 'Window', 500.00, 1),
(4, '13W2', 'Economy', 'Window', 500.00, 1),
(4, '14A', 'Economy', 'Aisle', 200.00, 0),
(4, '14A2', 'Economy', 'Aisle', 200.00, 0),
(4, '14M', 'Economy', 'Middle', 0.00, 1),
(4, '14M2', 'Economy', 'Middle', 0.00, 1),
(4, '14W', 'Economy', 'Window', 500.00, 1),
(4, '14W2', 'Economy', 'Window', 500.00, 1),
(4, '15A', 'Economy', 'Aisle', 200.00, 1),
(4, '15A2', 'Economy', 'Aisle', 200.00, 0),
(4, '15M', 'Economy', 'Middle', 0.00, 1),
(4, '15M2', 'Economy', 'Middle', 0.00, 1),
(4, '15W', 'Economy', 'Window', 500.00, 0),
(4, '15W2', 'Economy', 'Window', 500.00, 1),
(4, '16A', 'Economy', 'Aisle', 200.00, 1),
(4, '16A2', 'Economy', 'Aisle', 200.00, 1),
(4, '16M', 'Economy', 'Middle', 0.00, 0),
(4, '16M2', 'Economy', 'Middle', 0.00, 1),
(4, '16W', 'Economy', 'Window', 500.00, 1),
(4, '16W2', 'Economy', 'Window', 500.00, 1),
(4, '17A', 'Economy', 'Aisle', 200.00, 1),
(4, '17A2', 'Economy', 'Aisle', 200.00, 1),
(4, '17M', 'Economy', 'Middle', 0.00, 1),
(4, '17M2', 'Economy', 'Middle', 0.00, 0),
(4, '17W', 'Economy', 'Window', 500.00, 1),
(4, '17W2', 'Economy', 'Window', 500.00, 0),
(4, '18A', 'Economy', 'Aisle', 200.00, 1),
(4, '18A2', 'Economy', 'Aisle', 200.00, 0),
(4, '18M', 'Economy', 'Middle', 0.00, 1),
(4, '18M2', 'Economy', 'Middle', 0.00, 0),
(4, '18W', 'Economy', 'Window', 500.00, 1),
(4, '18W2', 'Economy', 'Window', 500.00, 1),
(4, '19A', 'Economy', 'Aisle', 200.00, 0),
(4, '19A2', 'Economy', 'Aisle', 200.00, 1),
(4, '19M', 'Economy', 'Middle', 0.00, 1),
(4, '19M2', 'Economy', 'Middle', 0.00, 1),
(4, '19W', 'Economy', 'Window', 500.00, 1),
(4, '19W2', 'Economy', 'Window', 500.00, 1),
(4, '1A', 'First', 'Aisle', 200.00, 1),
(4, '1W', 'First', 'Window', 500.00, 0),
(4, '20A', 'Economy', 'Aisle', 200.00, 1),
(4, '20A2', 'Economy', 'Aisle', 200.00, 0),
(4, '20M', 'Economy', 'Middle', 0.00, 0),
(4, '20M2', 'Economy', 'Middle', 0.00, 0),
(4, '20W', 'Economy', 'Window', 500.00, 0),
(4, '20W2', 'Economy', 'Window', 500.00, 1),
(4, '21A', 'Economy', 'Aisle', 200.00, 1),
(4, '21A2', 'Economy', 'Aisle', 200.00, 1),
(4, '21M', 'Economy', 'Middle', 0.00, 1),
(4, '21M2', 'Economy', 'Middle', 0.00, 1),
(4, '21W', 'Economy', 'Window', 500.00, 0),
(4, '21W2', 'Economy', 'Window', 500.00, 1),
(4, '22A', 'Economy', 'Aisle', 200.00, 1),
(4, '22A2', 'Economy', 'Aisle', 200.00, 1),
(4, '22M', 'Economy', 'Middle', 0.00, 1),
(4, '22M2', 'Economy', 'Middle', 0.00, 1),
(4, '22W', 'Economy', 'Window', 500.00, 1),
(4, '22W2', 'Economy', 'Window', 500.00, 1),
(4, '2A', 'First', 'Aisle', 200.00, 1),
(4, '2W', 'First', 'Window', 500.00, 1),
(4, '3A', 'Business', 'Aisle', 200.00, 1),
(4, '3W', 'Business', 'Window', 500.00, 1),
(4, '4A', 'Business', 'Aisle', 200.00, 1),
(4, '4W', 'Business', 'Window', 500.00, 0),
(4, '5A', 'Business', 'Aisle', 200.00, 1),
(4, '5W', 'Business', 'Window', 500.00, 1),
(4, '6A', 'Economy', 'Aisle', 200.00, 1),
(4, '6A2', 'Economy', 'Aisle', 200.00, 1),
(4, '6M', 'Economy', 'Middle', 0.00, 1),
(4, '6M2', 'Economy', 'Middle', 0.00, 1),
(4, '6W', 'Economy', 'Window', 500.00, 1),
(4, '6W2', 'Economy', 'Window', 500.00, 1),
(4, '7A', 'Economy', 'Aisle', 200.00, 0),
(4, '7A2', 'Economy', 'Aisle', 200.00, 1),
(4, '7M', 'Economy', 'Middle', 0.00, 1),
(4, '7M2', 'Economy', 'Middle', 0.00, 1),
(4, '7W', 'Economy', 'Window', 500.00, 1),
(4, '7W2', 'Economy', 'Window', 500.00, 1),
(4, '8A', 'Economy', 'Aisle', 200.00, 1),
(4, '8A2', 'Economy', 'Aisle', 200.00, 0),
(4, '8M', 'Economy', 'Middle', 0.00, 1),
(4, '8M2', 'Economy', 'Middle', 0.00, 1),
(4, '8W', 'Economy', 'Window', 500.00, 0),
(4, '8W2', 'Economy', 'Window', 500.00, 1),
(4, '9A', 'Economy', 'Aisle', 200.00, 1),
(4, '9A2', 'Economy', 'Aisle', 200.00, 1),
(4, '9M', 'Economy', 'Middle', 0.00, 1),
(4, '9M2', 'Economy', 'Middle', 0.00, 0),
(4, '9W', 'Economy', 'Window', 500.00, 1),
(4, '9W2', 'Economy', 'Window', 500.00, 0),
(5, '10A', 'Economy', 'Aisle', 75.00, 1),
(5, '10A2', 'Economy', 'Aisle', 75.00, 1),
(5, '10M', 'Economy', 'Middle', 0.00, 1),
(5, '10M2', 'Economy', 'Middle', 0.00, 0),
(5, '10W', 'Economy', 'Window', 150.00, 0),
(5, '10W2', 'Economy', 'Window', 150.00, 0),
(5, '11A', 'Economy', 'Aisle', 75.00, 0),
(5, '11A2', 'Economy', 'Aisle', 75.00, 1),
(5, '11M', 'Economy', 'Middle', 0.00, 0),
(5, '11M2', 'Economy', 'Middle', 0.00, 1),
(5, '11W', 'Economy', 'Window', 150.00, 1),
(5, '11W2', 'Economy', 'Window', 150.00, 0),
(5, '12A', 'Economy', 'Aisle', 75.00, 0),
(5, '12A2', 'Economy', 'Aisle', 75.00, 0),
(5, '12M', 'Economy', 'Middle', 0.00, 1),
(5, '12M2', 'Economy', 'Middle', 0.00, 1),
(5, '12W', 'Economy', 'Window', 150.00, 0),
(5, '12W2', 'Economy', 'Window', 150.00, 1),
(5, '13A', 'Economy', 'Aisle', 75.00, 0),
(5, '13A2', 'Economy', 'Aisle', 75.00, 1),
(5, '13M', 'Economy', 'Middle', 0.00, 0),
(5, '13M2', 'Economy', 'Middle', 0.00, 0),
(5, '13W', 'Economy', 'Window', 150.00, 1),
(5, '13W2', 'Economy', 'Window', 150.00, 1),
(5, '14A', 'Economy', 'Aisle', 75.00, 0),
(5, '14A2', 'Economy', 'Aisle', 75.00, 1),
(5, '14M', 'Economy', 'Middle', 0.00, 0),
(5, '14M2', 'Economy', 'Middle', 0.00, 0),
(5, '14W', 'Economy', 'Window', 150.00, 1),
(5, '14W2', 'Economy', 'Window', 150.00, 1),
(5, '15A', 'Economy', 'Aisle', 75.00, 0),
(5, '15A2', 'Economy', 'Aisle', 75.00, 1),
(5, '15M', 'Economy', 'Middle', 0.00, 1),
(5, '15M2', 'Economy', 'Middle', 0.00, 1),
(5, '15W', 'Economy', 'Window', 150.00, 0),
(5, '15W2', 'Economy', 'Window', 150.00, 0),
(5, '1A', 'Business', 'Aisle', 75.00, 1),
(5, '1W', 'Business', 'Window', 150.00, 0),
(5, '2A', 'Economy', 'Aisle', 75.00, 0),
(5, '2A2', 'Economy', 'Aisle', 75.00, 1),
(5, '2M', 'Economy', 'Middle', 0.00, 0),
(5, '2M2', 'Economy', 'Middle', 0.00, 0),
(5, '2W', 'Economy', 'Window', 150.00, 1),
(5, '2W2', 'Economy', 'Window', 150.00, 0),
(5, '3A', 'Economy', 'Aisle', 75.00, 0),
(5, '3A2', 'Economy', 'Aisle', 75.00, 0),
(5, '3M', 'Economy', 'Middle', 0.00, 0),
(5, '3M2', 'Economy', 'Middle', 0.00, 1),
(5, '3W', 'Economy', 'Window', 150.00, 1),
(5, '3W2', 'Economy', 'Window', 150.00, 1),
(5, '4A', 'Economy', 'Aisle', 75.00, 0),
(5, '4A2', 'Economy', 'Aisle', 75.00, 1),
(5, '4M', 'Economy', 'Middle', 0.00, 1),
(5, '4M2', 'Economy', 'Middle', 0.00, 1),
(5, '4W', 'Economy', 'Window', 150.00, 1),
(5, '4W2', 'Economy', 'Window', 150.00, 0),
(5, '5A', 'Economy', 'Aisle', 75.00, 1),
(5, '5A2', 'Economy', 'Aisle', 75.00, 0),
(5, '5M', 'Economy', 'Middle', 0.00, 1),
(5, '5M2', 'Economy', 'Middle', 0.00, 1),
(5, '5W', 'Economy', 'Window', 150.00, 1),
(5, '5W2', 'Economy', 'Window', 150.00, 0),
(5, '6A', 'Economy', 'Aisle', 75.00, 0),
(5, '6A2', 'Economy', 'Aisle', 75.00, 0),
(5, '6M', 'Economy', 'Middle', 0.00, 0),
(5, '6M2', 'Economy', 'Middle', 0.00, 1),
(5, '6W', 'Economy', 'Window', 150.00, 1),
(5, '6W2', 'Economy', 'Window', 150.00, 0),
(5, '7A', 'Economy', 'Aisle', 75.00, 1),
(5, '7A2', 'Economy', 'Aisle', 75.00, 1),
(5, '7M', 'Economy', 'Middle', 0.00, 1),
(5, '7M2', 'Economy', 'Middle', 0.00, 0),
(5, '7W', 'Economy', 'Window', 150.00, 0),
(5, '7W2', 'Economy', 'Window', 150.00, 1),
(5, '8A', 'Economy', 'Aisle', 75.00, 1),
(5, '8A2', 'Economy', 'Aisle', 75.00, 1),
(5, '8M', 'Economy', 'Middle', 0.00, 0),
(5, '8M2', 'Economy', 'Middle', 0.00, 1),
(5, '8W', 'Economy', 'Window', 150.00, 1),
(5, '8W2', 'Economy', 'Window', 150.00, 1),
(5, '9A', 'Economy', 'Aisle', 75.00, 1),
(5, '9A2', 'Economy', 'Aisle', 75.00, 1),
(5, '9M', 'Economy', 'Middle', 0.00, 1),
(5, '9M2', 'Economy', 'Middle', 0.00, 1),
(5, '9W', 'Economy', 'Window', 150.00, 1),
(5, '9W2', 'Economy', 'Window', 150.00, 1),
(6, '10A', 'Economy', 'Aisle', 75.00, 1),
(6, '10A2', 'Economy', 'Aisle', 75.00, 1),
(6, '10M', 'Economy', 'Middle', 0.00, 1),
(6, '10M2', 'Economy', 'Middle', 0.00, 1),
(6, '10W', 'Economy', 'Window', 150.00, 1),
(6, '10W2', 'Economy', 'Window', 150.00, 1),
(6, '11A', 'Economy', 'Aisle', 75.00, 0),
(6, '11A2', 'Economy', 'Aisle', 75.00, 1),
(6, '11M', 'Economy', 'Middle', 0.00, 1),
(6, '11M2', 'Economy', 'Middle', 0.00, 1),
(6, '11W', 'Economy', 'Window', 150.00, 1),
(6, '11W2', 'Economy', 'Window', 150.00, 1),
(6, '12A', 'Economy', 'Aisle', 75.00, 0),
(6, '12A2', 'Economy', 'Aisle', 75.00, 1),
(6, '12M', 'Economy', 'Middle', 0.00, 0),
(6, '12M2', 'Economy', 'Middle', 0.00, 0),
(6, '12W', 'Economy', 'Window', 150.00, 1),
(6, '12W2', 'Economy', 'Window', 150.00, 1),
(6, '13A', 'Economy', 'Aisle', 75.00, 0),
(6, '13A2', 'Economy', 'Aisle', 75.00, 1),
(6, '13M', 'Economy', 'Middle', 0.00, 1),
(6, '13M2', 'Economy', 'Middle', 0.00, 1),
(6, '13W', 'Economy', 'Window', 150.00, 0),
(6, '13W2', 'Economy', 'Window', 150.00, 0),
(6, '14A', 'Economy', 'Aisle', 75.00, 1),
(6, '14A2', 'Economy', 'Aisle', 75.00, 1),
(6, '14M', 'Economy', 'Middle', 0.00, 0),
(6, '14M2', 'Economy', 'Middle', 0.00, 1),
(6, '14W', 'Economy', 'Window', 150.00, 0),
(6, '14W2', 'Economy', 'Window', 150.00, 1),
(6, '15A', 'Economy', 'Aisle', 75.00, 1),
(6, '15A2', 'Economy', 'Aisle', 75.00, 0),
(6, '15M', 'Economy', 'Middle', 0.00, 0),
(6, '15M2', 'Economy', 'Middle', 0.00, 0),
(6, '15W', 'Economy', 'Window', 150.00, 1),
(6, '15W2', 'Economy', 'Window', 150.00, 1),
(6, '1A', 'Business', 'Aisle', 75.00, 0),
(6, '1W', 'Business', 'Window', 150.00, 1),
(6, '2A', 'Economy', 'Aisle', 75.00, 0),
(6, '2A2', 'Economy', 'Aisle', 75.00, 1),
(6, '2M', 'Economy', 'Middle', 0.00, 1),
(6, '2M2', 'Economy', 'Middle', 0.00, 0),
(6, '2W', 'Economy', 'Window', 150.00, 0),
(6, '2W2', 'Economy', 'Window', 150.00, 1),
(6, '3A', 'Economy', 'Aisle', 75.00, 0),
(6, '3A2', 'Economy', 'Aisle', 75.00, 1),
(6, '3M', 'Economy', 'Middle', 0.00, 1),
(6, '3M2', 'Economy', 'Middle', 0.00, 1),
(6, '3W', 'Economy', 'Window', 150.00, 1),
(6, '3W2', 'Economy', 'Window', 150.00, 0),
(6, '4A', 'Economy', 'Aisle', 75.00, 0),
(6, '4A2', 'Economy', 'Aisle', 75.00, 1),
(6, '4M', 'Economy', 'Middle', 0.00, 1),
(6, '4M2', 'Economy', 'Middle', 0.00, 0),
(6, '4W', 'Economy', 'Window', 150.00, 1),
(6, '4W2', 'Economy', 'Window', 150.00, 1),
(6, '5A', 'Economy', 'Aisle', 75.00, 1),
(6, '5A2', 'Economy', 'Aisle', 75.00, 1),
(6, '5M', 'Economy', 'Middle', 0.00, 0),
(6, '5M2', 'Economy', 'Middle', 0.00, 1),
(6, '5W', 'Economy', 'Window', 150.00, 1),
(6, '5W2', 'Economy', 'Window', 150.00, 1),
(6, '6A', 'Economy', 'Aisle', 75.00, 1),
(6, '6A2', 'Economy', 'Aisle', 75.00, 1),
(6, '6M', 'Economy', 'Middle', 0.00, 1),
(6, '6M2', 'Economy', 'Middle', 0.00, 1),
(6, '6W', 'Economy', 'Window', 150.00, 1),
(6, '6W2', 'Economy', 'Window', 150.00, 1),
(6, '7A', 'Economy', 'Aisle', 75.00, 1),
(6, '7A2', 'Economy', 'Aisle', 75.00, 0),
(6, '7M', 'Economy', 'Middle', 0.00, 1),
(6, '7M2', 'Economy', 'Middle', 0.00, 1),
(6, '7W', 'Economy', 'Window', 150.00, 1),
(6, '7W2', 'Economy', 'Window', 150.00, 1),
(6, '8A', 'Economy', 'Aisle', 75.00, 1),
(6, '8A2', 'Economy', 'Aisle', 75.00, 1),
(6, '8M', 'Economy', 'Middle', 0.00, 1),
(6, '8M2', 'Economy', 'Middle', 0.00, 1),
(6, '8W', 'Economy', 'Window', 150.00, 0),
(6, '8W2', 'Economy', 'Window', 150.00, 1),
(6, '9A', 'Economy', 'Aisle', 75.00, 1),
(6, '9A2', 'Economy', 'Aisle', 75.00, 1),
(6, '9M', 'Economy', 'Middle', 0.00, 1),
(6, '9M2', 'Economy', 'Middle', 0.00, 0),
(6, '9W', 'Economy', 'Window', 150.00, 1),
(6, '9W2', 'Economy', 'Window', 150.00, 0),
(7, '10A', 'Economy', 'Aisle', 100.00, 1),
(7, '10A2', 'Economy', 'Aisle', 100.00, 1),
(7, '10M', 'Economy', 'Middle', 0.00, 1),
(7, '10M2', 'Economy', 'Middle', 0.00, 1),
(7, '10W', 'Economy', 'Window', 250.00, 1),
(7, '10W2', 'Economy', 'Window', 250.00, 1),
(7, '11A', 'Economy', 'Aisle', 100.00, 1),
(7, '11A2', 'Economy', 'Aisle', 100.00, 1),
(7, '11M', 'Economy', 'Middle', 0.00, 1),
(7, '11M2', 'Economy', 'Middle', 0.00, 1),
(7, '11W', 'Economy', 'Window', 250.00, 1),
(7, '11W2', 'Economy', 'Window', 250.00, 1),
(7, '12A', 'Economy', 'Aisle', 100.00, 1),
(7, '12A2', 'Economy', 'Aisle', 100.00, 0),
(7, '12M', 'Economy', 'Middle', 0.00, 1),
(7, '12M2', 'Economy', 'Middle', 0.00, 1),
(7, '12W', 'Economy', 'Window', 250.00, 1),
(7, '12W2', 'Economy', 'Window', 250.00, 1),
(7, '13A', 'Economy', 'Aisle', 100.00, 0),
(7, '13A2', 'Economy', 'Aisle', 100.00, 0),
(7, '13M', 'Economy', 'Middle', 0.00, 0),
(7, '13M2', 'Economy', 'Middle', 0.00, 1),
(7, '13W', 'Economy', 'Window', 250.00, 1),
(7, '13W2', 'Economy', 'Window', 250.00, 1),
(7, '14A', 'Economy', 'Aisle', 100.00, 0),
(7, '14A2', 'Economy', 'Aisle', 100.00, 1),
(7, '14M', 'Economy', 'Middle', 0.00, 1),
(7, '14M2', 'Economy', 'Middle', 0.00, 1),
(7, '14W', 'Economy', 'Window', 250.00, 1),
(7, '14W2', 'Economy', 'Window', 250.00, 0),
(7, '15A', 'Economy', 'Aisle', 100.00, 1),
(7, '15A2', 'Economy', 'Aisle', 100.00, 1),
(7, '15M', 'Economy', 'Middle', 0.00, 1),
(7, '15M2', 'Economy', 'Middle', 0.00, 1),
(7, '15W', 'Economy', 'Window', 250.00, 0),
(7, '15W2', 'Economy', 'Window', 250.00, 1),
(7, '1A', 'Business', 'Aisle', 100.00, 0),
(7, '1W', 'Business', 'Window', 250.00, 1),
(7, '2A', 'Economy', 'Aisle', 100.00, 1),
(7, '2A2', 'Economy', 'Aisle', 100.00, 1),
(7, '2M', 'Economy', 'Middle', 0.00, 0),
(7, '2M2', 'Economy', 'Middle', 0.00, 0),
(7, '2W', 'Economy', 'Window', 250.00, 0),
(7, '2W2', 'Economy', 'Window', 250.00, 1),
(7, '3A', 'Economy', 'Aisle', 100.00, 1),
(7, '3A2', 'Economy', 'Aisle', 100.00, 1),
(7, '3M', 'Economy', 'Middle', 0.00, 1),
(7, '3M2', 'Economy', 'Middle', 0.00, 1),
(7, '3W', 'Economy', 'Window', 250.00, 1),
(7, '3W2', 'Economy', 'Window', 250.00, 1),
(7, '4A', 'Economy', 'Aisle', 100.00, 1),
(7, '4A2', 'Economy', 'Aisle', 100.00, 0),
(7, '4M', 'Economy', 'Middle', 0.00, 1),
(7, '4M2', 'Economy', 'Middle', 0.00, 0),
(7, '4W', 'Economy', 'Window', 250.00, 1),
(7, '4W2', 'Economy', 'Window', 250.00, 1),
(7, '5A', 'Economy', 'Aisle', 100.00, 0),
(7, '5A2', 'Economy', 'Aisle', 100.00, 1),
(7, '5M', 'Economy', 'Middle', 0.00, 0),
(7, '5M2', 'Economy', 'Middle', 0.00, 1),
(7, '5W', 'Economy', 'Window', 250.00, 0),
(7, '5W2', 'Economy', 'Window', 250.00, 1),
(7, '6A', 'Economy', 'Aisle', 100.00, 1),
(7, '6A2', 'Economy', 'Aisle', 100.00, 1),
(7, '6M', 'Economy', 'Middle', 0.00, 0),
(7, '6M2', 'Economy', 'Middle', 0.00, 1),
(7, '6W', 'Economy', 'Window', 250.00, 1),
(7, '6W2', 'Economy', 'Window', 250.00, 0),
(7, '7A', 'Economy', 'Aisle', 100.00, 1),
(7, '7A2', 'Economy', 'Aisle', 100.00, 1),
(7, '7M', 'Economy', 'Middle', 0.00, 0),
(7, '7M2', 'Economy', 'Middle', 0.00, 0),
(7, '7W', 'Economy', 'Window', 250.00, 1),
(7, '7W2', 'Economy', 'Window', 250.00, 1),
(7, '8A', 'Economy', 'Aisle', 100.00, 1),
(7, '8A2', 'Economy', 'Aisle', 100.00, 1),
(7, '8M', 'Economy', 'Middle', 0.00, 1),
(7, '8M2', 'Economy', 'Middle', 0.00, 1),
(7, '8W', 'Economy', 'Window', 250.00, 1),
(7, '8W2', 'Economy', 'Window', 250.00, 1),
(7, '9A', 'Economy', 'Aisle', 100.00, 1),
(7, '9A2', 'Economy', 'Aisle', 100.00, 1),
(7, '9M', 'Economy', 'Middle', 0.00, 1),
(7, '9M2', 'Economy', 'Middle', 0.00, 0),
(7, '9W', 'Economy', 'Window', 250.00, 1),
(7, '9W2', 'Economy', 'Window', 250.00, 1),
(8, '10A', 'Economy', 'Aisle', 200.00, 1),
(8, '10A2', 'Economy', 'Aisle', 200.00, 1),
(8, '10M', 'Economy', 'Middle', 0.00, 1),
(8, '10M2', 'Economy', 'Middle', 0.00, 1),
(8, '10W', 'Economy', 'Window', 500.00, 0),
(8, '10W2', 'Economy', 'Window', 500.00, 1),
(8, '11A', 'Economy', 'Aisle', 200.00, 1),
(8, '11A2', 'Economy', 'Aisle', 200.00, 1),
(8, '11M', 'Economy', 'Middle', 0.00, 1),
(8, '11M2', 'Economy', 'Middle', 0.00, 1),
(8, '11W', 'Economy', 'Window', 500.00, 1),
(8, '11W2', 'Economy', 'Window', 500.00, 0),
(8, '12A', 'Economy', 'Aisle', 200.00, 0),
(8, '12A2', 'Economy', 'Aisle', 200.00, 1),
(8, '12M', 'Economy', 'Middle', 0.00, 1),
(8, '12M2', 'Economy', 'Middle', 0.00, 0),
(8, '12W', 'Economy', 'Window', 500.00, 1),
(8, '12W2', 'Economy', 'Window', 500.00, 0),
(8, '13A', 'Economy', 'Aisle', 200.00, 1),
(8, '13A2', 'Economy', 'Aisle', 200.00, 1),
(8, '13M', 'Economy', 'Middle', 0.00, 1),
(8, '13M2', 'Economy', 'Middle', 0.00, 0),
(8, '13W', 'Economy', 'Window', 500.00, 0),
(8, '13W2', 'Economy', 'Window', 500.00, 1),
(8, '14A', 'Economy', 'Aisle', 200.00, 1),
(8, '14A2', 'Economy', 'Aisle', 200.00, 1),
(8, '14M', 'Economy', 'Middle', 0.00, 1),
(8, '14M2', 'Economy', 'Middle', 0.00, 1),
(8, '14W', 'Economy', 'Window', 500.00, 1),
(8, '14W2', 'Economy', 'Window', 500.00, 1),
(8, '15A', 'Economy', 'Aisle', 200.00, 0),
(8, '15A2', 'Economy', 'Aisle', 200.00, 1),
(8, '15M', 'Economy', 'Middle', 0.00, 0),
(8, '15M2', 'Economy', 'Middle', 0.00, 1),
(8, '15W', 'Economy', 'Window', 500.00, 1),
(8, '15W2', 'Economy', 'Window', 500.00, 0),
(8, '16A', 'Economy', 'Aisle', 200.00, 1),
(8, '16A2', 'Economy', 'Aisle', 200.00, 0),
(8, '16M', 'Economy', 'Middle', 0.00, 0),
(8, '16M2', 'Economy', 'Middle', 0.00, 1),
(8, '16W', 'Economy', 'Window', 500.00, 0),
(8, '16W2', 'Economy', 'Window', 500.00, 1),
(8, '17A', 'Economy', 'Aisle', 200.00, 1),
(8, '17A2', 'Economy', 'Aisle', 200.00, 0),
(8, '17M', 'Economy', 'Middle', 0.00, 1),
(8, '17M2', 'Economy', 'Middle', 0.00, 1),
(8, '17W', 'Economy', 'Window', 500.00, 1),
(8, '17W2', 'Economy', 'Window', 500.00, 0),
(8, '18A', 'Economy', 'Aisle', 200.00, 0),
(8, '18A2', 'Economy', 'Aisle', 200.00, 1),
(8, '18M', 'Economy', 'Middle', 0.00, 1),
(8, '18M2', 'Economy', 'Middle', 0.00, 0),
(8, '18W', 'Economy', 'Window', 500.00, 1),
(8, '18W2', 'Economy', 'Window', 500.00, 1),
(8, '19A', 'Economy', 'Aisle', 200.00, 1),
(8, '19A2', 'Economy', 'Aisle', 200.00, 1),
(8, '19M', 'Economy', 'Middle', 0.00, 1),
(8, '19M2', 'Economy', 'Middle', 0.00, 0),
(8, '19W', 'Economy', 'Window', 500.00, 1),
(8, '19W2', 'Economy', 'Window', 500.00, 0),
(8, '1A', 'First', 'Aisle', 200.00, 0),
(8, '1W', 'First', 'Window', 500.00, 1),
(8, '20A', 'Economy', 'Aisle', 200.00, 1),
(8, '20A2', 'Economy', 'Aisle', 200.00, 0),
(8, '20M', 'Economy', 'Middle', 0.00, 1),
(8, '20M2', 'Economy', 'Middle', 0.00, 1),
(8, '20W', 'Economy', 'Window', 500.00, 0),
(8, '20W2', 'Economy', 'Window', 500.00, 0),
(8, '21A', 'Economy', 'Aisle', 200.00, 1),
(8, '21A2', 'Economy', 'Aisle', 200.00, 1),
(8, '21M', 'Economy', 'Middle', 0.00, 1),
(8, '21M2', 'Economy', 'Middle', 0.00, 1),
(8, '21W', 'Economy', 'Window', 500.00, 1),
(8, '21W2', 'Economy', 'Window', 500.00, 0),
(8, '22A', 'Economy', 'Aisle', 200.00, 1),
(8, '22A2', 'Economy', 'Aisle', 200.00, 1),
(8, '22M', 'Economy', 'Middle', 0.00, 1),
(8, '22M2', 'Economy', 'Middle', 0.00, 1),
(8, '22W', 'Economy', 'Window', 500.00, 0),
(8, '22W2', 'Economy', 'Window', 500.00, 1),
(8, '2A', 'Business', 'Aisle', 200.00, 1),
(8, '2W', 'Business', 'Window', 500.00, 1),
(8, '3A', 'Business', 'Aisle', 200.00, 0),
(8, '3W', 'Business', 'Window', 500.00, 0),
(8, '4A', 'Business', 'Aisle', 200.00, 0),
(8, '4W', 'Business', 'Window', 500.00, 1),
(8, '5A', 'Economy', 'Aisle', 200.00, 0),
(8, '5A2', 'Economy', 'Aisle', 200.00, 1),
(8, '5M', 'Economy', 'Middle', 0.00, 1),
(8, '5M2', 'Economy', 'Middle', 0.00, 0),
(8, '5W', 'Economy', 'Window', 500.00, 0),
(8, '5W2', 'Economy', 'Window', 500.00, 1),
(8, '6A', 'Economy', 'Aisle', 200.00, 1),
(8, '6A2', 'Economy', 'Aisle', 200.00, 1),
(8, '6M', 'Economy', 'Middle', 0.00, 1),
(8, '6M2', 'Economy', 'Middle', 0.00, 1),
(8, '6W', 'Economy', 'Window', 500.00, 1),
(8, '6W2', 'Economy', 'Window', 500.00, 1),
(8, '7A', 'Economy', 'Aisle', 200.00, 1),
(8, '7A2', 'Economy', 'Aisle', 200.00, 1),
(8, '7M', 'Economy', 'Middle', 0.00, 1),
(8, '7M2', 'Economy', 'Middle', 0.00, 1),
(8, '7W', 'Economy', 'Window', 500.00, 1),
(8, '7W2', 'Economy', 'Window', 500.00, 0),
(8, '8A', 'Economy', 'Aisle', 200.00, 0),
(8, '8A2', 'Economy', 'Aisle', 200.00, 1),
(8, '8M', 'Economy', 'Middle', 0.00, 1),
(8, '8M2', 'Economy', 'Middle', 0.00, 1),
(8, '8W', 'Economy', 'Window', 500.00, 0),
(8, '8W2', 'Economy', 'Window', 500.00, 1),
(8, '9A', 'Economy', 'Aisle', 200.00, 0),
(8, '9A2', 'Economy', 'Aisle', 200.00, 1),
(8, '9M', 'Economy', 'Middle', 0.00, 1),
(8, '9M2', 'Economy', 'Middle', 0.00, 1),
(8, '9W', 'Economy', 'Window', 500.00, 1),
(8, '9W2', 'Economy', 'Window', 500.00, 1),
(9, '10A', 'Economy', 'Aisle', 75.00, 1),
(9, '10A2', 'Economy', 'Aisle', 75.00, 1),
(9, '10M', 'Economy', 'Middle', 0.00, 1),
(9, '10M2', 'Economy', 'Middle', 0.00, 1),
(9, '10W', 'Economy', 'Window', 150.00, 0),
(9, '10W2', 'Economy', 'Window', 150.00, 0),
(9, '11A', 'Economy', 'Aisle', 75.00, 1),
(9, '11A2', 'Economy', 'Aisle', 75.00, 1),
(9, '11M', 'Economy', 'Middle', 0.00, 0),
(9, '11M2', 'Economy', 'Middle', 0.00, 0),
(9, '11W', 'Economy', 'Window', 150.00, 1),
(9, '11W2', 'Economy', 'Window', 150.00, 1),
(9, '12A', 'Economy', 'Aisle', 75.00, 1),
(9, '12A2', 'Economy', 'Aisle', 75.00, 1),
(9, '12M', 'Economy', 'Middle', 0.00, 0),
(9, '12M2', 'Economy', 'Middle', 0.00, 0),
(9, '12W', 'Economy', 'Window', 150.00, 1),
(9, '12W2', 'Economy', 'Window', 150.00, 1),
(9, '13A', 'Economy', 'Aisle', 75.00, 1),
(9, '13A2', 'Economy', 'Aisle', 75.00, 0),
(9, '13M', 'Economy', 'Middle', 0.00, 0),
(9, '13M2', 'Economy', 'Middle', 0.00, 1),
(9, '13W', 'Economy', 'Window', 150.00, 1),
(9, '13W2', 'Economy', 'Window', 150.00, 1),
(9, '14A', 'Economy', 'Aisle', 75.00, 1),
(9, '14A2', 'Economy', 'Aisle', 75.00, 1),
(9, '14M', 'Economy', 'Middle', 0.00, 1),
(9, '14M2', 'Economy', 'Middle', 0.00, 0),
(9, '14W', 'Economy', 'Window', 150.00, 1),
(9, '14W2', 'Economy', 'Window', 150.00, 1),
(9, '15A', 'Economy', 'Aisle', 75.00, 1),
(9, '15A2', 'Economy', 'Aisle', 75.00, 1),
(9, '15M', 'Economy', 'Middle', 0.00, 0),
(9, '15M2', 'Economy', 'Middle', 0.00, 1),
(9, '15W', 'Economy', 'Window', 150.00, 1),
(9, '15W2', 'Economy', 'Window', 150.00, 1),
(9, '1A', 'Business', 'Aisle', 75.00, 1),
(9, '1W', 'Business', 'Window', 150.00, 0),
(9, '2A', 'Economy', 'Aisle', 75.00, 1),
(9, '2A2', 'Economy', 'Aisle', 75.00, 1),
(9, '2M', 'Economy', 'Middle', 0.00, 1),
(9, '2M2', 'Economy', 'Middle', 0.00, 0),
(9, '2W', 'Economy', 'Window', 150.00, 0),
(9, '2W2', 'Economy', 'Window', 150.00, 1),
(9, '3A', 'Economy', 'Aisle', 75.00, 1),
(9, '3A2', 'Economy', 'Aisle', 75.00, 1),
(9, '3M', 'Economy', 'Middle', 0.00, 0),
(9, '3M2', 'Economy', 'Middle', 0.00, 0),
(9, '3W', 'Economy', 'Window', 150.00, 1),
(9, '3W2', 'Economy', 'Window', 150.00, 0),
(9, '4A', 'Economy', 'Aisle', 75.00, 0),
(9, '4A2', 'Economy', 'Aisle', 75.00, 0),
(9, '4M', 'Economy', 'Middle', 0.00, 1),
(9, '4M2', 'Economy', 'Middle', 0.00, 1),
(9, '4W', 'Economy', 'Window', 150.00, 0),
(9, '4W2', 'Economy', 'Window', 150.00, 0),
(9, '5A', 'Economy', 'Aisle', 75.00, 1),
(9, '5A2', 'Economy', 'Aisle', 75.00, 1),
(9, '5M', 'Economy', 'Middle', 0.00, 1),
(9, '5M2', 'Economy', 'Middle', 0.00, 0),
(9, '5W', 'Economy', 'Window', 150.00, 1),
(9, '5W2', 'Economy', 'Window', 150.00, 1),
(9, '6A', 'Economy', 'Aisle', 75.00, 1),
(9, '6A2', 'Economy', 'Aisle', 75.00, 1),
(9, '6M', 'Economy', 'Middle', 0.00, 1),
(9, '6M2', 'Economy', 'Middle', 0.00, 0),
(9, '6W', 'Economy', 'Window', 150.00, 1),
(9, '6W2', 'Economy', 'Window', 150.00, 1),
(9, '7A', 'Economy', 'Aisle', 75.00, 1),
(9, '7A2', 'Economy', 'Aisle', 75.00, 1),
(9, '7M', 'Economy', 'Middle', 0.00, 0),
(9, '7M2', 'Economy', 'Middle', 0.00, 0),
(9, '7W', 'Economy', 'Window', 150.00, 0),
(9, '7W2', 'Economy', 'Window', 150.00, 0),
(9, '8A', 'Economy', 'Aisle', 75.00, 1),
(9, '8A2', 'Economy', 'Aisle', 75.00, 0),
(9, '8M', 'Economy', 'Middle', 0.00, 1),
(9, '8M2', 'Economy', 'Middle', 0.00, 1),
(9, '8W', 'Economy', 'Window', 150.00, 1),
(9, '8W2', 'Economy', 'Window', 150.00, 0),
(9, '9A', 'Economy', 'Aisle', 75.00, 0),
(9, '9A2', 'Economy', 'Aisle', 75.00, 0),
(9, '9M', 'Economy', 'Middle', 0.00, 1),
(9, '9M2', 'Economy', 'Middle', 0.00, 0),
(9, '9W', 'Economy', 'Window', 150.00, 1),
(9, '9W2', 'Economy', 'Window', 150.00, 1),
(10, '10A', 'Economy', 'Aisle', 75.00, 1),
(10, '10A2', 'Economy', 'Aisle', 75.00, 1),
(10, '10M', 'Economy', 'Middle', 0.00, 1),
(10, '10M2', 'Economy', 'Middle', 0.00, 1),
(10, '10W', 'Economy', 'Window', 150.00, 0),
(10, '10W2', 'Economy', 'Window', 150.00, 1),
(10, '11A', 'Economy', 'Aisle', 75.00, 1),
(10, '11A2', 'Economy', 'Aisle', 75.00, 1),
(10, '11M', 'Economy', 'Middle', 0.00, 1),
(10, '11M2', 'Economy', 'Middle', 0.00, 1),
(10, '11W', 'Economy', 'Window', 150.00, 1),
(10, '11W2', 'Economy', 'Window', 150.00, 0),
(10, '12A', 'Economy', 'Aisle', 75.00, 1),
(10, '12A2', 'Economy', 'Aisle', 75.00, 1),
(10, '12M', 'Economy', 'Middle', 0.00, 1),
(10, '12M2', 'Economy', 'Middle', 0.00, 1),
(10, '12W', 'Economy', 'Window', 150.00, 1),
(10, '12W2', 'Economy', 'Window', 150.00, 1),
(10, '13A', 'Economy', 'Aisle', 75.00, 1),
(10, '13A2', 'Economy', 'Aisle', 75.00, 1),
(10, '13M', 'Economy', 'Middle', 0.00, 1),
(10, '13M2', 'Economy', 'Middle', 0.00, 1),
(10, '13W', 'Economy', 'Window', 150.00, 0),
(10, '13W2', 'Economy', 'Window', 150.00, 1),
(10, '14A', 'Economy', 'Aisle', 75.00, 0),
(10, '14A2', 'Economy', 'Aisle', 75.00, 1),
(10, '14M', 'Economy', 'Middle', 0.00, 1),
(10, '14M2', 'Economy', 'Middle', 0.00, 1),
(10, '14W', 'Economy', 'Window', 150.00, 1),
(10, '14W2', 'Economy', 'Window', 150.00, 1),
(10, '15A', 'Economy', 'Aisle', 75.00, 1),
(10, '15A2', 'Economy', 'Aisle', 75.00, 1),
(10, '15M', 'Economy', 'Middle', 0.00, 1),
(10, '15M2', 'Economy', 'Middle', 0.00, 0),
(10, '15W', 'Economy', 'Window', 150.00, 0),
(10, '15W2', 'Economy', 'Window', 150.00, 1),
(10, '1A', 'Business', 'Aisle', 75.00, 1),
(10, '1W', 'Business', 'Window', 150.00, 1),
(10, '2A', 'Economy', 'Aisle', 75.00, 0),
(10, '2A2', 'Economy', 'Aisle', 75.00, 1),
(10, '2M', 'Economy', 'Middle', 0.00, 1),
(10, '2M2', 'Economy', 'Middle', 0.00, 0),
(10, '2W', 'Economy', 'Window', 150.00, 1),
(10, '2W2', 'Economy', 'Window', 150.00, 1),
(10, '3A', 'Economy', 'Aisle', 75.00, 1),
(10, '3A2', 'Economy', 'Aisle', 75.00, 1),
(10, '3M', 'Economy', 'Middle', 0.00, 0),
(10, '3M2', 'Economy', 'Middle', 0.00, 1),
(10, '3W', 'Economy', 'Window', 150.00, 1),
(10, '3W2', 'Economy', 'Window', 150.00, 1),
(10, '4A', 'Economy', 'Aisle', 75.00, 0),
(10, '4A2', 'Economy', 'Aisle', 75.00, 1),
(10, '4M', 'Economy', 'Middle', 0.00, 1),
(10, '4M2', 'Economy', 'Middle', 0.00, 1),
(10, '4W', 'Economy', 'Window', 150.00, 0),
(10, '4W2', 'Economy', 'Window', 150.00, 0),
(10, '5A', 'Economy', 'Aisle', 75.00, 0),
(10, '5A2', 'Economy', 'Aisle', 75.00, 1),
(10, '5M', 'Economy', 'Middle', 0.00, 1),
(10, '5M2', 'Economy', 'Middle', 0.00, 1),
(10, '5W', 'Economy', 'Window', 150.00, 0),
(10, '5W2', 'Economy', 'Window', 150.00, 0),
(10, '6A', 'Economy', 'Aisle', 75.00, 1),
(10, '6A2', 'Economy', 'Aisle', 75.00, 0),
(10, '6M', 'Economy', 'Middle', 0.00, 1),
(10, '6M2', 'Economy', 'Middle', 0.00, 1),
(10, '6W', 'Economy', 'Window', 150.00, 1),
(10, '6W2', 'Economy', 'Window', 150.00, 1),
(10, '7A', 'Economy', 'Aisle', 75.00, 0),
(10, '7A2', 'Economy', 'Aisle', 75.00, 1),
(10, '7M', 'Economy', 'Middle', 0.00, 1),
(10, '7M2', 'Economy', 'Middle', 0.00, 1),
(10, '7W', 'Economy', 'Window', 150.00, 0),
(10, '7W2', 'Economy', 'Window', 150.00, 0),
(10, '8A', 'Economy', 'Aisle', 75.00, 1),
(10, '8A2', 'Economy', 'Aisle', 75.00, 0),
(10, '8M', 'Economy', 'Middle', 0.00, 1),
(10, '8M2', 'Economy', 'Middle', 0.00, 1),
(10, '8W', 'Economy', 'Window', 150.00, 0),
(10, '8W2', 'Economy', 'Window', 150.00, 1),
(10, '9A', 'Economy', 'Aisle', 75.00, 0),
(10, '9A2', 'Economy', 'Aisle', 75.00, 1),
(10, '9M', 'Economy', 'Middle', 0.00, 1),
(10, '9M2', 'Economy', 'Middle', 0.00, 1),
(10, '9W', 'Economy', 'Window', 150.00, 1),
(10, '9W2', 'Economy', 'Window', 150.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `TicketID` int(11) NOT NULL,
  `BookingID` int(11) NOT NULL,
  `AircraftID` int(11) NOT NULL,
  `SeatNumber` varchar(10) NOT NULL,
  `PricePaid` decimal(10,2) NOT NULL,
  `PNR` varchar(10) NOT NULL,
  `ExtraLuggageKG` decimal(5,2) DEFAULT 0.00 CHECK (`ExtraLuggageKG` >= 0),
  `ExtraLuggageCost` decimal(10,2) DEFAULT 0.00 CHECK (`ExtraLuggageCost` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tickets`
--

INSERT INTO `tickets` (`TicketID`, `BookingID`, `AircraftID`, `SeatNumber`, `PricePaid`, `PNR`, `ExtraLuggageKG`, `ExtraLuggageCost`) VALUES
(1, 1, 1, '3A', 3575.00, 'PNR100001', 0.00, 0.00),
(2, 2, 2, '3W', 3750.00, 'PNR100002', 5.00, 500.00),
(3, 3, 3, '7M', 4200.00, 'PNR100003', 0.00, 0.00),
(4, 4, 4, '1W', 3000.00, 'PNR100004', 10.00, 1000.00),
(5, 5, 5, '2A', 2875.00, 'PNR100005', 0.00, 0.00),
(6, 6, 6, '1A', 3975.00, 'PNR100006', 0.00, 0.00),
(7, 7, 7, '2W', 12250.00, 'PNR100007', 15.00, 1500.00),
(8, 8, 7, '3A', 33200.00, 'PNR100008', 0.00, 0.00),
(9, 9, 8, '1A', 18200.00, 'PNR100009', 0.00, 0.00),
(10, 10, 8, '3W', 28500.00, 'PNR100010', 0.00, 0.00),
(11, 11, 9, '1W', 14500.00, 'PNR100011', 23.00, 2300.00),
(12, 12, 10, '2A', 14100.00, 'PNR100012', 0.00, 0.00),
(13, 13, 1, '4W', 3150.00, 'PNR100013', 0.00, 0.00),
(14, 14, 2, '4M', 3800.00, 'PNR100014', 7.00, 700.00),
(15, 15, 3, '5A', 4400.00, 'PNR100015', 0.00, 0.00),
(16, 16, 4, '11M', 2500.00, 'PNR100016', 0.00, 0.00),
(17, 17, 5, '1W', 52300.00, 'PNR100017', 20.00, 2000.00),
(18, 18, 6, '2W', 48300.00, 'PNR100018', 0.00, 0.00),
(19, 19, 7, '1A', 62200.00, 'PNR100019', 30.00, 3000.00),
(20, 20, 8, '3W', 19500.00, 'PNR100020', 0.00, 0.00),
(21, 21, 8, '4A', 20200.00, 'PNR100021', 0.00, 0.00),
(22, 22, 9, '4A', 8200.00, 'PNR100022', 0.00, 0.00),
(23, 23, 10, '4W', 25150.00, 'PNR100023', 15.00, 1500.00),
(24, 24, 4, '5A', 15200.00, 'PNR100024', 0.00, 0.00),
(25, 25, 5, '5W', 30150.00, 'PNR100025', 10.00, 1000.00),
(26, 26, 9, '5A', 3475.00, 'PNR100026', 0.00, 0.00),
(27, 27, 10, '5W', 22150.00, 'PNR100027', 12.00, 1200.00),
(28, 28, 1, '5M', 2900.00, 'PNR100028', 0.00, 0.00),
(29, 29, 2, '5A', 2675.00, 'PNR100029', 0.00, 0.00),
(30, 30, 3, '6A', 2400.00, 'PNR100030', 0.00, 0.00);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_booking_detail`
-- (See below for the actual view)
--
CREATE TABLE `v_booking_detail` (
`BookingID` int(11)
,`BookingStatus` varchar(20)
,`BookingDate` datetime
,`PassengerName` varchar(101)
,`Email` varchar(100)
,`ContactNo` varchar(15)
,`Age` int(11)
,`AirlineName` varchar(100)
,`DepartureAirportID` varchar(10)
,`ArrivalAirportID` varchar(10)
,`DepartureTime` datetime
,`ArrivalTime` datetime
,`SeatNumber` varchar(10)
,`SeatClass` varchar(20)
,`SeatPosition` varchar(10)
,`PricePaid` decimal(10,2)
,`ExtraLuggageKG` decimal(5,2)
,`ExtraLuggageCost` decimal(10,2)
,`MealTotal` decimal(42,2)
,`PNR` varchar(10)
,`PaymentMethod` varchar(20)
,`PaymentStatus` varchar(20)
,`AmountPaid` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_flight_availability`
-- (See below for the actual view)
--
CREATE TABLE `v_flight_availability` (
`FlightID` int(11)
,`AirlineName` varchar(100)
,`FromCity` varchar(50)
,`ToCity` varchar(50)
,`DepartureAirportID` varchar(10)
,`ArrivalAirportID` varchar(10)
,`DepartureTime` datetime
,`ArrivalTime` datetime
,`DurationMins` bigint(21)
,`BasePrice` decimal(10,2)
,`StateTaxAmount` decimal(10,2)
,`TotalPrice` decimal(11,2)
,`FlightType` varchar(20)
,`FlightCategory` varchar(20)
,`AircraftModel` varchar(100)
,`AvailableSeats` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure for view `v_booking_detail`
--
DROP TABLE IF EXISTS `v_booking_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_booking_detail`  AS SELECT `b`.`BookingID` AS `BookingID`, `b`.`Status` AS `BookingStatus`, `b`.`BookingDate` AS `BookingDate`, concat(`p`.`FirstName`,' ',`p`.`LastName`) AS `PassengerName`, `p`.`Email` AS `Email`, `p`.`ContactNo` AS `ContactNo`, TIMESTAMPDIFF(YEAR, `p`.`DateOfBirth`, CURDATE()) AS `Age`, `al`.`AirlineName` AS `AirlineName`, `f`.`DepartureAirportID` AS `DepartureAirportID`, `f`.`ArrivalAirportID` AS `ArrivalAirportID`, `f`.`DepartureTime` AS `DepartureTime`, `f`.`ArrivalTime` AS `ArrivalTime`, `t`.`SeatNumber` AS `SeatNumber`, `s`.`SeatClass` AS `SeatClass`, `s`.`SeatPosition` AS `SeatPosition`, `t`.`PricePaid` AS `PricePaid`, `t`.`ExtraLuggageKG` AS `ExtraLuggageKG`, `t`.`ExtraLuggageCost` AS `ExtraLuggageCost`, coalesce((select sum(`m`.`Price` * `bm`.`Quantity`) from (`bookingmeals` `bm` join `meals` `m` on(`bm`.`MealID` = `m`.`MealID`)) where `bm`.`BookingID` = `b`.`BookingID`),0) AS `MealTotal`, `t`.`PNR` AS `PNR`, `pay`.`PaymentMethod` AS `PaymentMethod`, `pay`.`PaymentStatus` AS `PaymentStatus`, `pay`.`Amount` AS `AmountPaid` FROM (((((((`bookings` `b` join `passengers` `p` on(`b`.`PassengerID` = `p`.`PassengerID`)) join `flights` `f` on(`b`.`FlightID` = `f`.`FlightID`)) join `aircraft` `ac` on(`f`.`AircraftID` = `ac`.`AircraftID`)) join `airlines` `al` on(`ac`.`AirlineID` = `al`.`AirlineID`)) join `tickets` `t` on(`t`.`BookingID` = `b`.`BookingID`)) join `seats` `s` on(`t`.`AircraftID` = `s`.`AircraftID` and `t`.`SeatNumber` = `s`.`SeatNumber`)) left join `payments` `pay` on(`pay`.`TicketID` = `t`.`TicketID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_flight_availability`
--
DROP TABLE IF EXISTS `v_flight_availability`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_flight_availability`  AS SELECT `f`.`FlightID` AS `FlightID`, `al`.`AirlineName` AS `AirlineName`, `dep`.`City` AS `FromCity`, `arr`.`City` AS `ToCity`, `f`.`DepartureAirportID` AS `DepartureAirportID`, `f`.`ArrivalAirportID` AS `ArrivalAirportID`, `f`.`DepartureTime` AS `DepartureTime`, `f`.`ArrivalTime` AS `ArrivalTime`, timestampdiff(MINUTE,`f`.`DepartureTime`,`f`.`ArrivalTime`) AS `DurationMins`, `f`.`BasePrice` AS `BasePrice`, `f`.`StateTaxAmount` AS `StateTaxAmount`, `f`.`BasePrice`+ `f`.`StateTaxAmount` AS `TotalPrice`, `f`.`FlightType` AS `FlightType`, `f`.`FlightCategory` AS `FlightCategory`, `ac`.`AircraftModel` AS `AircraftModel`, (select count(0) from `seats` `s` where `s`.`AircraftID` = `f`.`AircraftID` and `s`.`IsAvailable` = 1) AS `AvailableSeats` FROM ((((`flights` `f` join `aircraft` `ac` on(`f`.`AircraftID` = `ac`.`AircraftID`)) join `airlines` `al` on(`ac`.`AirlineID` = `al`.`AirlineID`)) join `airports` `dep` on(`f`.`DepartureAirportID` = `dep`.`AirportCode`)) join `airports` `arr` on(`f`.`ArrivalAirportID` = `arr`.`AirportCode`)) WHERE `al`.`IsActive` = 1 AND `ac`.`Status` = 'Active' ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `aircraft`
--
ALTER TABLE `aircraft`
  ADD PRIMARY KEY (`AircraftID`),
  ADD UNIQUE KEY `RegistrationNo` (`RegistrationNo`),
  ADD KEY `fk_aircraft_airline` (`AirlineID`);

--
-- Indexes for table `airlines`
--
ALTER TABLE `airlines`
  ADD PRIMARY KEY (`AirlineID`),
  ADD UNIQUE KEY `IATACode` (`IATACode`);

--
-- Indexes for table `airports`
--
ALTER TABLE `airports`
  ADD PRIMARY KEY (`AirportCode`);

--
-- Indexes for table `app_users`
--
ALTER TABLE `app_users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `bookingmeals`
--
ALTER TABLE `bookingmeals`
  ADD PRIMARY KEY (`BookingMealID`),
  ADD KEY `fk_bm_booking` (`BookingID`),
  ADD KEY `fk_bm_passenger` (`PassengerID`),
  ADD KEY `fk_bm_meal` (`MealID`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`BookingID`),
  ADD KEY `fk_bookings_flight` (`FlightID`),
  ADD KEY `fk_bookings_passenger` (`PassengerID`);

--
-- Indexes for table `flights`
--
ALTER TABLE `flights`
  ADD PRIMARY KEY (`FlightID`),
  ADD KEY `fk_flight_aircraft` (`AircraftID`),
  ADD KEY `fk_flight_arr_airport` (`ArrivalAirportID`),
  ADD KEY `fk_flight_unary` (`ConnectingFlightID`),
  ADD KEY `idx_flights_route_date` (`DepartureAirportID`,`ArrivalAirportID`,`DepartureTime`);

--
-- Indexes for table `meals`
--
ALTER TABLE `meals`
  ADD PRIMARY KEY (`MealID`),
  ADD KEY `fk_meals_airline` (`AirlineID`);

--
-- Indexes for table `passengers`
--
ALTER TABLE `passengers`
  ADD PRIMARY KEY (`PassengerID`),
  ADD UNIQUE KEY `Email` (`Email`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`PaymentID`),
  ADD KEY `fk_payments_ticket` (`TicketID`);

--
-- Indexes for table `seats`
--
ALTER TABLE `seats`
  ADD PRIMARY KEY (`AircraftID`,`SeatNumber`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`TicketID`),
  ADD UNIQUE KEY `BookingID` (`BookingID`),
  ADD UNIQUE KEY `PNR` (`PNR`),
  ADD KEY `fk_tickets_seat` (`AircraftID`,`SeatNumber`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `aircraft`
--
ALTER TABLE `aircraft`
  MODIFY `AircraftID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `airlines`
--
ALTER TABLE `airlines`
  MODIFY `AirlineID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `app_users`
--
ALTER TABLE `app_users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `bookingmeals`
--
ALTER TABLE `bookingmeals`
  MODIFY `BookingMealID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `BookingID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `flights`
--
ALTER TABLE `flights`
  MODIFY `FlightID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `meals`
--
ALTER TABLE `meals`
  MODIFY `MealID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `passengers`
--
ALTER TABLE `passengers`
  MODIFY `PassengerID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `PaymentID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `TicketID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `aircraft`
--
ALTER TABLE `aircraft`
  ADD CONSTRAINT `fk_aircraft_airline` FOREIGN KEY (`AirlineID`) REFERENCES `airlines` (`AirlineID`);

--
-- Constraints for table `bookingmeals`
--
ALTER TABLE `bookingmeals`
  ADD CONSTRAINT `fk_bm_booking` FOREIGN KEY (`BookingID`) REFERENCES `bookings` (`BookingID`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_bm_meal` FOREIGN KEY (`MealID`) REFERENCES `meals` (`MealID`),
  ADD CONSTRAINT `fk_bm_passenger` FOREIGN KEY (`PassengerID`) REFERENCES `passengers` (`PassengerID`);

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_bookings_flight` FOREIGN KEY (`FlightID`) REFERENCES `flights` (`FlightID`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_bookings_passenger` FOREIGN KEY (`PassengerID`) REFERENCES `passengers` (`PassengerID`);

--
-- Constraints for table `flights`
--
ALTER TABLE `flights`
  ADD CONSTRAINT `fk_flight_aircraft` FOREIGN KEY (`AircraftID`) REFERENCES `aircraft` (`AircraftID`),
  ADD CONSTRAINT `fk_flight_arr_airport` FOREIGN KEY (`ArrivalAirportID`) REFERENCES `airports` (`AirportCode`),
  ADD CONSTRAINT `fk_flight_dep_airport` FOREIGN KEY (`DepartureAirportID`) REFERENCES `airports` (`AirportCode`),
  ADD CONSTRAINT `fk_flight_unary` FOREIGN KEY (`ConnectingFlightID`) REFERENCES `flights` (`FlightID`) ON DELETE SET NULL;

--
-- Constraints for table `meals`
--
ALTER TABLE `meals`
  ADD CONSTRAINT `fk_meals_airline` FOREIGN KEY (`AirlineID`) REFERENCES `airlines` (`AirlineID`);

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `fk_payments_ticket` FOREIGN KEY (`TicketID`) REFERENCES `tickets` (`TicketID`) ON DELETE CASCADE;

--
-- Constraints for table `seats`
--
ALTER TABLE `seats`
  ADD CONSTRAINT `fk_seats_aircraft` FOREIGN KEY (`AircraftID`) REFERENCES `aircraft` (`AircraftID`) ON DELETE CASCADE;

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `fk_tickets_booking` FOREIGN KEY (`BookingID`) REFERENCES `bookings` (`BookingID`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_tickets_seat` FOREIGN KEY (`AircraftID`,`SeatNumber`) REFERENCES `seats` (`AircraftID`, `SeatNumber`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
