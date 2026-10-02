-- =============================================================================
--  FIX: primary keys, AUTO_INCREMENT and unique keys
--  The tables above were created without them, so INSERTs that rely on
--  AUTO_INCREMENT (e.g. registering a passenger) fail with
--  "Field 'PassengerID' doesn't have a default value".
--  Run ONCE. If a line fails with 'Multiple primary key defined', that table
--  already has its key - skip that line. Fails if a table has duplicate IDs
--  (e.g. the import was run twice) - drop the database and re-import instead.
-- =============================================================================
USE `skybook`;

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
ALTER TABLE `flights`      ADD PRIMARY KEY (`FlightID`),      MODIFY `FlightID`      int(11) NOT NULL AUTO_INCREMENT;
