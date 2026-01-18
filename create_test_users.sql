-- Create Test Users for LMS System
-- Run this in SQL Server Management Studio or Azure Data Studio
-- Connect to: Server=EMAAN-PC; Database=LMSDatabase; User=sa; Password=pass

USE LMSDatabase;
GO

-- Password for both users: "password123"
-- SHA256 Hash (Base64): 75K3eLr+dx6JJFuJ7LwIpEpOFmwGZZkRiB84PURz6U8=

-- Insert Admin User
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@test.com')
BEGIN
    INSERT INTO Users (Email, FirstName, LastName, Sex, Role, PasswordHash, CreatedAt, IsActive)
    VALUES (
        'admin@test.com',
        'Admin',
        'User',
        'Male',
        'Admin',
        '75K3eLr+dx6JJFuJ7LwIpEpOFmwGZZkRiB84PURz6U8=',
        GETUTCDATE(),
        1
    );
    PRINT 'Admin user created: admin@test.com / password123';
END
ELSE
BEGIN
    UPDATE Users 
    SET PasswordHash = '75K3eLr+dx6JJFuJ7LwIpEpOFmwGZZkRiB84PURz6U8=',
        IsActive = 1
    WHERE Email = 'admin@test.com';
    PRINT 'Admin user updated with new password';
END
GO

-- Insert Student User
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'student@test.com')
BEGIN
    INSERT INTO Users (Email, FirstName, LastName, Sex, Role, PasswordHash, CreatedAt, IsActive)
    VALUES (
        'student@test.com',
        'Student',
        'User',
        'Female',
        'Student',
        '75K3eLr+dx6JJFuJ7LwIpEpOFmwGZZkRiB84PURz6U8=',
        GETUTCDATE(),
        1
    );
    PRINT 'Student user created: student@test.com / password123';
END
ELSE
BEGIN
    UPDATE Users 
    SET PasswordHash = '75K3eLr+dx6JJFuJ7LwIpEpOFmwGZZkRiB84PURz6U8=',
        IsActive = 1
    WHERE Email = 'student@test.com';
    PRINT 'Student user updated with new password';
END
GO

-- Verify users were created
SELECT Id, Email, FirstName, LastName, Role, CreatedAt, IsActive
FROM Users
WHERE Email IN ('admin@test.com', 'student@test.com');
GO

PRINT '';
PRINT '=== Test Users Created ===';
PRINT 'Admin:   admin@test.com / password123';
PRINT 'Student: student@test.com / password123';
PRINT '========================';
