-- SkyBook: 50+ extra flights (Oct 29 - Nov 8 2026) + per-flight meal availability
-- Run AFTER skybook_complete_import.sql (and fix_keys_and_autoincrement.sql).
USE `skybook`;

-- 1) New column: are meals served on this flight? (1 = yes, 0 = no)
ALTER TABLE `flights` ADD COLUMN `MealsAvailable` TINYINT(1) NOT NULL DEFAULT 1 AFTER `ConnectingFlightID`;

-- 2) Existing flights: budget carriers with no meal menu (Akasa, Air India Express) = no meals
UPDATE `flights` f JOIN `aircraft` ac ON f.AircraftID = ac.AircraftID SET f.MealsAvailable = IF(ac.AirlineID IN (17,19), 0, 1);

-- 3) New flights
INSERT IGNORE INTO `flights` (`FlightID`,`AircraftID`,`DepartureAirportID`,`ArrivalAirportID`,`DepartureTime`,`ArrivalTime`,`StateTaxAmount`,`BasePrice`,`FlightType`,`FlightCategory`,`ConnectingFlightID`,`MealsAvailable`) VALUES
(101,1,'AMD','DEL','2026-10-31 14:45:00','2026-10-31 16:20:00',200.00,5800.00,'National','Direct',NULL,1),
(102,1,'DEL','AMD','2026-11-07 17:05:00','2026-11-07 18:50:00',200.00,5800.00,'National','Direct',NULL,1),
(103,2,'DEL','AMD','2026-11-07 14:40:00','2026-11-07 16:25:00',200.00,5800.00,'National','Direct',NULL,1),
(104,1,'AMD','DEL','2026-10-29 06:15:00','2026-10-29 07:50:00',200.00,5400.00,'National','Direct',NULL,0),
(105,6,'DEL','AMD','2026-11-01 19:30:00','2026-11-01 21:15:00',200.00,6100.00,'National','Direct',NULL,1),
(106,3,'AMD','CCU','2026-11-07 14:10:00','2026-11-07 17:00:00',200.00,6500.00,'National','Direct',NULL,1),
(107,19,'CCU','AMD','2026-10-30 08:40:00','2026-10-30 11:35:00',200.00,7200.00,'National','Direct',NULL,0),
(108,5,'AMD','BOM','2026-11-03 21:45:00','2026-11-03 23:05:00',200.00,3200.00,'National','Direct',NULL,0),
(109,10,'BOM','AMD','2026-11-08 16:55:00','2026-11-08 18:20:00',200.00,3000.00,'National','Direct',NULL,1),
(110,18,'AMD','BLR','2026-10-31 11:20:00','2026-10-31 13:25:00',200.00,5000.00,'National','Direct',NULL,0),
(111,8,'BLR','AMD','2026-11-05 06:15:00','2026-11-05 08:25:00',200.00,4800.00,'National','Direct',NULL,1),
(112,2,'AMD','HYD','2026-10-29 19:30:00','2026-10-29 21:25:00',200.00,5200.00,'National','Direct',NULL,0),
(113,7,'HYD','AMD','2026-11-01 14:10:00','2026-11-01 16:10:00',200.00,4400.00,'National','Direct',NULL,1),
(114,4,'AMD','MAA','2026-11-07 08:40:00','2026-11-07 11:10:00',200.00,5400.00,'National','Direct',NULL,1),
(115,1,'MAA','AMD','2026-10-30 21:45:00','2026-10-31 00:20:00',200.00,5400.00,'National','Direct',NULL,1),
(116,6,'AMD','GOI','2026-11-03 16:55:00','2026-11-03 18:40:00',200.00,3900.00,'National','Direct',NULL,0),
(117,3,'AMD','JAI','2026-11-08 11:20:00','2026-11-08 12:35:00',200.00,3500.00,'National','Direct',NULL,1),
(118,19,'AMD','PNQ','2026-10-31 06:15:00','2026-10-31 07:45:00',200.00,3400.00,'National','Direct',NULL,0),
(119,11,'AMD','DXB','2026-11-05 19:30:00','2026-11-05 22:45:00',900.00,14300.00,'International','Direct',NULL,1),
(120,11,'DXB','AMD','2026-10-29 14:10:00','2026-10-29 17:40:00',900.00,15400.00,'International','Direct',NULL,1),
(121,11,'AMD','LHR','2026-11-01 08:40:00','2026-11-01 18:00:00',900.00,41300.00,'International','Direct',NULL,1),
(122,11,'AMD','BKK','2026-11-07 21:45:00','2026-11-08 03:30:00',900.00,18100.00,'International','Direct',NULL,1),
(123,2,'DEL','CCU','2026-10-30 16:55:00','2026-10-30 19:15:00',200.00,5500.00,'National','Direct',NULL,1),
(124,7,'CCU','DEL','2026-11-03 11:20:00','2026-11-03 13:45:00',200.00,5100.00,'National','Direct',NULL,1),
(125,4,'AMD','DEL','2026-11-08 06:15:00','2026-11-08 07:50:00',200.00,6400.00,'National','Direct',NULL,1),
(126,1,'DEL','AMD','2026-10-31 19:30:00','2026-10-31 21:15:00',200.00,5400.00,'National','Direct',NULL,0),
(127,6,'AMD','CCU','2026-11-05 14:10:00','2026-11-05 17:00:00',200.00,6500.00,'National','Direct',NULL,1),
(128,3,'CCU','AMD','2026-10-29 08:40:00','2026-10-29 11:35:00',200.00,6500.00,'National','Direct',NULL,1),
(129,19,'AMD','BOM','2026-11-01 21:45:00','2026-11-01 23:05:00',200.00,3700.00,'National','Direct',NULL,0),
(130,5,'BOM','AMD','2026-11-07 16:55:00','2026-11-07 18:20:00',200.00,3400.00,'National','Direct',NULL,0),
(131,10,'AMD','BLR','2026-10-30 11:20:00','2026-10-30 13:25:00',200.00,5000.00,'National','Direct',NULL,1),
(132,18,'BLR','AMD','2026-11-03 06:15:00','2026-11-03 08:25:00',200.00,5000.00,'National','Direct',NULL,0),
(133,8,'AMD','HYD','2026-11-08 19:30:00','2026-11-08 21:25:00',200.00,4600.00,'National','Direct',NULL,1),
(134,2,'HYD','AMD','2026-10-31 14:10:00','2026-10-31 16:10:00',200.00,4900.00,'National','Direct',NULL,0),
(135,7,'AMD','MAA','2026-11-05 08:40:00','2026-11-05 11:10:00',200.00,5600.00,'National','Direct',NULL,1),
(136,4,'MAA','AMD','2026-10-29 21:45:00','2026-10-30 00:20:00',200.00,6200.00,'National','Direct',NULL,1),
(137,1,'AMD','GOI','2026-11-01 16:55:00','2026-11-01 18:40:00',200.00,4100.00,'National','Direct',NULL,1),
(138,6,'AMD','JAI','2026-11-07 11:20:00','2026-11-07 12:35:00',200.00,3700.00,'National','Direct',NULL,0),
(139,3,'AMD','PNQ','2026-10-30 06:15:00','2026-10-30 07:45:00',200.00,3400.00,'National','Direct',NULL,1),
(140,11,'AMD','DXB','2026-11-03 19:30:00','2026-11-03 22:45:00',900.00,14800.00,'International','Direct',NULL,1),
(141,11,'DXB','AMD','2026-11-08 14:10:00','2026-11-08 17:40:00',900.00,15400.00,'International','Direct',NULL,1),
(142,11,'AMD','LHR','2026-10-31 08:40:00','2026-10-31 18:00:00',900.00,41600.00,'International','Direct',NULL,1),
(143,11,'AMD','BKK','2026-11-05 21:45:00','2026-11-06 03:30:00',900.00,17100.00,'International','Direct',NULL,1),
(144,8,'DEL','CCU','2026-10-29 16:55:00','2026-10-29 19:15:00',200.00,4800.00,'National','Direct',NULL,1),
(145,2,'CCU','DEL','2026-11-01 11:20:00','2026-11-01 13:45:00',200.00,5100.00,'National','Direct',NULL,1),
(146,7,'AMD','DEL','2026-11-07 06:15:00','2026-11-07 07:50:00',200.00,5800.00,'National','Direct',NULL,1),
(147,4,'DEL','AMD','2026-10-30 19:30:00','2026-10-30 21:15:00',200.00,5600.00,'National','Direct',NULL,1),
(148,1,'AMD','CCU','2026-11-03 14:10:00','2026-11-03 17:00:00',200.00,6700.00,'National','Direct',NULL,1),
(149,6,'CCU','AMD','2026-11-08 08:40:00','2026-11-08 11:35:00',200.00,6700.00,'National','Direct',NULL,1),
(150,3,'AMD','BOM','2026-10-31 21:45:00','2026-10-31 23:05:00',200.00,3700.00,'National','Direct',NULL,1),
(151,19,'BOM','AMD','2026-11-05 16:55:00','2026-11-05 18:20:00',200.00,3000.00,'National','Direct',NULL,0),
(152,5,'AMD','BLR','2026-10-29 11:20:00','2026-10-29 13:25:00',200.00,4800.00,'National','Direct',NULL,0),
(153,10,'BLR','AMD','2026-11-01 06:15:00','2026-11-01 08:25:00',200.00,5800.00,'National','Direct',NULL,1),
(154,18,'AMD','HYD','2026-11-07 19:30:00','2026-11-07 21:25:00',200.00,4900.00,'National','Direct',NULL,0),
(155,8,'HYD','AMD','2026-10-30 14:10:00','2026-10-30 16:10:00',200.00,4400.00,'National','Direct',NULL,1),
(156,2,'AMD','MAA','2026-11-03 08:40:00','2026-11-03 11:10:00',200.00,5400.00,'National','Direct',NULL,1);

SELECT CONCAT('Total flights: ', COUNT(*), ' | with meals: ', SUM(MealsAvailable)) AS Status FROM flights;
