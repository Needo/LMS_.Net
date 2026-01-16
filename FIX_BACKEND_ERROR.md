# 🔧 Fix Backend 500 Error - Step by Step Guide

## Problem
You're getting: `Http failure response for http://localhost:5000/api/courses: 500 Internal Server Error`

## Root Cause
The database doesn't have the new tables (Categories, UserCourseSubscriptions) that the backend code is trying to access.

---

## 🚀 Solution (Choose One)

### Option A: Quick Fix (Recommended)

**Step 1:** Open PowerShell as Administrator

**Step 2:** Run the simple fix script:
```powershell
cd C:\LMSSystem
.\simple-fix.ps1
```

**Step 3:** Start the API:
```powershell
cd LMS.API
dotnet run
```

**Step 4:** Test in browser:
- Open: `http://localhost:5000/swagger`
- Try the `/api/courses/categories` endpoint

---

### Option B: Manual Fix

**Step 1:** Open PowerShell in `C:\LMSSystem\LMS.API`

**Step 2:** Drop the old database:
```powershell
dotnet ef database drop --force
```

**Step 3:** Delete old migrations:
```powershell
Remove-Item .\Migrations\*.cs
```

**Step 4:** Create new migration:
```powershell
dotnet ef migrations add InitialCreateV2
```

**Step 5:** Apply migration:
```powershell
dotnet ef database update
```

**Step 6:** Start the API:
```powershell
dotnet run
```

---

## ✅ Verify It's Working

### 1. Check API is Running
You should see:
```
Now listening on: http://localhost:5000
Application started. Press Ctrl+C to shut down.
```

### 2. Test Swagger
- Open browser: `http://localhost:5000/swagger`
- You should see all API endpoints
- Try `GET /api/courses/categories` - should return empty array `[]`

### 3. Check Database Tables
Open SQL Server Management Studio and verify these tables exist:
- ✅ Categories
- ✅ Courses
- ✅ CourseItems
- ✅ Users
- ✅ UserCourseSubscriptions

---

## 🎯 Create Test Data

### Option 1: Using SQL (Quick)

Open SQL Server Management Studio and run:

```sql
USE LMSDB;

-- Create admin user
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Sex, Role, IsActive, CreatedDate)
VALUES ('admin@lms.com', 'jGl25bVBBBW96Qi9Te4V37Fnqchz/Eu4qB9vKrRIqRg=', 'Admin', 'User', 'Male', 'Admin', 1, GETDATE());

-- Create student user  
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Sex, Role, IsActive, CreatedDate)
VALUES ('student@lms.com', 'BPiZbadjt6lpsQKO4wB1aerzpjVIbdqyEdUSyFud+Ps=', 'Test', 'Student', 'Male', 'Student', 1, GETDATE());

-- Verify
SELECT Id, Email, FirstName, LastName, Role FROM Users;
```

**Credentials:**
- Admin: `admin@lms.com` / `admin123`
- Student: `student@lms.com` / `student123`

### Option 2: Using Scanner (Proper)

1. Create test folders:
```
C:\LMS_Content\
  Books\
    Math101\
      Chapter1\
        sample.txt
  Courses\
    WebDev\
      Lesson1\
        intro.txt
```

2. Login to frontend as admin
3. Go to Admin Panel → Scanner tab
4. Enter path: `C:\LMS_Content`
5. Click "Scan Courses"

This will create:
- 2 Categories (Books, Courses)
- 2 Courses (Math101, WebDev)
- Folders and files

---

## 🐛 Troubleshooting

### Error: "Build failed"
**Solution:** Check for compilation errors in Visual Studio or run:
```powershell
dotnet build
```
Fix any errors shown.

### Error: "Unable to connect to database"
**Solution:** 
1. Check SQL Server is running
2. Verify connection string in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=EMAAN-PC;Database=LMSDB;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
  }
}
```

### Error: "A network-related or instance-specific error"
**Solution:**
1. Open SQL Server Configuration Manager
2. Enable TCP/IP protocol
3. Restart SQL Server service

### Still Getting 500 Error?
**Check the API console output for the actual error message.**

Common issues:
- Missing table → Run migration again
- Wrong connection string → Check `appsettings.json`
- Port already in use → Kill process on port 5000

To check what's on port 5000:
```powershell
Get-Process -Id (Get-NetTCPConnection -LocalPort 5000).OwningProcess
```

---

## 📝 After Fix - Test Checklist

- [ ] API starts without errors
- [ ] Swagger page loads
- [ ] GET /api/courses/categories returns 200 (even if empty)
- [ ] Database has all 5 tables
- [ ] Users table has Role column
- [ ] Courses table has CategoryId column
- [ ] Can create a user via API or SQL
- [ ] Can login and get response with role

---

## 🎉 Next Steps

Once the backend is working:

1. **Test the scanner:**
   - Create test folder structure
   - Use scanner to import
   - Verify categories and courses created

2. **Update Frontend:**
   - Follow IMPLEMENTATION_GUIDE.md
   - Start with updating models
   - Then update services
   - Then update components

---

## 💡 Pro Tips

1. **Always check the API console** for error messages when something fails
2. **Use Swagger** to test endpoints before using them in frontend
3. **Check database** after operations to verify data was saved
4. **Keep API running** while developing frontend

---

## 📞 If You're Still Stuck

Run this diagnostic command and share the output:

```powershell
cd C:\LMSSystem\LMS.API
dotnet build 2>&1 | Tee-Object build-log.txt
dotnet ef migrations list 2>&1 | Tee-Object migrations-log.txt
```

Then check `build-log.txt` and `migrations-log.txt` for errors.

---

**Good luck! The backend should work after this. 🚀**
