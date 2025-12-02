-- Лабораторная работа 8
USE master;
GO

IF DB_ID(N'Lab8') IS NOT NULL
BEGIN
    ALTER DATABASE Lab8 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Lab8;
END
GO

CREATE DATABASE Lab8
ON PRIMARY(
    NAME = Lab8_dat,
    FILENAME = 'D:\database\lab8\Lab8_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab_8log,
    FILENAME = 'D:\database\lab8\Lab8_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab8;
GO

IF OBJECT_ID(N'dbo.AIRCRAFT', N'U') IS NOT NULL
    DROP TABLE dbo.AIRCRAFT;
GO
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
    ('F-GKXM',  N'A320neo',   N'Airbus', 180, 7400.50,  3, 1),  
    ('D-ABCD',  N'B737-8',    N'Boeing', 220, 7600.00,  7, 1), 
    ('G-EZUA',  N'A321-200',  N'Airbus', 189, 8200.25, 10, 1),  
    ('N123AB',  N'B787-8',    N'Boeing', 242, 9800.00,  2, 2),  
    ('EI-GSH',  N'SSJ100',    N'Sukhoi',  98, 6400.00,  6, 1);
GO

-- Task 1:
DROP PROCEDURE IF EXISTS dbo.GetAircraftByPassengerCapacity;
GO

CREATE PROCEDURE dbo.GetAircraftByPassengerCapacity
    @cursor CURSOR VARYING OUTPUT,
    @MinPassengerCapacity SMALLINT
AS
BEGIN
    SET @cursor = CURSOR FORWARD_ONLY STATIC FOR
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
    WHERE PassengerCapacity >= @MinPassengerCapacity;
    OPEN @cursor;
END;
GO

-- тест для Task 1:
DECLARE @cursor1 CURSOR;
DECLARE 
    @AircraftID         INT,
    @BoardNumber        VARCHAR(8),
    @Model              NVARCHAR(10),
    @Manufacturer       NVARCHAR(20),
    @PassengerCapacity  SMALLINT,
    @LoadCapacity       NUMERIC(6,2),
    @AircraftAge        TINYINT,
    @Status             TINYINT;
EXEC dbo.GetAircraftByPassengerCapacity
    @cursor = @cursor1 OUTPUT,
    @MinPassengerCapacity = 200;
FETCH NEXT FROM @cursor1
INTO
    @AircraftID,
    @BoardNumber,
    @Model,
    @Manufacturer,
    @PassengerCapacity,
    @LoadCapacity,
    @AircraftAge,
    @Status;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT
        @AircraftID        AS AircraftID,
        @BoardNumber       AS BoardNumber,
        @Model             AS Model,
        @Manufacturer      AS Manufacturer,
        @PassengerCapacity AS PassengerCapacity,
        @LoadCapacity      AS LoadCapacity,
        @AircraftAge       AS AircraftAge,
        @Status            AS Status;
    FETCH NEXT FROM @cursor1
    INTO
        @AircraftID,
        @BoardNumber,
        @Model,
        @Manufacturer,
        @PassengerCapacity,
        @LoadCapacity,
        @AircraftAge,
        @Status;
END;
CLOSE @cursor1;
DEALLOCATE @cursor1;
GO

-- Task 2:
DROP FUNCTION IF EXISTS dbo.GetStatusDescription;
GO

CREATE FUNCTION dbo.GetStatusDescription(@Status TINYINT)
RETURNS NVARCHAR(30)
AS
BEGIN
    DECLARE @Result NVARCHAR(30);
    SET @Result =
        CASE @Status
            WHEN 1 THEN N'Active'
            WHEN 2 THEN N'Unactive'
        END;
    RETURN @Result;
END;
GO


DROP PROCEDURE IF EXISTS dbo.GetAircraftByMinCapacityWithStatus;
GO

CREATE PROCEDURE dbo.GetAircraftByMinCapacityWithStatus
    @cursor CURSOR VARYING OUTPUT,
    @MinPassengerCapacity SMALLINT
AS
BEGIN
    SET @cursor = CURSOR FORWARD_ONLY STATIC FOR
    SELECT
        AircraftID,
        BoardNumber,
        Model,
        Manufacturer,
        PassengerCapacity,
        LoadCapacity,
        AircraftAge,
        dbo.GetStatusDescription(Status) AS StatusDescription
    FROM dbo.AIRCRAFT
    WHERE PassengerCapacity >= @MinPassengerCapacity;
    OPEN @cursor;
END;
GO

-- Тест для Task 2:
DECLARE @cursor2 CURSOR;
DECLARE 
    @AircraftID         INT,
    @BoardNumber        VARCHAR(8),
    @Model              NVARCHAR(10),
    @Manufacturer       NVARCHAR(20),
    @PassengerCapacity  SMALLINT,
    @LoadCapacity       NUMERIC(6,2),
    @AircraftAge        TINYINT,
    @StatusDescription  NVARCHAR(30);
EXEC dbo.GetAircraftByMinCapacityWithStatus
     @cursor = @cursor2 OUTPUT,
     @MinPassengerCapacity = 180;
FETCH NEXT FROM @cursor2
INTO
    @AircraftID,
    @BoardNumber,
    @Model,
    @Manufacturer,
    @PassengerCapacity,
    @LoadCapacity,
    @AircraftAge,
    @StatusDescription;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT
        @AircraftID         AS AircraftID,
        @BoardNumber        AS BoardNumber,
        @Model              AS Model,
        @Manufacturer       AS Manufacturer,
        @PassengerCapacity  AS PassengerCapacity,
        @LoadCapacity       AS LoadCapacity,
        @AircraftAge        AS AircraftAge,
        @StatusDescription  AS StatusDescription;
    FETCH NEXT FROM @cursor2
    INTO
        @AircraftID,
        @BoardNumber,
        @Model,
        @Manufacturer,
        @PassengerCapacity,
        @LoadCapacity,
        @AircraftAge,
        @StatusDescription;
END;
CLOSE @cursor2;
DEALLOCATE @cursor2;
GO

-- Task 3:
DROP FUNCTION IF EXISTS dbo.IsNewAircraft;
GO

CREATE FUNCTION dbo.IsNewAircraft(@AircraftAge TINYINT)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN @AircraftAge <= 5 THEN 1 ELSE 0 END;
END;
GO

DROP PROCEDURE IF EXISTS dbo.GetNewAircraftData;
GO

CREATE PROCEDURE dbo.GetNewAircraftData
AS
BEGIN
    DECLARE @cursor CURSOR;
    EXEC dbo.GetAircraftByMinCapacityWithStatus
        @cursor = @cursor OUTPUT,
        @MinPassengerCapacity = 180;
    DECLARE 
        @AircraftID         INT,
        @BoardNumber        VARCHAR(8),
        @Model              NVARCHAR(10),
        @Manufacturer       NVARCHAR(20),
        @PassengerCapacity  SMALLINT,
        @LoadCapacity       NUMERIC(6,2),
        @AircraftAge        TINYINT,
        @StatusDescription  NVARCHAR(30);
    FETCH NEXT FROM @cursor
    INTO
        @AircraftID,
        @BoardNumber,
        @Model,
        @Manufacturer,
        @PassengerCapacity,
        @LoadCapacity,
        @AircraftAge,
        @StatusDescription;

    PRINT 'Results for dbo.GetNewAircraftData:';

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF dbo.IsNewAircraft(@AircraftAge) = 1
        BEGIN
            SELECT
                @AircraftID         AS AircraftID,
                @BoardNumber        AS BoardNumber,
                @Model              AS Model,
                @Manufacturer       AS Manufacturer,
                @PassengerCapacity  AS PassengerCapacity,
                @LoadCapacity       AS LoadCapacity,
                @AircraftAge        AS AircraftAge,
                @StatusDescription  AS StatusDescription;
        END;
        FETCH NEXT FROM @cursor
        INTO
            @AircraftID,
            @BoardNumber,
            @Model,
            @Manufacturer,
            @PassengerCapacity,
            @LoadCapacity,
            @AircraftAge,
            @StatusDescription;
    END;
    CLOSE @cursor;
    DEALLOCATE @cursor;
END;
GO

-- Тест для Task 3:
EXEC dbo.GetNewAircraftData;
GO

-- Task 4:
DROP FUNCTION IF EXISTS dbo.FilteredAircraftWithStatus;
GO

DROP FUNCTION IF EXISTS dbo.FilteredAircraftWithStatus;
GO

-- краткая версия функции
CREATE FUNCTION dbo.FilteredAircraftWithStatus()
RETURNS TABLE
AS
RETURN
(
    SELECT
        AircraftID,
        BoardNumber,
        Model,
        Manufacturer,
        PassengerCapacity,
        LoadCapacity,
        AircraftAge,
        dbo.GetStatusDescription(Status) AS StatusDescription
    FROM dbo.AIRCRAFT
    WHERE PassengerCapacity >= 180
);
GO

-- Полная версия функцияя
-- CREATE FUNCTION dbo.FilteredAircraftWithStatus()
-- RETURNS @ResultTable TABLE
-- (
--     AircraftID        INT,
--     BoardNumber       VARCHAR(8),
--     Model             NVARCHAR(10),
--     Manufacturer      NVARCHAR(20),
--     PassengerCapacity SMALLINT,
--     LoadCapacity      NUMERIC(6,2),
--     AircraftAge       TINYINT,
--     StatusDescription NVARCHAR(30)
-- )
-- AS
-- BEGIN
--     INSERT INTO @ResultTable
--     SELECT
--         AircraftID,
--         BoardNumber,
--         Model,
--         Manufacturer,
--         PassengerCapacity,
--         LoadCapacity,
--         AircraftAge,
--         dbo.GetStatusDescription(Status) AS StatusDescription
--     FROM dbo.AIRCRAFT
--     WHERE PassengerCapacity >= 180;
--     RETURN;
-- END;
-- GO

DROP PROCEDURE IF EXISTS dbo.UseFilteredAircraftWithStatus;
GO

CREATE PROCEDURE dbo.UseFilteredAircraftWithStatus
AS
BEGIN
    SELECT * FROM dbo.FilteredAircraftWithStatus();
END;
GO

-- Тест для Task 4:
EXEC dbo.UseFilteredAircraftWithStatus;
GO
