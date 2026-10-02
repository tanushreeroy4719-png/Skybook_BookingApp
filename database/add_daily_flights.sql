-- SkyBook: DAILY flights generator. Run AFTER add_more_flights.sql (needs flights.MealsAvailable).
USE `skybook`;

DROP TABLE IF EXISTS `daily_templates`;
CREATE TABLE `daily_templates` (
  `Dep` CHAR(3), `Arr` CHAR(3), `DepTime` TIME, `DurMin` INT, `AircraftID` INT, `BasePrice` DECIMAL(10,2), `FType` VARCHAR(15)
) ENGINE=InnoDB;

INSERT INTO `daily_templates` VALUES
('AMD','DEL','07:00:00',95,1,5800,'National'),
('AMD','DEL','19:45:00',95,4,6050,'National'),
('DEL','AMD','07:00:00',105,5,5800,'National'),
('DEL','AMD','19:45:00',105,19,6050,'National'),
('AMD','CCU','07:00:00',170,2,6900,'National'),
('AMD','CCU','19:45:00',170,8,7150,'National'),
('CCU','AMD','07:00:00',175,6,6900,'National'),
('CCU','AMD','19:45:00',175,1,7150,'National'),
('AMD','BOM','07:00:00',80,10,3400,'National'),
('AMD','BOM','19:45:00',80,5,3650,'National'),
('BOM','AMD','07:00:00',85,7,3400,'National'),
('BOM','AMD','19:45:00',85,2,3650,'National'),
('AMD','BLR','07:00:00',125,3,5200,'National'),
('AMD','BLR','19:45:00',125,6,5450,'National'),
('BLR','AMD','07:00:00',130,18,5200,'National'),
('BLR','AMD','19:45:00',130,10,5450,'National'),
('AMD','HYD','07:00:00',115,4,4600,'National'),
('AMD','HYD','19:45:00',115,7,4850,'National'),
('HYD','AMD','07:00:00',120,19,4600,'National'),
('HYD','AMD','19:45:00',120,3,4850,'National'),
('AMD','MAA','07:00:00',150,8,5600,'National'),
('AMD','MAA','19:45:00',150,18,5850,'National'),
('MAA','AMD','07:00:00',155,1,5600,'National'),
('MAA','AMD','19:45:00',155,4,5850,'National'),
('AMD','GOI','07:00:00',105,5,4300,'National'),
('AMD','GOI','19:45:00',105,19,4550,'National'),
('GOI','AMD','07:00:00',110,2,4300,'National'),
('GOI','AMD','19:45:00',110,8,4550,'National'),
('AMD','JAI','07:00:00',75,6,3900,'National'),
('AMD','JAI','19:45:00',75,1,4150,'National'),
('JAI','AMD','07:00:00',80,10,3900,'National'),
('JAI','AMD','19:45:00',80,5,4150,'National'),
('AMD','PNQ','07:00:00',90,7,3600,'National'),
('AMD','PNQ','19:45:00',90,2,3850,'National'),
('PNQ','AMD','07:00:00',95,3,3600,'National'),
('PNQ','AMD','19:45:00',95,6,3850,'National'),
('DEL','CCU','07:00:00',140,18,5200,'National'),
('DEL','CCU','19:45:00',140,10,5450,'National'),
('CCU','DEL','07:00:00',145,4,5300,'National'),
('CCU','DEL','19:45:00',145,7,5550,'National'),
('DEL','BOM','07:00:00',130,19,5000,'National'),
('DEL','BOM','19:45:00',130,3,5250,'National'),
('BOM','DEL','07:00:00',135,8,5000,'National'),
('BOM','DEL','19:45:00',135,18,5250,'National'),
('AMD','DXB','07:00:00',195,8,14500,'International'),
('DXB','AMD','07:00:00',210,13,14800,'International'),
('AMD','BKK','07:00:00',345,3,17500,'International'),
('AMD','LHR','07:00:00',560,12,41000,'International');

DROP PROCEDURE IF EXISTS `add_daily_flights`;
DELIMITER $$
CREATE PROCEDURE `add_daily_flights`(IN start_day DATE, IN end_day DATE)
BEGIN
  DECLARE d DATE;
  SET d = start_day;
  WHILE d <= end_day DO
    INSERT INTO flights (AircraftID, DepartureAirportID, ArrivalAirportID, DepartureTime, ArrivalTime,
                         StateTaxAmount, BasePrice, FlightType, FlightCategory, ConnectingFlightID, MealsAvailable)
    SELECT t.AircraftID, t.Dep, t.Arr,
           TIMESTAMP(d, t.DepTime),
           TIMESTAMP(d, t.DepTime) + INTERVAL t.DurMin MINUTE,
           IF(t.FType = 'National', 200, 900),
           ROUND(t.BasePrice * IF(DAYOFWEEK(d) IN (1,6,7), 1.10, 1.00)),   -- Fri/Sat/Sun +10%
           t.FType, 'Direct', NULL,
           IF(ac.AirlineID IN (17,19), 0, 1)                               -- Akasa / Air India Express: no meals
    FROM daily_templates t
    JOIN aircraft ac ON ac.AircraftID = t.AircraftID
    WHERE NOT EXISTS (SELECT 1 FROM flights x
                      WHERE x.AircraftID = t.AircraftID AND x.DepartureAirportID = t.Dep
                        AND x.ArrivalAirportID = t.Arr AND x.DepartureTime = TIMESTAMP(d, t.DepTime));
    SET d = d + INTERVAL 1 DAY;
  END WHILE;
END$$
DELIMITER ;

-- Generate flights for every day from 2 Oct 2026 to 31 Dec 2026 (safe to re-run, no duplicates).
CALL add_daily_flights('2026-10-02', '2026-12-31');

-- OPTIONAL auto top-up: every night add the day 90 days ahead (needs: SET GLOBAL event_scheduler = ON;)
DROP EVENT IF EXISTS `ev_daily_flights`;
CREATE EVENT `ev_daily_flights` ON SCHEDULE EVERY 1 DAY STARTS (CURRENT_DATE + INTERVAL 1 DAY)
DO CALL add_daily_flights(CURRENT_DATE + INTERVAL 90 DAY, CURRENT_DATE + INTERVAL 90 DAY);

SELECT COUNT(*) AS TotalFlights, SUM(MealsAvailable) AS WithMeals, MIN(DepartureTime) AS FirstDay, MAX(DepartureTime) AS LastDay FROM flights;
