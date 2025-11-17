-- Лабораторная работа 6
USE master;
GO

IF DB_ID(N'Lab6') IS NOT NULL
BEGIN
    DROP DATABASE Lab6;
    PRINT 'Existing database Lab6 has been deleted';
END
ELSE
BEGIN
    PRINT 'Database Lab6 not found';
END
GO

CREATE DATABASE Lab6
ON ( NAME = Lab6_dat,
    FILENAME = 'D:\database\lab6\Lab6_log.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab6_log,
    FILENAME = 'D:\database\lab6\Lab6_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab6;
GO

-- Task 1:
IF OBJECT_ID('dbo.AIRCRAFT', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AIRCRAFT
    (
        AircraftID INT PRIMARY KEY IDENTITY(1,1),
        BoardNumber VARCHAR(8) NOT NULL,
        Model NVARCHAR(10) NOT NULL,
        Manufacturer NVARCHAR(20) NOT NULL,
        PassengerCapacity SMALLINT NOT NULL,
        LoadCapacity NUMERIC(6,2) NOT NULL,
        AircraftAge TINYINT NOT NULL,
        Status TINYINT NOT NULL,
        CONSTRAINT AK_BoardNumber UNIQUE (BoardNumber)
    );
END;
GO

-- Task 2:
IF OBJECT_ID('dbo.FLIGHT', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FLIGHT
    (
        FlightID INT PRIMARY KEY IDENTITY(1,1),
        FlightNumber VARCHAR(5) NOT NULL,
        FlightDate Date NOT NULL,
        Airline CHAR(2) NOT NULL,
        DepartureAirport CHAR(3) NOT NULL,
        ArrivalAirport CHAR(3) NOT NULL,
        BoardingTime DATETIME NOT NULL,
        DepartureTime DATETIME NOT NULL,
        ArrivalTime DATETIME NOT NULL,
        Status TINYINT NOT NULL DEFAULT 1 CHECK(Status > 0 AND Status < 6),
        AircraftID INT NOT NULL,
        CONSTRAINT AK_Flight UNIQUE (FlightNumber, FlightDate),
        CONSTRAINT FK_AircraftID FOREIGN KEY (AircraftID) REFERENCES dbo.AIRCRAFT(AircraftID)
    );
END;
GO

-- Task 3:
