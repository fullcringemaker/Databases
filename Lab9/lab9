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
