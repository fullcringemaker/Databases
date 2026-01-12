USE master;
GO

IF DB_ID(N'MyDB1') IS NOT NULL
BEGIN
    ALTER DATABASE MyDB1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MyDB1;
END
GO

CREATE DATABASE MyDB1 ON (
    NAME = MyDB1_dat,
    FILENAME = 'D:\database\lab13\MyDB1_dat.mdf',
    SIZE = 10MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5%
)
LOG ON (
    NAME = MyDB1_log,
    FILENAME = 'D:\database\lab13\MyDB1_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

IF DB_ID(N'MyDB2') IS NOT NULL
BEGIN
    ALTER DATABASE MyDB2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MyDB2;
END
GO

CREATE DATABASE MyDB2 ON (
    NAME = MyDB2_dat,
    FILENAME = 'D:\database\lab13\MyDB2_dat.mdf',
    SIZE = 10MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5%
)
LOG ON (
    NAME = MyDB2_log,
    FILENAME = 'D:\database\lab13\MyDB2_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE MyDB1;
GO

-- Удаление таблицы Crew1, если она существует
IF OBJECT_ID(N'Crew1', N'U') IS NOT NULL
    DROP TABLE Crew1;
GO

-- Создание таблицы Crew1
CREATE TABLE Crew1
(
    CrewID INT PRIMARY KEY,         
    LicenseNumber VARCHAR(15) NOT NULL,    
    FirstName NVARCHAR(30) NOT NULL,
    LastName  NVARCHAR(30) NOT NULL,
    Position TINYINT NOT NULL CHECK (Position IN (1, 2, 3, 4)),
    LicenseExpiryDate DATE Not NULL,
    CONSTRAINT Seq_Crew1 CHECK (CrewID < 3),
);

USE MyDB2;
GO

-- Удаление таблицы Crew2, если она существует
IF OBJECT_ID(N'Crew2', N'U') IS NOT NULL
    DROP TABLE Crew2;
GO

-- Создание таблицы Crew2
CREATE TABLE Crew2
(
    CrewID INT PRIMARY KEY,         
    LicenseNumber VARCHAR(15) NOT NULL,    
    FirstName NVARCHAR(30) NOT NULL,
    LastName  NVARCHAR(30) NOT NULL,
    Position TINYINT NOT NULL CHECK (Position IN (1, 2, 3, 4)),
    LicenseExpiryDate DATE Not NULL,
    CONSTRAINT Seq_Crew1 CHECK (CrewID >= 3),
);

USE MyDB1;
GO

-- Удаление представления CrewView, если оно существует
IF OBJECT_ID(N'CrewView', N'V') IS NOT NULL
    DROP VIEW CrewView;
GO

-- Создание представления CrewView
CREATE VIEW CrewView
AS
        SELECT *
        FROM MyDB1.dbo.Crew1
    UNION ALL
        SELECT *
        FROM MyDB2.dbo.Crew2;
GO

-- Вставка данных в CrewView
INSERT INTO dbo.CrewView
VALUES
    (1, 'LIC-4551', N'Ivan', N'Petrov', 1, '2027-06-30'), 
    (2, 'LIC-9571', N'Petr', N'Ivaov', 2, '2028-01-15'),
    (3, 'LIC-3391', N'Vasiliy', N'Sidorov', 3, '2026-11-20'),
    (4, 'LIC-7784', N'Alica', N'Smirnova', 4, '2029-03-10'),
    (5, 'LIC-7023', N'Giorgiy', N'Kuznetsov', 3, '2027-09-05');
GO

-- Проверка содержимого представления и таблиц
SELECT * 
FROM MyDB1.dbo.Crew1;
SELECT * 
FROM MyDB2.dbo.Crew2;
SELECT * 
FROM dbo.CrewView;
GO

-- Удаление строки из представления
DELETE FROM dbo.CrewView
WHERE FirstName = N'Vasiliy';
GO

-- Обновление строки в представлении
UPDATE dbo.CrewView
SET LicenseExpiryDate = '2035-12-31'
WHERE Position = 4;
GO

-- Вставка новой строки в представление
INSERT INTO dbo.CrewView 
VALUES
    (8, 'LIC-1433', N'Max', N'Volkov', 4, '2031-05-20');
GO

-- Проверка содержимого представления и таблиц после изменения
SELECT * 
FROM MyDB1.dbo.Crew1;
SELECT * 
FROM MyDB2.dbo.Crew2;
SELECT * 
FROM dbo.CrewView;
GO
