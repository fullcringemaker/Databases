-- Лабораторная работа 10
USE master;
GO

IF DB_ID(N'Lab10') IS NOT NULL
BEGIN
    ALTER DATABASE Lab10 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Lab10;
END
GO

CREATE DATABASE Lab10
ON PRIMARY(
    NAME = Lab10_dat,
    FILENAME = 'D:\database\lab10\Lab10_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab_10log,
    FILENAME = 'D:\database\lab10\Lab10_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab10;
GO

IF OBJECT_ID(N'AIRCRAFT') IS NOT NULL
    DROP TABLE AIRCRAFT;
GO

CREATE TABLE AIRCRAFT
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
GO

INSERT INTO AIRCRAFT
    (BoardNumber, Model, Manufacturer, PassengerCapacity, LoadCapacity, AircraftAge, Status)
VALUES
    ('F-GKXM',  N'A320neo',   N'Airbus', 180, 7400.50,  3, 1),  
    ('D-ABCD',  N'B737-8',    N'Boeing', 220, 7600.00,  7, 1), 
    ('G-EZUA',  N'A321-200',  N'Airbus', 189, 8200.25, 10, 1),  
    ('N123AB',  N'B787-8',    N'Boeing', 242, 9800.00,  2, 2),  
    ('EI-GSH',  N'SSJ100',    N'Sukhoi',  98, 6400.00,  6, 1);
GO
