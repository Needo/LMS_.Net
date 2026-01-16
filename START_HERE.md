# 🚨 IMMEDIATE ACTION REQUIRED

## The Problem
You're getting a **500 Internal Server Error** because the database doesn't have the new tables.

## The Solution (2 Minutes)

### Quick Fix Steps:

1. **Open PowerShell** (don't need admin)

2. **Run these commands:**
```powershell
cd C:\LMSSystem\LMS.API
dotnet ef database drop --force
dotnet ef migrations add InitialCreateV2
dotnet ef database update
```

3. **Start the API:**
```powershell
dotnet run
```

4. **Test it:**
- Open browser: http://localhost:5000/swagger
- Click on GET /api/courses/categories
- Click "Try it out"
- Click "Execute"
- Should return: `[]` (empty array)

✅ **If you see the empty array, it's working!**

---

## Create Test Users

Open SQL Server Management Studio and run:

```sql
USE LMSDB;

INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Sex, Role, IsActive, CreatedDate)
VALUES 
  ('admin@lms.com', 'jGl25bVBBBW96Qi9Te4V37Fnqchz/Eu4qB9vKrRIqRg=', 'Admin', 'User', 'Male', 'Admin', 1, GETDATE()),
  ('student@lms.com', 'BPiZbadjt6lpsQKO4wB1aerzpjVIbdqyEdUSyFud+Ps=', 'Test', 'Student', 'Male', 'Student', 1, GETDATE());
```

**Login Credentials:**
- Admin: admin@lms.com / admin123
- Student: student@lms.com / student123

---

## Then Start Frontend

```powershell
cd C:\LMSSystem\LMSUI
ng serve
```

Open: http://localhost:4200

---

## What Changed in Backend

The backend now expects these new database tables:
- Categories (for Books, Courses, Documents, etc.)
- UserCourseSubscriptions (for user enrollment)
- Role column in Users table
- CategoryId column in Courses table

The old database doesn't have these, causing the 500 error.

---

## After Backend is Fixed

The current frontend will work but won't show categories yet. You'll need to:

1. Update models to include Category
2. Update services to call new endpoints
3. Update components to show category tree

I can help you with that once the backend is running!

---

**For detailed troubleshooting, see: FIX_BACKEND_ERROR.md**
