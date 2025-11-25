-- Лабораторная работа 7
USE master;
GO

IF DB_ID(N'Lab7') IS NOT NULL
BEGIN
    ALTER DATABASE Lab7 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Lab7;
END
GO

CREATE DATABASE Lab7
ON PRIMARY(
    NAME = Lab7_dat,
    FILENAME = 'D:\database\lab7\Lab7_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab7_log,
    FILENAME = 'D:\database\lab7\Lab7_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab7;
GO

-- Task 1:
