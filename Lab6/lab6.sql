USE master;
GO

IF DB_ID(N'Lab6') IS NOT NULL
BEGIN
    DROP DATABASE Lab6;
    PRINT 'Existing database Lab6 has been deleted';
END
ELSE
BEGIN
    PRINT 'Database Lab6 not found';
END
GO

CREATE DATABASE Lab6
ON ( NAME = Lab6_dat,
    FILENAME = 'D:\database\lab6\Lab6_log.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = Lab6_log,
    FILENAME = 'D:\database\lab6\Lab6_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO
