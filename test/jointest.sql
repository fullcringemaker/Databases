-- тест     
USE master;
GO

IF DB_ID(N'testing') IS NOT NULL
BEGIN
    ALTER DATABASE testing SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE testing;
END
GO

CREATE DATABASE testing
ON PRIMARY(
    NAME = testing_dat,
    FILENAME = 'D:\database\testing\testing_dat.mdf', 
    SIZE = 10MB,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)
LOG ON (NAME = testinglog,
    FILENAME = 'D:\database\testing\testing_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE testing;
GO

-- Таблица T1
IF OBJECT_ID(N'T1') IS NOT NULL
    DROP TABLE T1;
GO

CREATE TABLE T1
(
    C1 int NOT NULL,
    C2 varchar(1) NOT NULL,
);

-- Таблица T2
IF OBJECT_ID(N'T2') IS NOT NULL
    DROP TABLE T2;
GO

CREATE TABLE T2
(
    C3 varchar(1) NOT NULL,
    C4 int NOT NULL,
);

INSERT INTO T1
    (C1, C2)
VALUES
    (1, 'a'),
    (2, 'a'),
    (3, 'b'),
    (4, 'c'),
    (5, 'f');
GO

select * from t1

INSERT INTO T2
    (C3, C4)
VALUES
    ('a', 2),
    ('b', 7),
    ('b', 5),
    ('c', 8),
    ('g', 9);
GO

select * from t2

--select * from t1 join t2 on c2=c3
select * from t1 inner join t2 on c2=c3

--select * from t1 left join t2 on c2=c3
select * from t1 left outer join t2 on c2=c3

--select * from t1 right join t2 on c2=c3
select * from t1 right outer join t2 on c2=c3

--select * from t1 full join t2 on c2=c3
select * from t1 full outer join t2 on c2=c3

select count (*) from t1 full outer join t2 on c2=c3
select count (C1) from t1 full outer join t2 on c2=c3
select count (C4) from t1 full outer join t2 on c2=c3
