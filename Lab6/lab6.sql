-- Лабораторная работа 6
USE master;
GO

IF DB_ID(N'Lab6') IS NOT NULL
BEGIN
    DROP DATABASE Lab6;
END
GO

CREATE DATABASE Lab6
ON PRIMARY(
    NAME = Lab6_dat,
    FILENAME = 'D:\database\lab6\Lab6_dat.mdf', 
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
IF OBJECT_ID('dbo.CrewGUID', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CrewGUID
    (
        CrewGUID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        FirstName NVARCHAR(30),
        LatName NVARCHAR(30),
        Gender TINYINT,
        Position TINYINT,
        FlyingHours DECIMAL(6,2),
        LicenseExpiryDate DATE
    );
END;
GO

-- Task 4:
IF OBJECT_ID('dbo.SeqCrewID', 'SO') IS NULL
    CREATE SEQUENCE dbo.SeqCrewID AS INT START WITH 1 INCREMENT BY 1;
GO

IF OBJECT_ID('dbo.CREW', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CREW
    (
        CrewID INT PRIMARY KEY DEFAULT NEXT VALUE FOR dbo.SeqCrewID,
        LicenseNumber VARCHAR(15) UNIQUE NOT NULL,
        FirstName NVARCHAR(30) NOT NULL,
        LatName NVARCHAR(30) NOT NULL,
        Gender TINYINT NOT NULL,
        Position TINYINT NOT NULL,
        FlyingHours DECIMAL(6,2) NOT NULL,
        LicenseExpiryDate DATE Not NULL
    );
END;
GO

-- Task 5:


SELECT *
FROM dbo.CREW
