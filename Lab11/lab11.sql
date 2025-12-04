-- Лабораторная работа 11
USE master;
GO

IF DB_ID(N'Lab11') IS NOT NULL
BEGIN
    ALTER DATABASE Lab11 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Lab11;
END
GO

CREATE DATABASE Lab11
ON PRIMARY(
    NAME = Lab11_dat,
    FILENAME = 'D:\database\lab11\Lab11_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab_9log,
    FILENAME = 'D:\database\lab11\Lab11_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE Lab11;
GO
