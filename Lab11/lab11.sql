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

-- 2) Создание таблиц
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
    ON DELETE CASCADE ON UPDATE NO ACTION
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
    CONSTRAINT PK_FlightID FOREIGN KEY (FlightID) REFERENCES dbo.FLIGHT (FlightID)
    ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT PK_CrewID FOREIGN KEY (CrewID) REFERENCES dbo.CREW (CrewID)
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

-- создание триггера для вставки через представления
IF OBJECT_ID(N'trigger_insertAircraftWithFlight', N'TR') IS NOT NULL
    DROP TRIGGER trigger_insertAircraftWithFlight;
GO

CREATE TRIGGER trigger_insert_AircraftWithFlight
ON view_AircraftWithFlight
INSTEAD OF INSERT
AS
BEGIN
    WITH DistinctAircraft AS
    (
        -- взятие уникальных самолетов
        SELECT DISTINCT
            I.BoardNumber,
            I.Model,
            I.PassengerCapacity,
            I.LoadCapacity,
            I.AircraftAge,
            I.AircraftStatus,
            I.Manufacturer
        FROM INSERTED I
        WHERE I.BoardNumber IS NOT NULL
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
        I.FlightNumber,
        I.FlightDate,
        I.DepartureAirport,
        I.ArrivalAirport,
        I.BoardingTime,
        I.DepartureTime,
        I.ArrivalTime,
        I.FlightStatus,
        A.AircraftID,
        I.Airline
    FROM INSERTED I
        INNER JOIN AIRCRAFT A
            ON A.BoardNumber = I.BoardNumber;
END;
GO

--Запретить прямую вставку в AIRCRAFT
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

IF OBJECT_ID(N'trigger_delete_Ticket') IS NOT NULL
    DROP TRIGGER trigger_delete_Ticket;
GO

CREATE TRIGGER trigger_delete_Ticket
ON TICKET
AFTER DELETE
AS
BEGIN
    -- Проверка, что нельзя удалить последний билет пассажира
    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE NOT EXISTS (
            SELECT 1
            FROM TICKET t
            WHERE t.PassengerID = d.PassengerID
        )
    )
    BEGIN
        RAISERROR ('Нельзя удалить последний билет пассажира', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Удаление, если условие выполнено
    DELETE FROM TICKET
    WHERE TicketID IN (
        SELECT TicketID
        FROM DELETED);
END;
GO

DELETE FROM TICKET
WHERE TicketID = 3;
GO
