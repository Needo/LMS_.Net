-- Wait for SQL Server to be ready
WAITFOR DELAY '00:00:05';
GO

-- Create database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'LMSDatabase')
BEGIN
    CREATE DATABASE LMSDatabase;
END
GO

USE LMSDatabase;
GO

-- Create Users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Email NVARCHAR(255) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(255) NOT NULL,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Sex NVARCHAR(10) NOT NULL,
        Role NVARCHAR(50) NOT NULL DEFAULT 'Student',
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE()
    );
END
GO

-- Create Categories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(255) NOT NULL,
        Path NVARCHAR(MAX) NOT NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE()
    );
END
GO

-- Create Courses table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Courses')
BEGIN
    CREATE TABLE Courses (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(255) NOT NULL,
        CategoryId INT NOT NULL,
        Path NVARCHAR(MAX) NOT NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        FOREIGN KEY (CategoryId) REFERENCES Categories(Id) ON DELETE CASCADE
    );
END
GO

-- Create Contents table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Contents')
BEGIN
    CREATE TABLE Contents (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        CourseId INT NOT NULL,
        ParentId INT NULL,
        Name NVARCHAR(255) NOT NULL,
        Path NVARCHAR(MAX) NOT NULL,
        Type NVARCHAR(50) NOT NULL,
        Extension NVARCHAR(50) NULL,
        Size BIGINT NULL,
        CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        FOREIGN KEY (CourseId) REFERENCES Courses(Id) ON DELETE CASCADE,
        FOREIGN KEY (ParentId) REFERENCES Contents(Id)
    );
END
GO

-- Create UserCourseSubscriptions table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserCourseSubscriptions')
BEGIN
    CREATE TABLE UserCourseSubscriptions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        CourseId INT NOT NULL,
        SubscribedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
        FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        FOREIGN KEY (CourseId) REFERENCES Courses(Id) ON DELETE CASCADE,
        UNIQUE(UserId, CourseId)
    );
END
GO

-- Insert default admin user (password: password123)
IF NOT EXISTS (SELECT * FROM Users WHERE Email = 'admin@lms.com')
BEGIN
    INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Sex, Role)
    VALUES ('admin@lms.com', 
            'EF797C8118F02DFB649607DD5D3F8C7623048C9C063D532CC95C5ED7A898A64F',
            'Admin', 'User', 'Male', 'Admin');
END
GO

-- Insert default student user (password: password123)
IF NOT EXISTS (SELECT * FROM Users WHERE Email = 'student@lms.com')
BEGIN
    INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Sex, Role)
    VALUES ('student@lms.com', 
            'EF797C8118F02DFB649607DD5D3F8C7623048C9C063D532CC95C5ED7A898A64F',
            'Student', 'User', 'Female', 'Student');
END
GO

PRINT 'Database initialization completed successfully!';
GO
