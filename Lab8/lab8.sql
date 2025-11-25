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

--Task 1:
