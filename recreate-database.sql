USE master;
GO

-- Drop database if it exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'LMSDB')
BEGIN
    ALTER DATABASE LMSDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LMSDB;
END
GO

-- Create fresh database
CREATE DATABASE LMSDB;
GO

USE LMSDB;
GO

PRINT 'Database recreated successfully!';
