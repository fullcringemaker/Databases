-- Переключение на базу данных MyDB1
USE MyDB1;
GO

-- Удаление таблицы Crew1_Vert, если она существует
IF OBJECT_ID(N'Crew1_Vert', N'U') IS NOT NULL
    DROP TABLE Crew1_Vert;
GO

-- Создание таблицы Crew1_Vert
CREATE TABLE Crew1_Vert
(
    CrewID INT PRIMARY KEY,         
    LicenseNumber VARCHAR(15) NOT NULL,    
    FirstName NVARCHAR(30) NOT NULL,
    LastName  NVARCHAR(30) NOT NULL
);

-- Переключение на базу данных MyDB2
USE MyDB2;
GO

-- Удаление таблицы Crew2_Vert, если она существует
IF OBJECT_ID(N'Crew2_Vert', N'U') IS NOT NULL
    DROP TABLE Crew2_Vert;
GO

-- Создание таблицы Crew2_Vert
CREATE TABLE Crew2_Vert
(
    CrewID INT PRIMARY KEY,
    Position TINYINT NOT NULL CHECK (Position IN (1, 2, 3, 4)),
    LicenseExpiryDate DATE Not NULL
);

-- Переключение на базу данных MyDB1
USE MyDB1;
GO

-- Удаление представления CrewView_Vert, если оно существует
IF OBJECT_ID(N'CrewView_Vert', N'V') IS NOT NULL
    DROP VIEW CrewView_Vert;
GO

-- Создание представления CrewView_Vert для объединения вертикально фрагментированных данных
CREATE VIEW CrewView_Vert
AS
    SELECT
        cr1.CrewID,
        cr1.LicenseNumber,
        cr1.FirstName,
        cr1.LastName,
        cr2.Position,
        cr2.LicenseExpiryDate
    FROM MyDB1.dbo.Crew1_Vert cr1
        INNER JOIN MyDB2.dbo.Crew2_Vert cr2 
        ON cr1.CrewID = cr2.CrewID;
GO

-- Удаление триггера для вставки, если он существует
IF OBJECT_ID(N'Trigger_Insert_CrewView_Vert', N'TR') IS NOT NULL
    DROP TRIGGER Trigger_Insert_CrewView_Vert;
GO

-- Создание триггера для вставки данных
CREATE TRIGGER Trigger_Insert_CrewView_Vert
ON CrewView_Vert
INSTEAD OF INSERT
AS
BEGIN
    -- Вставка данных в Crew1_Vert
    INSERT INTO MyDB1.dbo.Crew1_Vert
        (CrewID, LicenseNumber, FirstName, LastName)
    SELECT CrewID, LicenseNumber, FirstName, LastName
    FROM inserted;
    -- Вставка данных в Crew2_Vert
    INSERT INTO MyDB2.dbo.Crew2_Vert
        (CrewID, Position, LicenseExpiryDate)
    SELECT CrewID, Position, LicenseExpiryDate
    FROM inserted;
END;
GO

-- Удаление триггера для обновления, если он существует
IF OBJECT_ID(N'Trigger_Update_CrewView_Vert', N'TR') IS NOT NULL
    DROP TRIGGER Trigger_Update_CrewView_Vert;
GO

-- Создание триггера для обновления данных
CREATE TRIGGER Trigger_Update_CrewView_Vert
ON CrewView_Vert
INSTEAD OF UPDATE
AS
BEGIN
    -- запрет на обновление CrewID
    IF UPDATE(CrewID)
        BEGIN
        RAISERROR('Нельзя изменить столбец CrewID', 16, 1)
        ROLLBACK TRANSACTION;
    END
    ELSE
        BEGIN
        -- Обновление данных в Crew1_Vert
        UPDATE cr1
    SET 
        cr1.LicenseNumber = inserted.LicenseNumber,
        cr1.FirstName = inserted.FirstName,
        cr1.LastName = inserted.LastName
    FROM MyDB1.dbo.Crew1_Vert cr1
        INNER JOIN inserted 
        ON cr1.CrewID = inserted.CrewID;
        -- Обновление данных в Crew2_Vert
        UPDATE cr2
    SET 
        cr2.Position = inserted.Position,
        cr2.LicenseExpiryDate = inserted.LicenseExpiryDate
    FROM MyDB2.dbo.Crew2_Vert cr2
        INNER JOIN inserted 
        ON cr2.CrewID = inserted.CrewID;
    END;
END;
GO

-- Удаление триггера для удаления, если он существует
IF OBJECT_ID(N'Trigger_Delete_CrewView_Vert', N'TR') IS NOT NULL
    DROP TRIGGER Trigger_Delete_CrewView_Vert;
GO

-- Создание триггера для удаления данных
CREATE TRIGGER Trigger_Delete_CrewView_Vert
ON CrewView_Vert
INSTEAD OF DELETE
AS
BEGIN
    -- Удаление данных из Crew1_Vert
    DELETE FROM MyDB1.dbo.Crew1_Vert
    WHERE CrewID IN (SELECT CrewID
    FROM deleted);
    -- Удаление данных из Crew2_Vert
    DELETE FROM MyDB2.dbo.Crew2_Vert
    WHERE CrewID IN (SELECT CrewID
    FROM deleted);
END;
GO

-- Проверка работы триггеров и представления

-- Вставка данных в представление
INSERT INTO CrewView_Vert
    (CrewID, LicenseNumber, FirstName, LastName, Position, LicenseExpiryDate)
VALUES
    (1, 'LIC-4551', N'Ivan', N'Petrov', 1, '2027-06-30'), 
    (2, 'LIC-9571', N'Petr', N'Ivaov', 2, '2028-01-15'),
    (3, 'LIC-3391', N'Vasiliy', N'Sidorov', 3, '2026-11-20'),
    (4, 'LIC-7784', N'Alica', N'Smirnova', 4, '2029-03-10'),
    (5, 'LIC-7023', N'Giorgiy', N'Kuznetsov', 3, '2027-09-05');
GO

-- Выборка данных из представления
SELECT *
FROM CrewView_Vert;
GO

-- Обновление данных через представление
UPDATE CrewView_Vert
SET LicenseExpiryDate = '2035-12-31'
WHERE Position = 4;
GO

-- Удаление данных через представление
DELETE FROM CrewView_Vert
WHERE FirstName = N'Vasiliy';
GO

-- Проверка данных в таблицах
SELECT *
FROM MyDB1.dbo.Crew1_Vert;
SELECT *
FROM MyDB2.dbo.Crew2_Vert; 
GO

