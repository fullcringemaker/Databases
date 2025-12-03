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

-- Insert
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

-- Update
CREATE TRIGGER Trigger_Update_AIRCRAFT
ON AIRCRAFT
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE LEN(BoardNumber) < 4
    )
    BEGIN
        RAISERROR(N'BoardNumber must contain at least 4 characters', 16, 1);
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

-- Delete
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

-- Tests:
INSERT INTO AIRCRAFT (BoardNumber, Model, Manufacturer)
VALUES 
    ('ABCD1234', 'A320', 'Airbus'),
    ('EFGH5678', 'B737', 'Boeing');
GO

SELECT * FROM AIRCRAFT;
GO

UPDATE AIRCRAFT
SET BoardNumber = 'QWER9999'
WHERE BoardNumber = 'ABCD1234';
GO

SELECT * FROM AIRCRAFT;
GO

--invalid
--UPDATE AIRCRAFT
--SET BoardNumber = 'AA'
--WHERE BoardNumber = 'EFGH5678';
--GO
--SELECT * FROM AIRCRAFT;
--GO

DELETE FROM AIRCRAFT
WHERE BoardNumber = 'QWER9999';
GO

SELECT * FROM AIRCRAFT;
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

IF OBJECT_ID(N'view_AIRCRAFTAndTechSpecifications') IS NOT NULL
    DROP VIEW view_AIRCRAFTAndTechSpecifications;
GO

CREATE VIEW view_AIRCRAFTAndTechSpecifications
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
        INNER JOIN AircraftTechSpecifications ts 
            ON a.AircraftID = ts.AircraftID;
GO

IF OBJECT_ID(N'Trigger_Insert_view_AIRCRAFTAndTechSpecifications') IS NOT NULL 
    DROP TRIGGER Trigger_Insert_view_AIRCRAFTAndTechSpecifications;
GO

-- Insert
CREATE TRIGGER Trigger_Insert_view_AIRCRAFTAndTechSpecifications
ON view_AIRCRAFTAndTechSpecifications
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN AIRCRAFT a
            ON i.BoardNumber = a.BoardNumber
    )
    BEGIN
        RAISERROR(N'Aircraft with this BoardNumber already exists.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    INSERT INTO AIRCRAFT 
        (BoardNumber, Model, Manufacturer)
    SELECT 
        BoardNumber, 
        Model, 
        Manufacturer
    FROM inserted;

    INSERT INTO AircraftTechSpecifications
        (AircraftID, PassengerCapacity, LoadCapacity, AircraftAge, Status)
    SELECT
        a.AircraftID,
        i.PassengerCapacity,
        i.LoadCapacity,
        i.AircraftAge,
        i.Status
    FROM inserted i
    JOIN AIRCRAFT a
        ON a.BoardNumber = i.BoardNumber;
END;
GO

IF OBJECT_ID(N'Trigger_Update_view_AIRCRAFTAndTechSpecifications') IS NOT NULL 
    DROP TRIGGER Trigger_Update_view_AIRCRAFTAndTechSpecifications;
GO

-- Update
CREATE TRIGGER Trigger_Update_view_AIRCRAFTAndTechSpecifications
ON view_AIRCRAFTAndTechSpecifications
INSTEAD OF UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE PassengerCapacity < 0
           OR LoadCapacity      < 0
    )
    BEGIN
        RAISERROR(N'PassengerCapacity and LoadCapacity must be positive.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    WITH UpdatedAIRCRAFT AS
    (
        SELECT
            a.AircraftID,
            i.BoardNumber,
            i.Model,
            i.Manufacturer
        FROM AIRCRAFT a
        INNER JOIN inserted i
            ON a.AircraftID = i.AircraftID
    )
    UPDATE a
    SET
        a.BoardNumber  = ua.BoardNumber,
        a.Model        = ua.Model,
        a.Manufacturer = ua.Manufacturer
    FROM AIRCRAFT a
    INNER JOIN UpdatedAircraft ua
        ON a.AircraftID = ua.AircraftID;

    WITH UpdatedTechSpecifications AS
    (
        SELECT
            ts.AircraftID,
            i.PassengerCapacity,
            i.LoadCapacity,
            i.AircraftAge,
            i.Status
        FROM AircraftTechSpecifications ts
        INNER JOIN inserted i
            ON ts.AircraftID = i.AircraftID
    )
    UPDATE ts
    SET
        ts.PassengerCapacity = uts.PassengerCapacity,
        ts.LoadCapacity      = uts.LoadCapacity,
        ts.AircraftAge       = uts.AircraftAge,
        ts.Status            = uts.Status
    FROM AircraftTechSpecifications ts
    INNER JOIN UpdatedTechSpecifications uts
        ON ts.AircraftID = uts.AircraftID;
END;
GO

IF OBJECT_ID(N'Trigger_Delete_view_AIRCRAFTAndTechSpecifications') IS NOT NULL 
    DROP TRIGGER Trigger_Delete_view_AIRCRAFTAndTechSpecifications;
GO

-- Delete
CREATE TRIGGER Trigger_Delete_view_AIRCRAFTAndTechSpecifications
ON view_AIRCRAFTAndTechSpecifications
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM AircraftTechSpecifications
    WHERE AircraftID IN (
    SELECT AircraftID 
    FROM deleted);

    DELETE FROM AIRCRAFT
    WHERE AircraftID IN (
    SELECT AircraftID 
    FROM deleted);
END;
GO

-- Tests:
INSERT INTO view_AIRCRAFTAndTechSpecifications
    (BoardNumber, Model, Manufacturer, PassengerCapacity, LoadCapacity, AircraftAge, Status)
VALUES
    ('L9000001', 'A321', 'Airbus', 220, 18.50, 3, 1),
    ('B9000002', 'B787', 'Boeing', 260, 22.00, 2, 2);
GO

SELECT * FROM view_AIRCRAFTAndTechSpecifications;
GO

SELECT * FROM AIRCRAFT;
GO

SELECT * FROM AircraftTechSpecifications;
GO

--invalid
--INSERT INTO view_AIRCRAFTAndTechSpecifications
--    (BoardNumber, Model, Manufacturer, PassengerCapacity, LoadCapacity, AircraftAge, Status)
--VALUES
--    ('L9000001', 'A330', 'Airbus', 250, 20.00, 4, 1);
--PRINT 'Error (duplicate INSERT): ' + ERROR_MESSAGE();
--GO

UPDATE view_AIRCRAFTAndTechSpecifications
SET 
    Model = 'A321neo',
    PassengerCapacity = 230,
    LoadCapacity = 19.75
WHERE BoardNumber = 'L9000001';
GO

SELECT * FROM view_AIRCRAFTAndTechSpecifications;
GO

SELECT * FROM AIRCRAFT;
GO

SELECT * FROM AircraftTechSpecifications;
GO

--invalid
--UPDATE view_AIRCRAFTAndTechSpecifications
--SET PassengerCapacity = -10      -- триггер должен выдать RAISERROR
--WHERE BoardNumber = 'B9000002';
--PRINT 'Error (invalid UPDATE): ' + ERROR_MESSAGE();
--GO
--SELECT * FROM AircraftTechSpecifications;
--GO

DELETE FROM view_AIRCRAFTAndTechSpecifications
WHERE BoardNumber = 'L9000001';
GO

SELECT * FROM view_AIRCRAFTAndTechSpecifications;
GO

SELECT * FROM AIRCRAFT;
GO

SELECT * FROM AircraftTechSpecifications;
GO
