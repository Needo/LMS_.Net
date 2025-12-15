# LMS Project Structure

## Backend (C:\LMSSystem\LMS.API)
- **Models**: Course.cs, CourseItem.cs
- **Services**: CourseService.cs (handles scan, CRUD)
- **Controllers**: CoursesController.cs, FilesController.cs
- **Database**: SQL Server (EMAAN-PC), EF Core

## Frontend (C:\LMSSystem\LMSUI)
- **Components**: header, sidebar, viewer, admin, main-layout
- **Services**: course.service.ts
- **Models**: course.model.ts

## Key Features Implemented:
- Course scanning from file system
- Tree view navigation
- Video/audio/document viewer
- Bulk database operations for performance
```

Share this at the start of a new conversation, then I'll remember the structure!

### 3. **Reference Previous Conversations**
Start your message with context:
```
Following our previous work where we optimized the scan with bulk inserts,
now I want to add course deletion. Here's the CoursesController.cs:
[paste file]
```

### 4. **Share File Paths Instead of Content**
Just tell me the structure:
```
I need to modify:
- LMS.API/Controllers/CoursesController.cs
- LMSUI/src/app/services/course.service.ts

Add a delete course method that removes from DB and updates UI.
```

I know the standard patterns and can generate code without seeing the full files!

### 5. **Use Targeted Questions**
Instead of: "Here's my entire codebase, what's wrong?"

Ask: "My scan is still slow. Here's the ScanDirectoryAsync method: [paste method]"

---

## **Token-Saving Tips:**

### ✅ DO:
- Share only the specific file/method you're changing
- Describe changes you've made: "I added a search box in sidebar"
- Ask for specific features: "Add delete button to admin panel"
- Reference file paths: "Update CourseService.cs to include..."

### ❌ DON'T:
- Upload entire node_modules or bin/obj folders
- Share all files when only changing one
- Paste long generated files (migrations, package-lock.json)

---

## **For Your Next Session:**

Just start with:
```
Working on the LMS system we built (Angular + ASP.NET Core + SQL Server).
I want to [specific feature].
Here's the relevant file: [paste only that file]