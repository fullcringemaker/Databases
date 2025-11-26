-- Лабораторная работа 6
USE master;
GO

IF DB_ID(N'Lab6') IS NOT NULL
BEGIN
    ALTER DATABASE Lab6 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
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
    ('N123AB', 'A320neo', N'Airbus', 180, 9000.00, 3, 1);
GO

SELECT * FROM AIRCRAFT;

SELECT SCOPE_IDENTITY() AS ScopeIdentity;

-- Task 2:
IF OBJECT_ID('dbo.FLIGHT', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FLIGHT
    (
        FlightID INT NOT NULL PRIMARY KEY IDENTITY(1,1),      
        FlightNumber VARCHAR(5) NOT NULL,         
        FlightDate DATE NOT NULL DEFAULT (SYSDATETIME()),        
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
    (FlightNumber, Airline, DepartureAirport, ArrivalAirport, BoardingTime, DepartureTime, ArrivalTime, Status, AircraftID)
VALUES
    ('KL120', 'KL', 'AMS', 'BCN', '2025-11-20T07:15:00', '2025-11-20T08:00:00', '2025-11-20T10:45:00', 2, 1)
GO

INSERT INTO dbo.FLIGHT
    (FlightNumber, FlightDate, Airline, DepartureAirport, ArrivalAirport, BoardingTime, DepartureTime, ArrivalTime, AircraftID)
VALUES
    ('KL121', '2025-11-21', 'KL', 'AMS', 'BCN', '2025-11-20T07:15:00', '2025-11-20T08:00:00', '2025-11-20T10:45:00', 1)
GO

SELECT * FROM dbo.FLIGHT;

-- Task 3:
IF OBJECT_ID('dbo.CREW', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CREW
    (
        CrewID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        LicenseNumber VARCHAR(15) NOT NULL,    
        FirstName NVARCHAR(30) NOT NULL,
        LastName  NVARCHAR(30) NOT NULL,
        Gender TINYINT NOT NULL CHECK (Gender IN (1, 2)),
        Position TINYINT NOT NULL CHECK (Position IN (1, 2, 3, 4)),
        FlyingHours DECIMAL(6,2) NOT NULL CHECK (FlyingHours >= 0),
        LicenseExpiryDate DATE NOT NULL,
        CONSTRAINT AK_LicenseNumber UNIQUE (LicenseNumber),
    );
END;
GO

INSERT INTO dbo.CREW
    (LicenseNumber, FirstName, LastName, Gender, Position, FlyingHours, LicenseExpiryDate)
VALUES
    ('RU-ATPL-001',  N'Алексей',  N'Иванов',   1, 1,  8500.50, '2029-03-15'),
    ('RU-CPL-045',   N'Мария',    N'Петрова',  2, 2,  3200.75, '2027-11-20');
GO

SELECT * FROM dbo.CREW

-- Task 4:
IF OBJECT_ID('dbo.SeqPassengerID', 'SO') IS NULL
    CREATE SEQUENCE dbo.SeqPassengerID AS INT START WITH 1 INCREMENT BY 1;
GO

IF OBJECT_ID('dbo.PASSENGER', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PASSENGER
    (
        PassengerID INT PRIMARY KEY DEFAULT NEXT VALUE FOR dbo.SeqPassengerID,
        DocumentNumber VARCHAR(14) NOT NULL,       
        FirstName NVARCHAR(30) NOT NULL,
        LastName NVARCHAR(30) NOT NULL,
        DateOfBirth DATE NOT NULL,
        Gender TINYINT NOT NULL CHECK (Gender IN (1,2)),      
        Citizenship CHAR(3) NOT NULL,
        CONSTRAINT AK_DocumentNumber UNIQUE (DocumentNumber),
    );
END;
GO

INSERT INTO dbo.PASSENGER
    (DocumentNumber, FirstName, LastName, DateOfBirth, Gender, Citizenship)
VALUES
    ('45 12 345678', N'Алексей',  N'Иванов',   '1990-03-15', 1, 'RUS'),
    ('40 09 112233', N'Мария',    N'Петрова',  '1995-11-20', 2, 'RUS'),
    ('45001234567894', N'Дмитрий',  N'Смирнов',  '1988-07-02', 1, 'BLR');
GO

SELECT * FROM dbo.PASSENGER;
GO

-- Task 5:
-- NO ACTION
CREATE TABLE dbo.parent_noaction
(
    ParentID INT PRIMARY KEY,
    ParentName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.child_noaction
(
    ChildID INT PRIMARY KEY,
    ParentID INT NOT NULL,
    ChildName NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_child_noaction_parent FOREIGN KEY (ParentID) REFERENCES dbo.parent_noaction(ParentID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

INSERT INTO dbo.parent_noaction (ParentID, ParentName)
VALUES 
    (1, N'Родитель 1'), 
    (2, N'Родитель 2');
GO

INSERT INTO dbo.child_noaction (ChildID, ParentID, ChildName)
VALUES 
    (10, 1, N'Ребёнок A'),
    (11, 2, N'Ребёнок B');
GO

SELECT * FROM dbo.child_noaction;
GO

DELETE FROM dbo.child_noaction WHERE ParentID = 1;
DELETE FROM dbo.parent_noaction WHERE ParentID = 1;
GO

SELECT * FROM dbo.child_noaction;
GO

-- CASCADE
CREATE TABLE dbo.parent_cascade
(
    ParentID INT PRIMARY KEY,
    ParentName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.child_cascade
(
    ChildID INT PRIMARY KEY,
    ParentID INT NOT NULL,
    ChildName NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_child_cascade_parent FOREIGN KEY (ParentID) REFERENCES dbo.parent_cascade(ParentID)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
);
GO

INSERT INTO dbo.parent_cascade (ParentID, ParentName)
VALUES 
    (1, N'Родитель 1'), 
    (2, N'Родитель 2');

INSERT INTO dbo.child_cascade (ChildID, ParentID, ChildName)
VALUES 
    (20, 1, N'Ребёнок A'), 
    (21, 1, N'Ребёнок B'),
    (22, 2, N'Ребёнок C');
GO

SELECT * FROM dbo.child_cascade;
GO

DELETE FROM dbo.parent_cascade WHERE ParentID = 1;
GO

SELECT * FROM dbo.child_cascade;   
GO

-- SET NULL
CREATE TABLE dbo.parent_setnull
(
    ParentID INT PRIMARY KEY,
    ParentName NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.child_setnull
(
    ChildID INT PRIMARY KEY,
    ParentID INT NULL,         
    ChildName NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_child_setnull_parent FOREIGN KEY (ParentID) REFERENCES dbo.parent_setnull(ParentID)
        ON DELETE SET NULL
        ON UPDATE NO ACTION
);
GO

INSERT INTO dbo.parent_setnull (ParentID, ParentName)
VALUES 
    (1, N'Родитель 1'),
    (2, N'Родитель 2');

INSERT INTO dbo.child_setnull (ChildID, ParentID, ChildName)
VALUES 
    (30, 1, N'Ребёнок A'),
    (31, 2, N'Ребёнок B');
GO

SELECT * FROM dbo.child_setnull;
GO

DELETE FROM dbo.parent_setnull WHERE ParentID = 1;
GO
 
SELECT * FROM dbo.child_setnull;
GO

-- SET DEFAULT
CREATE TABLE dbo.parent_setdefault
(
    ParentID INT PRIMARY KEY,
    ParentName NVARCHAR(50) NOT NULL
);
GO

INSERT INTO dbo.parent_setdefault (ParentID, ParentName)
VALUES 
    (0, N'Родитель 1'), 
    (1, N'Родитель 2'),
    (2, N'Родитель 3');
GO

CREATE TABLE dbo.child_setdefault
(
    ChildID INT PRIMARY KEY,
    ParentID INT NOT NULL DEFAULT 2,
    ChildName NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_child_setdefault_parent FOREIGN KEY (ParentID) REFERENCES dbo.parent_setdefault(ParentID)
        ON DELETE SET DEFAULT
        ON UPDATE NO ACTION
);
GO

INSERT INTO dbo.child_setdefault (ChildID, ParentID, ChildName)
VALUES 
    (40, 1, N'Ребёнок A'),
    (41, 1, N'Ребёнок B'),
    (42, 0, N'Ребёнок C');
GO

SELECT * FROM dbo.child_setdefault;
GO

DELETE FROM dbo.parent_setdefault WHERE ParentID = 1;
GO
  
SELECT * FROM dbo.child_setdefault;
GO
