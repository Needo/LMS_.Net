USE LMSDatabase;
GO

PRINT 'Starting database upgrade...';
GO

-- Step 1: Add Role column to Users if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'Users') AND name = 'Role')
BEGIN
    ALTER TABLE Users ADD Role nvarchar(20) NOT NULL DEFAULT 'Student';
    PRINT 'Added Role column to Users';
END
ELSE
BEGIN
    PRINT 'Role column already exists in Users';
END
GO

-- Step 2: Create Categories table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories (
        Id int IDENTITY(1,1) PRIMARY KEY,
        Name nvarchar(max) NOT NULL,
        Path nvarchar(max) NOT NULL,
        CreatedDate datetime2 NOT NULL
    );
    PRINT 'Created Categories table';
END
ELSE
BEGIN
    PRINT 'Categories table already exists';
END
GO

-- Step 3: Add CategoryId to Courses if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'Courses') AND name = 'CategoryId')
BEGIN
    -- First create a default category for existing courses
    IF NOT EXISTS (SELECT * FROM Categories WHERE Name = 'General')
    BEGIN
        INSERT INTO Categories (Name, Path, CreatedDate)
        VALUES ('General', 'C:\Courses', GETDATE());
        PRINT 'Created default General category';
    END
    
    -- Add the CategoryId column as nullable first
    ALTER TABLE Courses ADD CategoryId int NULL;
    PRINT 'Added CategoryId column to Courses';
    
    -- Update all existing courses to use the default category
    DECLARE @DefaultCategoryId int = (SELECT Id FROM Categories WHERE Name = 'General');
    UPDATE Courses SET CategoryId = @DefaultCategoryId WHERE CategoryId IS NULL;
    PRINT 'Updated existing courses with default category';
    
    -- Now make it NOT NULL
    ALTER TABLE Courses ALTER COLUMN CategoryId int NOT NULL;
    PRINT 'Made CategoryId NOT NULL';
    
    -- Add foreign key constraint
    ALTER TABLE Courses ADD CONSTRAINT FK_Courses_Categories_CategoryId 
        FOREIGN KEY (CategoryId) REFERENCES Categories(Id) ON DELETE CASCADE;
    PRINT 'Added foreign key constraint';
    
    -- Create index
    CREATE INDEX IX_Courses_CategoryId ON Courses(CategoryId);
    PRINT 'Created index on CategoryId';
END
ELSE
BEGIN
    PRINT 'CategoryId already exists in Courses';
END
GO

-- Step 4: Create UserCourseSubscriptions table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserCourseSubscriptions')
BEGIN
    CREATE TABLE UserCourseSubscriptions (
        Id int IDENTITY(1,1) PRIMARY KEY,
        UserId int NOT NULL,
        CourseId int NOT NULL,
        SubscribedDate datetime2 NOT NULL,
        CONSTRAINT FK_UserCourseSubscriptions_Users_UserId 
            FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_UserCourseSubscriptions_Courses_CourseId 
            FOREIGN KEY (CourseId) REFERENCES Courses(Id) ON DELETE CASCADE
    );
    
    -- Create indexes
    CREATE INDEX IX_UserCourseSubscriptions_CourseId ON UserCourseSubscriptions(CourseId);
    CREATE UNIQUE INDEX IX_UserCourseSubscriptions_UserId_CourseId 
        ON UserCourseSubscriptions(UserId, CourseId);
    
    PRINT 'Created UserCourseSubscriptions table';
END
ELSE
BEGIN
    PRINT 'UserCourseSubscriptions table already exists';
END
GO

PRINT '';
PRINT '========================================';
PRINT 'Database upgrade completed successfully!';
PRINT '========================================';
PRINT '';

-- Verify all tables exist
PRINT 'Tables in database:';
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;
GO

-- Show table counts
PRINT '';
PRINT 'Record counts:';
SELECT 'Categories' as TableName, COUNT(*) as Records FROM Categories
UNION ALL
SELECT 'Courses', COUNT(*) FROM Courses
UNION ALL
SELECT 'CourseItems', COUNT(*) FROM CourseItems
UNION ALL
SELECT 'Users', COUNT(*) FROM Users
UNION ALL
SELECT 'UserCourseSubscriptions', COUNT(*) FROM UserCourseSubscriptions;
GO
