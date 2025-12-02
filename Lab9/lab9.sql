-- Лабораторная работа 9
USE master;
GO

IF DB_ID(N'Lab9') IS NOT NULL
BEGIN
    ALTER DATABASE Lab9 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Lab9;
END
GO

CREATE DATABASE Lab9
ON PRIMARY(
    NAME = Lab9_dat,
    FILENAME = 'D:\database\lab9\Lab9_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab_9log,
    FILENAME = 'D:\database\lab9\Lab9_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab9;
GO

--Task 1:
IF OBJECT_ID(N'AIRCRAFT') IS NOT NULL
    DROP TABLE AIRCRAFT;
GO

CREATE TABLE AIRCRAFT
(
    AircraftID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    BoardNumber VARCHAR(8) NOT NULL,
    Model NVARCHAR(10) NOT NULL,
    Manufacturer NVARCHAR(20) NOT NULL,
    CONSTRAINT AK_BoardNumber UNIQUE (BoardNumber),
);
GO

IF OBJECT_ID(N'Trigger_Insert_AIRCRAFT') IS NOT NULL 
    DROP TRIGGER Trigger_Insert_AIRCRAFT;
GO

CREATE TRIGGER Trigger_Insert_AIRCRAFT
ON AIRCRAFT
AFTER INSERT
AS
BEGIN
    PRINT 'New aircraft(s) added:';
    SELECT *
    FROM inserted;
END;
GO

IF OBJECT_ID(N'Trigger_Update_AIRCRAFT') IS NOT NULL 
    DROP TRIGGER Trigger_Update_AIRCRAFT;
GO

CREATE TRIGGER Trigger_Update_AIRCRAFT
ON dbo.AIRCRAFT
AFTER UPDATE
AS
BEGIN
    -- Проверяем, что длина BoardNumber >= 4
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE LEN(BoardNumber) < 4
    )
    BEGIN
        RAISERROR(N'BoardNumber must contain at least 4 characters.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    PRINT 'Aircraft(s) updated:';
    SELECT *
    FROM inserted;
END;
GO

IF OBJECT_ID(N'Trigger_Delete_AIRCRAFT') IS NOT NULL 
    DROP TRIGGER Trigger_Delete_AIRCRAFT;
GO

CREATE TRIGGER Trigger_Delete_AIRCRAFT
ON AIRCRAFT
AFTER DELETE
AS
BEGIN
    PRINT 'Aircraft(s) deleted:';
    SELECT *
    FROM deleted;
END;
GO

-- Task 2:
IF OBJECT_ID(N'AircraftTechSpecifications') IS NOT NULL
    DROP TABLE AircraftTechSpecifications;
GO

CREATE TABLE AircraftTechSpecifications
(
    AircraftID INT NOT NULL PRIMARY KEY,
    PassengerCapacity SMALLINT NOT NULL,
    LoadCapacity NUMERIC(6,2) NOT NULL,
    AircraftAge TINYINT NOT NULL,
    Status TINYINT NOT NULL DEFAULT (1) CHECK (Status IN (1, 2)),
    FOREIGN KEY (AircraftID) REFERENCES AIRCRAFT(AircraftID) ON DELETE CASCADE,
);
GO

IF OBJECT_ID(N'view_AIRCRAFTAndTechSpecification') IS NOT NULL
    DROP TABLE view_AIRCRAFTAndTechSpecification;
GO

CREATE VIEW view_AIRCRAFTAndTechSpecification
AS
    SELECT
        a.AircraftID,
        a.BoardNumber,
        a.Model,
        a.Manufacturer,
        ts.PassengerCapacity,
        ts.LoadCapacity,
        ts.AircraftAge,
        ts.Status
    FROM
        AIRCRAFT a
        INNER JOIN
        AircraftTechSpecifications ts ON a.AircraftID = ts.AircraftID;
GO

