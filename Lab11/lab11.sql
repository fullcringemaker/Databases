-- Лабораторная работа 11
USE master;
GO

IF DB_ID(N'Lab11') IS NOT NULL
BEGIN
    ALTER DATABASE Lab11 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Lab11;
END
GO

CREATE DATABASE Lab11
ON PRIMARY(
    NAME = Lab11_dat,
    FILENAME = 'D:\database\lab11\Lab11_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab_11log,
    FILENAME = 'D:\database\lab11\Lab11_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab11;
GO

-- Таблица AIRCRAFT
IF OBJECT_ID(N'AIRCRAFT', N'U') IS NOT NULL
    DROP TABLE AIRCRAFT;
GO

CREATE TABLE AIRCRAFT
(
    AircraftID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    BoardNumber VARCHAR(8) NOT NULL,
    Model NVARCHAR(10) NOT NULL,
    PassengerCapacity SMALLINT NOT NULL,
    LoadCapacity NUMERIC(6,2) NOT NULL,
    AircraftAge TINYINT NOT NULL,
    Status TINYINT NOT NULL DEFAULT (1) CHECK (Status IN (1, 2)),
    CONSTRAINT AK_BoardNumber UNIQUE (BoardNumber)
);

-- Таблица FLIGHT
IF OBJECT_ID(N'FLIGHT', N'U') IS NOT NULL
    DROP TABLE FLIGHT;
GO

CREATE TABLE FLIGHT
(
    FlightID INT NOT NULL PRIMARY KEY IDENTITY(1,1),      
    FlightNumber VARCHAR(5) NOT NULL,         
    FlightDate Date NOT NULL,        
    DepartureAirport CHAR(3) NOT NULL,
    ArrivalAirport CHAR(3) NOT NULL,
    BoardingTime DATETIME NOT NULL,
    DepartureTime DATETIME NOT NULL,
    ArrivalTime DATETIME NOT NULL,
    Status TINYINT NOT NULL DEFAULT 1 CHECK (Status IN (1, 2, 3, 4, 5)),  
    AircraftID INT NOT NULL,
    CONSTRAINT AK_Flight UNIQUE (FlightNumber, FlightDate),
    CONSTRAINT FK_AircraftID FOREIGN KEY (AircraftID) REFERENCES dbo.AIRCRAFT(AircraftID)
    ON UPDATE NO ACTION
);

-- Таблица PASSENGER
IF OBJECT_ID(N'PASSENGER', N'U') IS NOT NULL
    DROP TABLE PASSENGER;
GO

CREATE TABLE PASSENGER
(
    PassengerID INT NOT NULL PRIMARY KEY IDENTITY(1,1),      
    DocumentNumber VARCHAR(14) NOT NULL,       
    FirstName NVARCHAR(30) NOT NULL,
    LastName NVARCHAR(30) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender TINYINT NOT NULL CHECK (Gender IN (1,2)),      
    Citizenship CHAR(3) NOT NULL,
    CONSTRAINT AK_DocumentNumber UNIQUE (DocumentNumber)
);

-- Таблица CREW
IF OBJECT_ID(N'CREW', N'U') IS NOT NULL
    DROP TABLE CREW;
GO

CREATE TABLE CREW
(
    CrewID INT NOT NULL PRIMARY KEY IDENTITY(1,1),         
    LicenseNumber VARCHAR(15) NOT NULL,    
    FirstName NVARCHAR(30) NOT NULL,
    LastName  NVARCHAR(30) NOT NULL,
    Gender TINYINT NOT NULL CHECK (Gender IN (1, 2)),
    Position TINYINT NOT NULL CHECK (Position IN (1, 2, 3, 4)),
    FlyingHours DECIMAL(6,2) NOT NULL CHECK (FlyingHours >= 0),
    LicenseExpiryDate DATE Not NULL,
    CONSTRAINT AK_LicenseNumber UNIQUE (LicenseNumber)
);

-- Таблица TICKET
IF OBJECT_ID(N'TICKET', N'U') IS NOT NULL
    DROP TABLE TICKET;
GO

CREATE TABLE TICKET
(
    TicketID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    TicketNumber VARCHAR(13) NOT NULL,        
    Price MONEY NOT NULL,
    BookingDate DATE NOT NULL,
    SeatNumber VARCHAR(4) NOT NULL,
    ClassOfService TINYINT NOT NULL CHECK (ClassOfService IN (1, 2, 3)), 
    BaggageWeight DECIMAL(4,2) NULL,
    HandLuggageWeight DECIMAL(4,2) NULL,
    FlightID INT NOT NULL,
    PassengerID INT NOT NULL,
    CONSTRAINT AK_TicketNumber UNIQUE (TicketNumber),
    CONSTRAINT FK_FlightID FOREIGN KEY (FlightID) REFERENCES dbo.FLIGHT (FlightID)
    ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT FK_PassengerID FOREIGN KEY (PassengerID) REFERENCES dbo.PASSENGER (PassengerID)
    ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Таблица FLIGHT_CREW
IF OBJECT_ID(N'FLIGHT_CREW', N'U') IS NOT NULL
    DROP TABLE FLIGHT_CREW;
GO

CREATE TABLE FLIGHT_CREW
(
    FlightID INT NOT NULL,
    CrewID   INT NOT NULL,
    CONSTRAINT PK_FLIGHT_CREW PRIMARY KEY (FlightID, CrewID),
    CONSTRAINT FK_FLIGHT_CREW_FlightID FOREIGN KEY (FlightID) REFERENCES dbo.FLIGHT (FlightID)
    ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT FK_FLIGHT_CREW_CrewID FOREIGN KEY (CrewID) REFERENCES dbo.CREW (CrewID)
    ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Добавление столбца Address в таблицу LawFirm
ALTER TABLE AIRCRAFT
    ADD Manufacturer NVARCHAR(20) NOT NULL;
GO

-- Добавление столбца Airline в таблицу FLIGHT
ALTER TABLE FLIGHT
    ADD Airline CHAR(2) NOT NULL;
GO

-- Создание представления для AIRCRAFT и FLIGHT
IF OBJECT_ID(N'view_AircraftWithFlight') IS NOT NULL
    DROP VIEW view_AircraftWithFlight;
GO

CREATE VIEW view_AircraftWithFlight
AS
    SELECT
        A.AircraftID,
        A.BoardNumber,
        A.Model,
        A.PassengerCapacity,
        A.LoadCapacity,
        A.AircraftAge,
        A.Status      AS AircraftStatus,
        A.Manufacturer,
        F.FlightID,
        F.FlightNumber,
        F.FlightDate,
        F.DepartureAirport,
        F.ArrivalAirport,
        F.BoardingTime,
        F.DepartureTime,
        F.ArrivalTime,
        F.Status      AS FlightStatus,   
        F.Airline
    FROM AIRCRAFT AS A
        LEFT JOIN FLIGHT AS F
            ON F.AircraftID = A.AircraftID;
GO

-- Триггер: вставка значений AIRCRAFT и FLIGHT через представления
IF OBJECT_ID(N'trigger_Insert_AircraftWithFlight', N'TR') IS NOT NULL
    DROP TRIGGER trigger_Insert_AircraftWithFlight;
GO

CREATE TRIGGER trigger_Insert_AircraftWithFlight
ON view_AircraftWithFlight
INSTEAD OF INSERT
AS
BEGIN
    WITH DistinctAircraft AS
    (
        -- взятие уникальных самолетов
        SELECT DISTINCT
            i.BoardNumber,
            i.Model,
            i.PassengerCapacity,
            i.LoadCapacity,
            i.AircraftAge,
            i.AircraftStatus,
            i.Manufacturer
        FROM inserted i
        WHERE i.BoardNumber IS NOT NULL
    )
    -- добавлением уникальных самолетов, где нет повторений в бортовых номерах
    INSERT INTO AIRCRAFT
        (BoardNumber, Model, PassengerCapacity, LoadCapacity, AircraftAge, Status, Manufacturer)
    SELECT
        DA.BoardNumber,
        DA.Model,
        DA.PassengerCapacity,
        DA.LoadCapacity,
        DA.AircraftAge,
        DA.AircraftStatus,
        DA.Manufacturer
    FROM DistinctAircraft DA
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM AIRCRAFT AS A
        WHERE A.BoardNumber = DA.BoardNumber
    );
    -- добавление рейсов, связывая их с соответствующими самолётами 
    INSERT INTO FLIGHT
        (FlightNumber, FlightDate, DepartureAirport, ArrivalAirport, BoardingTime, DepartureTime, ArrivalTime, Status, AircraftID, Airline)
    SELECT
        i.FlightNumber,
        i.FlightDate,
        i.DepartureAirport,
        i.ArrivalAirport,
        i.BoardingTime,
        i.DepartureTime,
        i.ArrivalTime,
        i.FlightStatus,
        A.AircraftID,
        i.Airline
    FROM inserted AS i
        INNER JOIN AIRCRAFT AS A
            ON A.BoardNumber = i.BoardNumber;
END;
GO

-- Запрет прямой вставки в AIRCRAFT
--IF OBJECT_ID(N'trigger_PreventInsert_ToAircraft') IS NOT NULL
--    DROP TRIGGER trigger_PreventInsert_ToAircraft;
--GO

--CREATE TRIGGER trigger_PreventInsert_ToAircraft
--ON AIRCRAFT
--INSTEAD OF INSERT
--AS
--BEGIN
--    RAISERROR('Добавление записей в таблицу AIRCRAFT запрещено. Для добавления данных использовать view_AircraftWithFlight', 16, 1);
--    ROLLBACK TRANSACTION;
--END;
--GO

INSERT INTO view_AircraftWithFlight
    (BoardNumber, Model, PassengerCapacity, LoadCapacity, AircraftAge, AircraftStatus, Manufacturer,
     FlightNumber, FlightDate, DepartureAirport, ArrivalAirport, BoardingTime, DepartureTime, ArrivalTime, FlightStatus, Airline)
VALUES
    ('RA-82001', 'A320', 180, 2000.00, 5, 1, N'Airbus',
     'SU101', '2025-01-10', 'SVO', 'LED', '2025-01-10 07:30', '2025-01-10 08:00', '2025-01-10 09:30', 1, 'SU'),
    ('RA-82002', 'A321', 200, 2100.00, 4, 1, N'Airbus',
     'SU102', '2025-01-08', 'SVO', 'LED', '2025-01-08 09:00', '2025-01-08 09:30', '2025-01-08 11:00', 1, 'SU'),
    ('VP-B737', 'B737', 160, 1800.00, 7, 1, N'Boeing',
     'UT202', '2025-01-09', 'LED', 'DME', '2025-01-09 12:00', '2025-01-09 12:30', '2025-01-09 14:00', 1, 'UT'),
    ('VQ-B781', 'B777', 300, 3000.00, 6, 1, N'Boeing',
     'DP305', '2025-01-09', 'DME', 'LHR', '2025-01-09 14:00', '2025-01-09 14:40', '2025-01-09 18:30', 1, 'DP');
GO

SELECT *
FROM view_AircraftWithFlight;
GO

SELECT * 
FROM FLIGHT 
GO

-- Триггер: удаление самолетов из AIRCRAFT
IF OBJECT_ID(N'trigger_Delete_Aircraft') IS NOT NULL
    DROP TRIGGER trigger_Delete_Aircraft;
GO

CREATE TRIGGER trigger_Delete_Aircraft
ON AIRCRAFT
INSTEAD OF DELETE
AS
BEGIN
    -- проверка, есть ли хотя бы один рейс для удаляемых самолётов
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN FLIGHT F
          ON F.AircraftID = d.AircraftID
    )
    BEGIN
        RAISERROR(N'Нельзя удалить воздушное судно, для которого существуют рейсы.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    -- если связанных рейсов нет — выполняется delete
    DELETE A
    FROM AIRCRAFT AS A
    JOIN deleted AS d
      ON A.AircraftID = d.AircraftID;
END;
GO

--DELETE FROM AIRCRAFT
--WHERE AircraftID = 1;

INSERT INTO AIRCRAFT (BoardNumber, Model, PassengerCapacity, LoadCapacity, AircraftAge, Status, Manufacturer)
VALUES ('RA-89001', 'SSJ-100', 98, 1200.00, 3, 1, N'Иркут');
GO

DELETE FROM AIRCRAFT
WHERE BoardNumber = 'RA-89001';
GO

-- Триггер: обновление статусов самолетов из AIRCRAFT
IF OBJECT_ID(N'trigger_Update_Aircraft') IS NOT NULL
    DROP TRIGGER trigger_Update_Aircraft;
GO

CREATE TRIGGER trigger_Update_Aircraft
ON AIRCRAFT
INSTEAD OF UPDATE
AS
BEGIN
    IF UPDATE(AircraftID)
    BEGIN
        RAISERROR(N'Нельзя изменять AircraftID таким образом.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    -- проверка, есть ли попытки изменить статус самолета, у которого есть рейсы
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        JOIN deleted AS d
          ON i.AircraftID = d.AircraftID
        WHERE i.Status <> d.Status AND i.Status = 2 AND EXISTS (
                                                                    SELECT 1
                                                                    FROM FLIGHT F
                                                                    WHERE F.AircraftID = i.AircraftID
          )
    )
    BEGIN
        RAISERROR(N'Нельзя списывать воздушное судно, для которого существуют рейсы.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    -- если условие не выполняется - выполняется update
    UPDATE A
    SET A.BoardNumber       = i.BoardNumber,
        A.Model             = i.Model,
        A.PassengerCapacity = i.PassengerCapacity,
        A.LoadCapacity      = i.LoadCapacity,
        A.AircraftAge       = i.AircraftAge,
        A.Status            = i.Status,
        A.Manufacturer      = i.Manufacturer
    FROM AIRCRAFT AS A
    JOIN inserted AS i
      ON A.AircraftID = i.AircraftID;
END;
GO

--ошибочная попытка update
--UPDATE AIRCRAFT
--SET Status = 2
--WHERE AircraftID = 1;
--GO

INSERT INTO AIRCRAFT (BoardNumber, Model, PassengerCapacity, LoadCapacity, AircraftAge, Status, Manufacturer)
VALUES ('RA-67890', 'A321', 220, 2100.00, 4, 1, N'Airbus');
GO

UPDATE AIRCRAFT
SET Status = 2
WHERE BoardNumber = 'RA-67890';
GO

SELECT *
FROM AIRCRAFT
GO

-- Таблица PASSENGER
INSERT INTO PASSENGER
    (DocumentNumber, FirstName, LastName, DateOfBirth, Gender, Citizenship)
VALUES
    ('4010 123456', N'Ivan',   N'Ivanov',   '2000-05-12', 1, 'RUS'),
    ('4010 654321', N'Anna',   N'Petrova',  '1995-09-03', 2, 'RUS'),
    ('45 11 789012', N'Aleksei', N'Petrov',  '1992-03-21', 1, 'RUS'),
    ('AB987654321', N'John',   N'Smith',    '1988-12-02', 1, 'USA'),
    ('C987654321',  N'Emma',   N'Johnson',  '1999-07-15', 2, 'GBR');
GO

UPDATE PASSENGER
SET Citizenship = 'GBR'
WHERE DocumentNumber = 'AB987654321';
GO

SELECT * FROM PASSENGER

-- Таблица CREW
INSERT INTO CREW
    (LicenseNumber, FirstName, LastName, Gender, Position, FlyingHours, LicenseExpiryDate)
VALUES
    ('RU-PLT-111111',  N'Aleksei', N'Petrov',      1, 1, 5230.50, '2028-03-15'),
    ('RU-PLT-222222',  N'Sergei',  N'Ilin',        1, 1, 4120.75, '2027-10-01'),
    ('RU-PLT-333333',  N'Ivan',    N'Menshikov',   1, 1, 3890.20, '2029-05-30'), 
    ('RU-PLT-444444',  N'Maria',   N'Kuznetsova',  2, 1, 4500.00, '2029-11-20'), 
    ('RU-FO-555555',   N'Dmitrii', N'Sokolov',     1, 2, 2750.00, '2027-04-10'), 
    ('RU-FA-666666',   N'Olga',    N'Sidorova',    2, 3,  980.25, '2026-06-30'), 
    ('RU-SFA-777777',  N'Elena',   N'Morozova',    2, 4, 1540.00, '2029-01-20'), 
    ('RU-FO-888888',   N'Maksim',  N'Voronov',     1, 2, 3100.50, '2028-09-05'); 
GO

SELECT * FROM CREW

-- Таблица TICKET
INSERT INTO TICKET
    (TicketNumber, Price, BookingDate, SeatNumber, ClassOfService, BaggageWeight, HandLuggageWeight, FlightID, PassengerID)
SELECT
    'SU101-000001', 8000, '2025-01-04', '10A', 1, 18.00, 7.00, F.FlightID, P.PassengerID
FROM FLIGHT F
CROSS JOIN PASSENGER P
WHERE F.FlightNumber   = 'SU101'      
  AND P.DocumentNumber = '4010 123456'; 
GO

INSERT INTO TICKET
    (TicketNumber, Price, BookingDate, SeatNumber, ClassOfService,
     BaggageWeight, HandLuggageWeight, FlightID, PassengerID)
VALUES
    ('SU102-000001', 9000, '2025-01-06', '13A', 2, 20.00, 10.00, 2, 2),
    ('SU102-000002', 9100, '2025-01-06', '14B', 1, 18.00, 7.00, 2, 3),
    ('SU102-000003', 9100, '2025-01-07', '14C', 1, NULL, 5.00, 2, 3);
GO

INSERT INTO TICKET
    (TicketNumber, Price, BookingDate, SeatNumber, ClassOfService,
     BaggageWeight, HandLuggageWeight, FlightID, PassengerID)
VALUES
    ('UT202-000001', 8500, '2025-01-05', '12A', 2, NULL, 8.00, 3, 4),
    ('UT202-000002', 8600, '2025-01-05', '12B', 2, 15.00, 6.00, 3, 4);
GO

INSERT INTO TICKET
    (TicketNumber, Price, BookingDate, SeatNumber, ClassOfService,
     BaggageWeight, HandLuggageWeight, FlightID, PassengerID)
VALUES
    ('DP305-000001', 12000, '2025-01-08', '2C', 3, 25.00, 15.00, 4, 5);
GO

SELECT * FROM TICKET

-- Таблица FLIGHT_CREW 
INSERT INTO FLIGHT_CREW (FlightID, CrewID)
VALUES
    (1, 1),
    (1, 5),
    (2, 2), 
    (2, 6),
    (3, 3),  
    (3, 7), 
    (4, 4),
    (4, 8);
GO

SELECT * FROM FLIGHT_CREW 

-- DISTINCT: вывод производителей без повторений
SELECT DISTINCT
    Manufacturer
FROM AIRCRAFT;
GO

-- ORDER BY: сортировки по часам налета от большего к меньшему с помощью DESC
SELECT
    FirstName + ' ' + LastName AS FullName,
    Position,
    FlyingHours
FROM CREW
ORDER BY FlyingHours DESC;
GO

-- ORDER BY: сортировка по дате рождения от большего к меньшему с помощью ASC
SELECT
    FirstName + ' ' + LastName AS FullName,
    DateOfBirth,
    Citizenship
FROM PASSENGER
ORDER BY DateOfBirth ASC;
GO

-- INNER JOIN: рейсы и задействованные в них самолёты
SELECT
    F.FlightNumber,
    F.FlightDate,
    F.DepartureAirport,
    F.ArrivalAirport,
    A.BoardNumber,
    A.Model
FROM FLIGHT AS F
    INNER JOIN AIRCRAFT AS A
        ON F.AircraftID = A.AircraftID;
GO

-- LEFT JOIN: все пассажиры и их билеты
SELECT
    P.FirstName + ' ' + P.LastName AS PassengerName,
    P.DocumentNumber,
    T.TicketNumber,
    T.SeatNumber,
    T.FlightID
FROM PASSENGER AS P
    LEFT JOIN TICKET AS T
        ON P.PassengerID = T.PassengerID;
GO

-- RIGHT JOIN: все билеты и соответствующие им пассажиры
SELECT
    T.TicketNumber,
    T.SeatNumber,
    T.FlightID,
    P.FirstName + ' ' + P.LastName AS PassengerName,
    P.DocumentNumber
FROM PASSENGER AS P
    RIGHT JOIN TICKET AS T
        ON P.PassengerID = T.PassengerID;
GO

-- FULL OUTER JOIN: все рейсы и все билеты на них
SELECT
    F.FlightNumber,
    F.FlightDate,
    F.DepartureAirport,
    F.ArrivalAirport,
    T.TicketNumber,
    T.SeatNumber,
    T.PassengerID
FROM FLIGHT AS F
    FULL OUTER JOIN TICKET AS T
        ON F.FlightID = T.FlightID;
GO

-- LIKE: поиск рейсов авиакомпаний, код которых начинается на 'S'
SELECT
    FlightNumber,
    FlightDate,
    DepartureAirport,
    ArrivalAirport,
    Airline
FROM FLIGHT
WHERE Airline LIKE 'S%';
GO

-- BETWEEN: пассажиры, родившиеся в заданном диапазоне дат
SELECT
    FirstName + ' ' + LastName AS PassengerName,
    DateOfBirth,
    Citizenship
FROM PASSENGER
WHERE DateOfBirth BETWEEN '1985-01-01' AND '1994-12-31';
GO

-- IN: члены экипажа с определёнными должностями
SELECT
    FirstName + ' ' + LastName AS CrewName,
    Position,
    FlyingHours,
    Gender
FROM CREW
WHERE Position IN (1, 2);
GO

-- EXISTS: члены экипажа, которые уже были назначены хотя бы на один рейс
SELECT
    C.FirstName + ' ' + C.LastName AS CrewName,
    C.Position,
    C.FlyingHours,
    C.LicenseExpiryDate
FROM CREW AS C
WHERE EXISTS (
    SELECT 1
    FROM FLIGHT_CREW AS FC
    WHERE FC.CrewID = C.CrewID
);
GO

-- NULL: билеты без зарегистрированного багажа 
SELECT
    TicketNumber,
    SeatNumber,
    FlightID,
    PassengerID,
    BaggageWeight,
    HandLuggageWeight
FROM TICKET
WHERE BaggageWeight IS NULL;
GO

-- GROUP BY + COUNT: Количество выполненных рейсов для каждого борта 
SELECT
    A.BoardNumber,
    A.Model,
    F.Airline,
    COUNT(F.FlightID) AS FlightCount
FROM AIRCRAFT AS A
    JOIN FLIGHT AS F
        ON F.AircraftID = A.AircraftID
GROUP BY
    A.BoardNumber,
    A.Model,
    F.Airline;
GO

-- HAVING + COUNT: Авиакомпании, у которых выполнялось более одного рейса
SELECT
    F.Airline,
    COUNT(F.FlightID) AS FlightsPerAirline
FROM FLIGHT AS F
GROUP BY
    F.Airline
HAVING
    COUNT(F.FlightID) > 1;
GO

-- SUM, MIN, MAX, AVG: Суммарная, минимальная, максимальная и средняя стоимость билетов по каждому рейсу
SELECT
    F.FlightNumber,
    SUM(T.Price) AS SumTicketsPrice,    
    MIN(T.Price) AS MinTicketPrice, 
    MAX(T.Price) AS MaxTicketPrice,
    AVG(T.Price) AS AvgTicketPrice 
FROM FLIGHT AS F
    JOIN TICKET AS T 
        ON F.FlightID = T.FlightID
GROUP BY
    F.FlightNumber;
GO

-- COUNT по пассажирам: Количество билетов у каждого пассажира
SELECT
    P.FirstName + ' ' + P.LastName AS PassengerName,
    P.DocumentNumber,
    COUNT(T.TicketID) AS TicketCount
FROM PASSENGER AS P
    LEFT JOIN TICKET AS T 
        ON P.PassengerID = T.PassengerID
GROUP BY
    P.FirstName,
    P.LastName,
    P.DocumentNumber;
GO

-- UNION: все аэропорты вылета и прилёта со всех рейсов без повторов
SELECT
    F.DepartureAirport AS AirportCode,
    'DEPARTURE'        AS AirportRole
FROM FLIGHT AS F
UNION
SELECT
    F.ArrivalAirport   AS AirportCode,
    'ARRIVAL'          AS AirportRole
FROM FLIGHT AS F;
GO

-- UNION ALL: все аэропорты вылета и прилёта со всех рейсов с повторами
SELECT
    F.DepartureAirport AS AirportCode,
    'DEPARTURE'        AS AirportRole
FROM FLIGHT AS F
UNION ALL
SELECT
    F.ArrivalAirport   AS AirportCode,
    'ARRIVAL'          AS AirportRole
FROM FLIGHT AS F;
GO

-- EXCEPT: имена членов экипажа, которых НЕТ среди пассажиров
SELECT
    C.FirstName + N' ' + C.LastName AS Name
FROM CREW AS C
EXCEPT
SELECT
    P.FirstName + N' ' + P.LastName AS Name
FROM PASSENGER AS P;
GO

-- INTERSECT: имена, которые одновременно встречаются и у пассажиров, и у членов экипажа
SELECT
    C.FirstName + N' ' + C.LastName AS Name
FROM CREW AS C
INTERSECT
SELECT
    P.FirstName + N' ' + P.LastName AS Name
FROM PASSENGER AS P;
GO

-- Триггер: пассажиры, у которых после удаления билетов их не осталось, удаляются из PASSENGER
IF OBJECT_ID(N'trigger_Delete_PassengerWithoutTicket') IS NOT NULL
    DROP TRIGGER trigger_Delete_PassengerWithoutTicket;
GO

CREATE TRIGGER trigger_Delete_PassengerWithoutTicket
ON TICKET
AFTER DELETE
AS
BEGIN
    -- пассажиры, которых затронуло удаление
    WITH AffectedPassengers AS (
        SELECT DISTINCT PassengerID
        FROM deleted
        WHERE PassengerID IS NOT NULL
    )
    DELETE P
    FROM PASSENGER AS P
        JOIN AffectedPassengers AS AP
            ON P.PassengerID = AP.PassengerID
    WHERE NOT EXISTS (
        SELECT 1
        FROM TICKET AS T
        WHERE T.PassengerID = P.PassengerID
    );
END;
GO

--DELETE FROM TICKET
--WHERE TicketNumber = 'SU101-000001';
--GO

--SELECT
--    P.PassengerID,
--    P.FirstName,
--    P.LastName,
--    P.DocumentNumber
--FROM PASSENGER AS P
--WHERE P.DocumentNumber = '4010 123456';

--SELECT
--    T.TicketID,
--    T.TicketNumber,
--    T.PassengerID
--FROM TICKET AS T
--WHERE T.TicketNumber = 'SU101-000001';
--GO

-- 7) Хранимая процедура для получения всех билетов, связанных с конкретным пассажиром
IF OBJECT_ID(N'GetPassengerTickets', N'P') IS NOT NULL
    DROP PROCEDURE GetPassengerTickets;
GO

CREATE PROCEDURE GetPassengerTickets
    @PassengerID INT
AS
BEGIN
    SELECT
        P.PassengerID,
        P.FirstName + N' ' + P.LastName AS PassengerFullName,
        P.DocumentNumber,
        T.TicketID,
        T.TicketNumber,
        T.Price,
        T.BookingDate,
        T.SeatNumber,
        T.ClassOfService,
        T.BaggageWeight,
        T.HandLuggageWeight,
        F.FlightID,
        F.FlightNumber,
        F.FlightDate,
        F.DepartureAirport,
        F.ArrivalAirport,
        F.BoardingTime,
        F.DepartureTime,
        F.ArrivalTime,
        F.Airline
    FROM TICKET AS T
        INNER JOIN PASSENGER AS P
            ON T.PassengerID = P.PassengerID
        INNER JOIN FLIGHT AS F
            ON T.FlightID = F.FlightID
    WHERE T.PassengerID = @PassengerID
    ORDER BY
        F.FlightDate,
        F.FlightNumber,
        T.TicketNumber;
END;
GO

EXEC GetPassengerTickets @PassengerID = 3;
GO

-- Скалярная функция: количество членов экипажа для указанного рейса
IF OBJECT_ID(N'function_GetCrewCountForFlight') IS NOT NULL
    DROP FUNCTION function_GetCrewCountForFlight;
GO

CREATE FUNCTION function_GetCrewCountForFlight
(
    @FlightID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @CrewCount INT;
    SELECT @CrewCount = COUNT(*)
    FROM FLIGHT_CREW FC
    WHERE FC.FlightID = @FlightID;
    RETURN @CrewCount;
END;
GO

SELECT dbo.function_GetCrewCountForFlight(1) AS CrewCountForFlight;
GO

-- Табличная функция: все билеты, связанные с указанным рейсом
IF OBJECT_ID(N'function_GetTicketsByFlight') IS NOT NULL
    DROP FUNCTION function_GetTicketsByFlight;
GO

CREATE FUNCTION function_GetTicketsByFlight
(
    @FlightID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        T.TicketID,
        T.TicketNumber,
        T.Price,
        T.BookingDate,
        T.SeatNumber,
        T.ClassOfService,
        T.BaggageWeight,
        T.HandLuggageWeight,
        P.PassengerID,
        P.FirstName + N' ' + P.LastName AS PassengerFullName,
        P.DocumentNumber,
        F.FlightNumber,
        F.FlightDate,
        F.DepartureAirport,
        F.ArrivalAirport,
        F.Airline
    FROM TICKET AS T
        INNER JOIN PASSENGER AS P
            ON T.PassengerID = P.PassengerID
        INNER JOIN FLIGHT AS F
            ON T.FlightID = F.FlightID
    WHERE T.FlightID = @FlightID
);
GO

SELECT *
FROM dbo.function_GetTicketsByFlight(3);
GO

-- Таблица для логирования вставок билетов
IF OBJECT_ID(N'TicketLog') IS NOT NULL
    DROP TABLE TicketLog;
GO

CREATE TABLE TicketLog
(
    LogID       INT IDENTITY(1,1) PRIMARY KEY,
    TicketID    INT,               
    PassengerID INT,               
    FlightID    INT,               
    Action      NVARCHAR(50),      
    LogDate     DATETIME DEFAULT GETDATE()
);
GO

-- Триггер на вставку билетов: проверка корректности и логирование вставки
IF OBJECT_ID(N'trigger_Insert_Ticket') IS NOT NULL
    DROP TRIGGER trigger_Insert_Ticket;
GO

CREATE TRIGGER trigger_Insert_Ticket
ON TICKET
AFTER INSERT
AS
BEGIN
    -- Проверка: дата бронирования не может быть позднее даты рейса
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN FLIGHT f
            ON i.FlightID = f.FlightID
        WHERE i.BookingDate > f.FlightDate
    )
    BEGIN
        RAISERROR (N'Дата бронирования не может быть позднее даты рейса.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    -- Логирование вставки билетов
    INSERT INTO TicketLog
        (TicketID, PassengerID, FlightID, Action)
    SELECT
        i.TicketID,
        i.PassengerID,
        i.FlightID,
        N'INSERT'
    FROM inserted AS i;
END;
GO

INSERT INTO TICKET
    (TicketNumber, Price, BookingDate, SeatNumber, ClassOfService,
     BaggageWeight, HandLuggageWeight, FlightID, PassengerID)
VALUES
    ('SU102-000010', 9500, '2025-01-05', '16A', 1,
     20.00, 7.00, 2, 2);
GO

SELECT *
FROM TicketLog;
GO

-- вставка с ошибочными данными (дата бронирования позже даты рейса)
--INSERT INTO TICKET
--    (TicketNumber, Price, BookingDate, SeatNumber, ClassOfService,
--     BaggageWeight, HandLuggageWeight, FlightID, PassengerID)
--VALUES
--    ('SU102-000011', 9600, '2025-01-12', '16B', 1,
--     18.00, 7.00, 2, 2); 
--GO
