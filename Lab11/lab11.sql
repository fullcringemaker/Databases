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
LOG ON (NAME = Lab_9log,
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
    FROM AIRCRAFT A
        LEFT JOIN FLIGHT F
            ON F.AircraftID = A.AircraftID;
GO

-- Триггер для вставки через представления
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
        FROM AIRCRAFT A
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
    FROM inserted i
        INNER JOIN AIRCRAFT A
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
    ('ABCD1234', 'A320', 180, 2000.00, 5, 1, N'Airbus',
     'SU101', '2025-01-10', 'SVO', 'LED', '2025-01-10 07:30', '2025-01-10 08:00', '2025-01-10 09:30', 1, 'SU'),
    ('ABCD1234', 'A320', 180, 2000.00, 5, 1, N'Airbus',
     'SU102', '2025-01-11', 'SVO', 'LED', '2025-01-10 07:30', '2025-01-10 08:00', '2025-01-10 09:30', 1, 'SU'),
    ('EFGH5678', 'B737', 160, 1800.00, 7, 1, N'Boeing',
     'UT202', '2025-01-11', 'LED', 'DME', '2025-01-11 12:00', '2025-01-11 12:30', '2025-01-11 14:00', 1, 'UT');
GO

SELECT *
FROM view_AircraftWithFlight;
GO

SELECT * 
FROM FLIGHT 
GO

-- Триггер для удаления самолетов из AIRCRAFT
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
    FROM AIRCRAFT A
    JOIN deleted d
      ON A.AircraftID = d.AircraftID;
END;
GO

--DELETE FROM AIRCRAFT
--WHERE AircraftID = 1;

INSERT INTO AIRCRAFT (BoardNumber, Model, PassengerCapacity, LoadCapacity, AircraftAge, Status, Manufacturer)
VALUES ('RA12345', 'SSJ-100', 98, 1200.00, 3, 1, N'Иркут');
GO

DELETE FROM AIRCRAFT
WHERE BoardNumber = 'RA12345';
GO

-- Триггер для обновления статуса самолетов из AIRCRAFT
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
        FROM inserted i
        JOIN deleted d
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
    FROM AIRCRAFT A
    JOIN inserted i
      ON A.AircraftID = i.AircraftID;
END;
GO

--UPDATE AIRCRAFT
--SET Status = 2
--WHERE AircraftID = 1;
--GO

INSERT INTO AIRCRAFT (BoardNumber, Model, PassengerCapacity, LoadCapacity, AircraftAge, Status, Manufacturer)
VALUES ('RA67890', 'A321', 220, 2100.00, 4, 1, N'Airbus');
GO

UPDATE AIRCRAFT
SET Status = 2
WHERE BoardNumber = 'RA67890';
GO

SELECT *
FROM AIRCRAFT
GO

-- Таблица PASSENGER
INSERT INTO PASSENGER
    (DocumentNumber, FirstName, LastName, DateOfBirth, Gender, Citizenship)
VALUES
    ('4010 123456', N'Ivan',   N'Ivanov',  '1990-05-12', 1, 'RUS'),
    ('4010 654321', N'Anna',   N'Petrova', '1995-09-03', 2, 'RUS'),
    ('AB987654321', N'John',  N'Smith',    '1988-12-02', 1, 'USA');
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
    ('RU-PLT-123456',  N'Aleksei', N'Petrov',      1, 1, 5230.50, '2028-03-15'),
    ('RU-FO-234567',   N'Sergei',  N'Ilin',        1, 2, 3120.75, '2027-10-01'),
    ('RU-FA-345678',   N'Olga',    N'Sidorova',    2, 3,  980.25, '2026-06-30'),
    ('RU-SFA-456789',  N'Maria',   N'Kuznetsova',  2, 4, 1540.00, '2029-01-20'); 
GO

SELECT * FROM CREW

-- Таблица TICKET
INSERT INTO TICKET
    (TicketNumber, Price, BookingDate, SeatNumber, ClassOfService, BaggageWeight, HandLuggageWeight, FlightID, PassengerID)
SELECT
    'SU101-000001', 8500, '2025-01-05', '12A', 1, 20.00, 8.00, F.FlightID, P.PassengerID
FROM FLIGHT F
CROSS JOIN PASSENGER P
WHERE F.FlightNumber = 'UT202' AND P.DocumentNumber = '4010 654321'; 
GO

SELECT * FROM TICKET

