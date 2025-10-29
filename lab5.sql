USE master;
GO

IF DB_ID(N'Lab5') IS NOT NULL
BEGIN
    DROP DATABASE Lab5;
    PRINT 'The existing Lab5 database has been deleted';
END
ELSE
BEGIN
    PRINT 'The lab5 database was not found';
END
GO

-- Task 1:
CREATE DATABASE Lab5
ON ( NAME = lab5_dat,
    FILENAME = 'D:\database\lab5\Lab5_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5% )
LOG ON ( NAME = lab5_log,
    FILENAME = 'D:\database\lab5\Lab5_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB );
GO

-- Task 2:
USE Lab5;
GO
IF OBJECT_ID(N'AIRCRAFT') IS NOT NULL
BEGIN
    DROP TABLE AIRCRAFT;
    PRINT 'The existing AIRCRAFT table has been deleted';
END
GO

CREATE TABLE AIRCRAFT
(
    AircraftID INT PRIMARY KEY,
    BoardNumber VARCHAR(8) NOT NULL,
    Model NVARCHAR(10) NOT NULL,
    Manufacturer NVARCHAR(20) NOT NULL,
    PassengerCapacity SMALLINT NOT NULL,
    LoadCapacity NUMERIC(6,2) NOT NULL,
    AircraftAge TINYINT NOT NULL,
    Status TINYINT NOT NULL,
    CONSTRAINT AK_BoardNumber UNIQUE (BoardNumber)
);
GO

SELECT *
FROM AIRCRAFT; 
GO

-- Task 3:
ALTER DATABASE Lab5
ADD FILEGROUP LargeFileGroup;  
GO

ALTER DATABASE Lab5
ADD FILE(
    NAME = Lab5_LargeData,  
    FILENAME = 'D:\database\lab5\Lab5_dat2.ndf',  
    SIZE = 5MB,  
    MAXSIZE = 25MB,  
    FILEGROWTH = 5%
)
TO FILEGROUP LargeFileGroup;
GO

-- Task 4:
ALTER DATABASE Lab5
    MODIFY FILEGROUP LargeFileGroup DEFAULT;
GO

-- Task 5:
IF OBJECT_ID(N'FLIGHT') IS NOT NULL
BEGIN
    DROP TABLE FLIGHT;
    PRINT 'Existing FLIGHT table has been deleted';
END
GO

CREATE TABLE FLIGHT
(
    FlightID INT PRIMARY KEY,
    FlightNumber VARCHAR(5) NOT NULL,
    FlightDate Date NOT NULL,
    Airline CHAR(2) NOT NULL,
    DepartureAirport CHAR(3) NOT NULL,
    ArrivalAirport CHAR(3) NOT NULL,
    BoardingTime DATETIME NOT NULL,
    DepartureTime DATETIME NOT NULL,
    ArrivalTime DATETIME NOT NULL, 
    Status TINYINT NOT NULL,
    AircraftID INT NOT NULL,
    CONSTRAINT AK_Flight UNIQUE (FlightNumber, FlightDate),
    CONSTRAINT FK_AircraftID FOREIGN KEY (AircraftID) REFERENCES AIRCRAFT(AircraftID)
);
GO

SELECT *
FROM FLIGHT;
GO

INSERT INTO AIRCRAFT
    (AircraftID, BoardNumber, Model, Manufacturer, PassengerCapacity, LoadCapacity, AircraftAge, Status)
VALUES
    (152, 'PH-ABC', 'A320neo', 'Airbus', 165, 9500.00, 7, 1);
GO

INSERT INTO FLIGHT
    (FlightID, FlightNumber, FlightDate, Airline, DepartureAirport, ArrivalAirport, BoardingTime, DepartureTime, ArrivalTime, Status, AircraftID)
VALUES
    (1001, 'KL456', '2025-10-29', 'KL', 'AMS', 'BCN', '2025-10-29T13:20:00', '2025-10-29T14:00:00', '2025-10-29T15:45:00', 1, 152);
GO

SELECT *
FROM AIRCRAFT;
GO

SELECT *
FROM FLIGHT;
GO

-- Task 6:
ALTER DATABASE Lab5
    MODIFY FILEGROUP [PRIMARY] DEFAULT;
GO

IF OBJECT_ID(N'saveFLIGHT') IS NOT NULL
    DROP TABLE saveFLIGHT;
GO

SELECT *
INTO saveFLIGHT
FROM FLIGHT;
GO

DROP TABLE FLIGHT;
GO

ALTER DATABASE Lab5
    REMOVE FILE Lab5_LargeData;
GO

ALTER DATABASE Lab5
    REMOVE FILEGROUP LargeFileGroup;
GO

-- Task 7:
IF SCHEMA_ID(N'BuildingSchema') IS NOT NULL
BEGIN
    DROP SCHEMA BuildingSchema;
    PRINT 'The existing BuildingSchema schema has been deleted';
END
GO

CREATE SCHEMA BuildingSchema;
GO

ALTER SCHEMA BuildingSchema 
    TRANSFER AIRCRAFT;
GO

IF OBJECT_ID(N'BuildingSchema.AIRCRAFT') IS NOT NULL
BEGIN
    DROP TABLE BuildingSchema.AIRCRAFT;
    PRINT 'The existing BuildingSchema.AIRCRAFT table has been deleted';
END
GO

DROP SCHEMA BuildingSchema;
GO

