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
IF OBJECT_ID('dbo.Seq_CrewID', 'SO') IS NULL
    CREATE SEQUENCE dbo.Seq_CrewID AS INT START WITH 1 INCREMENT BY 1;
GO

IF OBJECT_ID('dbo.Crew', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Crew
    (
        CrewID INT PRIMARY KEY DEFAULT NEXT VALUE FOR dbo.Seq_CrewID,
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
IF OBJECT_ID('dbo.ParentTable', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ParentTable
    (
        ParentID INT PRIMARY KEY IDENTITY(1,1),
        ParentName NVARCHAR(100) NOT NULL
    );
END;
GO

-- NO ACTION
IF OBJECT_ID('dbo.ChildTableWithNoAction', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChildTableWithNoAction
    (
        ChildID INT PRIMARY KEY IDENTITY(1,1),
        ParentID INT,
        Description NVARCHAR(200),
        CONSTRAINT FK_ParentChildWithNoAction FOREIGN KEY (ParentID) 
        REFERENCES dbo.ParentTable(ParentID) ON DELETE NO ACTION ON UPDATE NO ACTION
    );
END;
GO

-- CASCADE
IF OBJECT_ID('dbo.ChildTableWithCascade', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChildTable_Cascade
    (
        ChildID INT PRIMARY KEY IDENTITY(1,1),
        ParentID INT,
        Description NVARCHAR(200),
        CONSTRAINT FK_ParentChildWithCascade FOREIGN KEY (ParentID) 
        REFERENCES dbo.ParentTable(ParentID) ON DELETE CASCADE ON UPDATE NO ACTION
    );
END;
GO

-- SET NULL
IF OBJECT_ID('dbo.ChildTableWithSetNull', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChildTableWithSetNull
    (
        ChildID INT PRIMARY KEY IDENTITY(1,1),
        ParentID INT NULL,
        Description NVARCHAR(200),
        CONSTRAINT FK_ParentChildWithSetNull FOREIGN KEY (ParentID) 
        REFERENCES dbo.ParentTable(ParentID) ON DELETE SET NULL ON UPDATE NO ACTION
    );
END;
GO

-- SET DEFAULT
IF OBJECT_ID('dbo.ChildTableWithSetDefault', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChildTableWithSetDefault
    (
        ChildID INT PRIMARY KEY IDENTITY(1,1),
        ParentID INT DEFAULT 1,
        Description NVARCHAR(200),
        CONSTRAINT FK_ParentChildWithSetDefault FOREIGN KEY (ParentID) 
        REFERENCES dbo.ParentTable(ParentID) ON DELETE SET DEFAULT ON UPDATE NO ACTION
    );
END;
GO

-- Проверка 
