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

--Task 1:
