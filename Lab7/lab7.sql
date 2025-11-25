-- Лабораторная работа 7
USE master;
GO

IF DB_ID(N'Lab7') IS NOT NULL
BEGIN
    ALTER DATABASE Lab7 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Lab7;
END
GO

CREATE DATABASE Lab7
ON PRIMARY(
    NAME = Lab7_dat,
    FILENAME = 'D:\database\lab7\Lab7_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab7_log,
    FILENAME = 'D:\database\lab7\Lab7_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab7;
GO

-- Task 1:
IF OBJECT_ID('dbo.AIRCRAFT', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AIRCRAFT
    (
        AircraftID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
        BoardNumber VARCHAR(8) NOT NULL,
        Model NVARCHAR(10) NOT NULL,
        Manufacturer NVARCHAR(20) NOT NULL,
        PassengerCapacity SMALLINT NOT NULL,
        LoadCapacity NUMERIC(6,2) NOT NULL,
        AircraftAge TINYINT NOT NULL,
        Status TINYINT NOT NULL DEFAULT (1) CHECK (Status IN (1, 2)),
        CONSTRAINT AK_BoardNumber UNIQUE (BoardNumber),
    );
END;
GO

INSERT INTO dbo.AIRCRAFT
    (BoardNumber, Model, Manufacturer, PassengerCapacity, LoadCapacity, AircraftAge, Status)
VALUES
    ('N123AA', 'A320', N'Airbus', 200, 7000.00, 5, 2),
    ('N123AB', 'A320neo', N'Airbus', 180, 9000.00, 3, 1),
    ('N123AC', 'A320ff', N'Airbus', 220, 8000.00, 4, 1);
GO

CREATE VIEW  view_AIRCRAFT
AS
    SELECT 
        AircraftID,
        BoardNumber,
        Model,
        Manufacturer,
        PassengerCapacity,
        LoadCapacity,
        AircraftAge,
        Status
    FROM dbo.AIRCRAFT
    WHERE LoadCapacity > 8000
    WITH CHECK OPTION;
GO

SELECT * FROM view_AIRCRAFT
GO

-- Task 2:
IF OBJECT_ID('dbo.FLIGHT', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FLIGHT
    (
        FlightID INT NOT NULL PRIMARY KEY IDENTITY(1,1),      
        FlightNumber VARCHAR(5) NOT NULL,         
        FlightDate Date NOT NULL,        
        Airline CHAR(2) NOT NULL,        
        DepartureAirport CHAR(3) NOT NULL,
        ArrivalAirport CHAR(3) NOT NULL,
        BoardingTime DATETIME NOT NULL,
        DepartureTime DATETIME NOT NULL,
        ArrivalTime DATETIME NOT NULL,
        Status TINYINT NOT NULL DEFAULT 1 CHECK (Status IN (1, 2, 3, 4, 5)),  
        AircraftID INT NOT NULL,
        CONSTRAINT AK_Flight UNIQUE (FlightNumber, FlightDate),
        CONSTRAINT FK_AircraftID FOREIGN KEY (AircraftID) REFERENCES dbo.AIRCRAFT(AircraftID)
    );
END;
GO

INSERT INTO dbo.FLIGHT
    (FlightNumber, FlightDate, Airline, DepartureAirport, ArrivalAirport, BoardingTime, DepartureTime, ArrivalTime, Status, AircraftID)
VALUES
    ('KL120', '2025-11-20', 'KL', 'AMS', 'BCN', '2025-11-20T07:15:00', '2025-11-20T08:00:00', '2025-11-20T10:45:00', 2, 1)
GO

INSERT INTO dbo.FLIGHT
    (FlightNumber, FlightDate, Airline, DepartureAirport, ArrivalAirport, BoardingTime, DepartureTime, ArrivalTime, AircraftID)
VALUES
    ('KL121', '2025-11-21', 'KL', 'AMS', 'BCN', '2025-11-20T07:15:00', '2025-11-20T08:00:00', '2025-11-20T10:45:00', 1)
GO

CREATE VIEW view_FLIGHTwithAIRCRAFT
AS
    SELECT
        f.FlightID,
        f.FlightNumber,
        f.FlightDate,
        f.Airline,
        f.DepartureAirport,
        f.ArrivalAirport,
        f.BoardingTime,
        f.DepartureTime,
        f.ArrivalTime,
        f.Status        AS FlightStatus,
        a.AircraftID,
        a.BoardNumber,
        a.Model,
        a.Manufacturer,
        a.PassengerCapacity,
        a.LoadCapacity,
        a.AircraftAge,
        a.Status        AS AircraftStatus
    FROM FLIGHT AS f
    INNER JOIN dbo.AIRCRAFT AS a
    ON f.AircraftID = a.AircraftID;
GO

SELECT * FROM view_FLIGHTwithAIRCRAFT;
GO

-- Task 3:
CREATE NONCLUSTERED INDEX IDX_AIRCRAFT_AGE
ON dbo.AIRCRAFT (AircraftAge)
INCLUDE (LoadCapacity, PassengerCapacity);
GO

SELECT AircraftID, AircraftAge, LoadCapacity, PassengerCapacity
FROM dbo.AIRCRAFT
WHERE AircraftAge > 2;
GO

-- Task 4: 
SET QUOTED_IDENTIFIER ON;
GO

CREATE VIEW view_indexAIRCRAFT
WITH 
    SCHEMABINDING
AS
    SELECT
        AircraftID,
        BoardNumber,
        Model,
        Manufacturer,
        PassengerCapacity,
        LoadCapacity,
        AircraftAge,
        Status
    FROM dbo.AIRCRAFT;
GO

CREATE UNIQUE CLUSTERED INDEX IDX_indexAIRCRAFT
ON view_indexAIRCRAFT (AircraftID);
GO

SELECT * FROM view_indexAIRCRAFT;
GO
