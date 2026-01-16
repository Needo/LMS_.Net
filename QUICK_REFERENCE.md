# LMS v2.0 - Quick Reference & Changes Summary

## 📊 What Changed

### New Database Tables
1. **Categories** - Stores root folder categories (Books, Courses, Documents)
2. **UserCourseSubscriptions** - Maps users to their subscribed courses

### Modified Tables
1. **Users** - Added `Role` column (Admin/Student)
2. **Courses** - Added `CategoryId` foreign key

### New Hierarchy Structure
```
Root Folder (e.g., C:\LMS_Content)
├── Books/                          ← CATEGORY
│   ├── Math101/                    ← COURSE
│   │   ├── Chapter1/               ← FOLDER (CourseItem)
│   │   │   ├── video1.mp4         ← FILE (CourseItem)
│   │   │   └── notes.pdf          ← FILE (CourseItem)
│   │   └── Chapter2/              ← FOLDER (CourseItem)
│   └── Physics201/                ← COURSE
├── Courses/                       ← CATEGORY
│   └── WebDev/                    ← COURSE
└── Documents/                     ← CATEGORY
    └── Reference/                 ← COURSE
```

---

## 🔌 New API Endpoints

### Categories
```http
GET /api/courses/categories
  → Returns all categories with their courses

GET /api/courses/categories/{categoryId}/courses
  → Returns all courses in a specific category
```

### Folder Contents
```http
GET /api/courses/folders/{folderId}/contents
  → Returns direct children of a folder (for table view)
```

### Subscriptions
```http
GET /api/subscriptions/user/{userId}
  → Get all course subscriptions for a user

GET /api/subscriptions/user/{userId}/course-ids
  → Get just the course IDs user is subscribed to

POST /api/subscriptions/subscribe
  Body: { "userId": 1, "courseId": 5 }
  → Subscribe user to course

POST /api/subscriptions/unsubscribe
  Body: { "userId": 1, "courseId": 5 }
  → Unsubscribe user from course

GET /api/subscriptions/check?userId=1&courseId=5
  → Check if user is subscribed to course
```

---

## 🎯 Key Features Overview

### For Administrators
✅ Scan file system with 3-level hierarchy
✅ Manage users (create, edit, delete, set roles)
✅ Manage course subscriptions per user
✅ Backup and restore database
✅ View all categories and courses

### For Students
✅ View only subscribed courses
✅ Browse course content in tree view
✅ View folder contents in table
✅ Play videos and audio
✅ Read documents (PDF, TXT, HTML, EPUB)

---

## 📁 Frontend Components Needed

### New Components
1. **content-table/** - Table view for folder contents
2. **admin/tabs/backup/** - Database backup/restore tab
3. **admin/tabs/user-management/** - User CRUD + subscriptions

### Components to Update
1. **header/** - Add app name, user info, admin button, logout
2. **sidebar/** - Show categories → courses tree structure
3. **viewer/** - Add EPUB support
4. **admin/** - Convert to tabbed interface (3 tabs)
5. **main-layout/** - Add resizable split panels

### New Services
1. **subscription.service.ts** - Handle course subscriptions

### Models to Update
1. **course.model.ts** - Add Category interface
2. **user.model.ts** - Add role property
3. **subscription.model.ts** - NEW file

---

## 🗂️ File Organization (Updated)

```
LMSUI/src/app/
├── components/
│   ├── login/
│   ├── header/                     ← UPDATE (add user info, logout)
│   ├── sidebar/                    ← UPDATE (category tree)
│   ├── content-table/              ← NEW (folder contents table)
│   ├── viewer/                     ← UPDATE (add EPUB)
│   ├── main-layout/                ← UPDATE (resizable panels)
│   └── admin/
│       ├── admin.component.ts      ← UPDATE (3 tabs)
│       └── tabs/
│           ├── scanner/
│           ├── backup/             ← NEW
│           └── user-management/    ← NEW
├── services/
│   ├── auth.service.ts
│   ├── course.service.ts           ← UPDATE (add category methods)
│   └── subscription.service.ts     ← NEW
└── models/
    ├── course.model.ts             ← UPDATE (add Category)
    ├── user.model.ts               ← UPDATE (add role)
    └── subscription.model.ts       ← NEW
```

---

## 🎨 UI Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│ [LMS] User Name (Admin)      [Admin Panel] [Logout]    │ ← Header
├──────────────┬──────────────────────────────────────────┤
│              │                                          │
│  Categories  │         Content Area                     │
│  ├─📚 Books  │  ┌────────────────────────────────┐    │
│  │ ├─📖 Math │  │ Folder Table OR File Viewer    │    │
│  │ └─📖 Phys │  │                                │    │
│  ├─📚 Course │  │  When folder clicked → Table   │    │
│  └─📚 Docs   │  │  When file clicked → Viewer    │    │
│              │  └────────────────────────────────┘    │
│              │                                          │
│              │                                          │
└──────────────┴──────────────────────────────────────────┘
    ↑                           ↑
   25% width               75% width
  (resizable)            (resizable)
```

---

## 🔄 Sample Data Flow

### 1. Login Flow
```
User enters email/password
  → POST /api/auth/login
  → Receive: { userId, email, firstName, lastName, role, token }
  → Store user info in localStorage
  → Navigate to main-layout
```

### 2. Load Categories & Courses
```
Component loads
  → GET /api/courses/categories
  → Receive: [{ id, name, courses: [...] }]
  → Display in sidebar tree
```

### 3. User Clicks Course
```
User clicks "Math 101" course
  → GET /api/courses/{courseId}/items
  → Receive top-level course items (folders/files)
  → Display in tree under course node
```

### 4. User Clicks Folder
```
User clicks a folder node
  → GET /api/courses/folders/{folderId}/contents
  → Receive folder children
  → Show in content-table component
```

### 5. User Clicks File
```
User clicks a video file
  → Hide content-table
  → Show viewer component
  → Load file: GET /api/files?path={filePath}
  → Display in video player
```

### 6. Admin Manages Subscriptions
```
Admin goes to User Management tab
  → GET /api/auth/users (all users)
  → For each user:
    → GET /api/subscriptions/user/{userId}/course-ids
    → Show courses with checkboxes (checked = subscribed)
  → User checks/unchecks course
    → POST /api/subscriptions/subscribe or unsubscribe
```

---

## 📋 Testing Scenarios

### Scenario 1: Scan New Content
1. Admin logs in
2. Goes to Admin Panel → Scanner tab
3. Enters path: `C:\LMS_Content`
4. Clicks "Scan Courses"
5. Expected Result:
   - Categories created from root folders
   - Courses created from first-level subfolders
   - Content scanned recursively

### Scenario 2: Subscribe User to Course
1. Admin logs in
2. Goes to Admin Panel → User Management tab
3. Selects a student user
4. Checks checkbox next to "Math 101"
5. Expected Result:
   - Subscription created
   - Student can now see Math 101 in their course list

### Scenario 3: Browse Course Content
1. Student logs in
2. Sees categories in left sidebar
3. Expands "Books" category
4. Clicks "Math 101" course
5. Sees course folders/files in tree
6. Clicks "Chapter 1" folder
7. Sees folder contents in table view
8. Clicks "video1.mp4" in table
9. Video plays in viewer panel

---

## 🚨 Common Issues & Solutions

### Issue: "CategoryId cannot be null"
**Solution:** Run SQL migration script to assign categories to existing courses

### Issue: CORS error when calling API
**Solution:** Verify CORS policy in Program.cs allows localhost:4200

### Issue: Tree view doesn't expand
**Solution:** Check that GetCourseItems returns proper hierarchy

### Issue: User role not showing
**Solution:** Verify LoginResponse includes role property

### Issue: Subscription not working
**Solution:** Check UserCourseSubscriptions table has unique constraint on UserId+CourseId

---

## 📦 NPM Packages to Install

```bash
npm install angular-split          # Resizable panels
npm install epubjs                 # EPUB viewer
npm install @types/epubjs --save-dev
npm install @angular/cdk           # Already installed (Material dependency)
```

---

## 🎯 Implementation Priority Order

1. ✅ **Backend Complete** - All models, services, controllers done
2. 🔄 **Apply Migration** - Run apply-migration.ps1
3. ⏳ **Update Frontend Models** - Add Category, update User/Course
4. ⏳ **Update Services** - Add category/subscription methods
5. ⏳ **Update Header** - Add user info and logout
6. ⏳ **Update Sidebar** - Show category tree
7. ⏳ **Create Content Table** - For folder contents
8. ⏳ **Update Admin Panel** - Add 3 tabs
9. ⏳ **Add Resizable Panels** - Install angular-split
10. ⏳ **Add EPUB Support** - Install epub.js

---

## 🎓 Best Practices

### Security
- ✅ Validate user roles before showing admin features
- ✅ Check subscriptions before loading course content
- ✅ Sanitize file paths on backend

### Performance
- ✅ Load categories once, cache in service
- ✅ Lazy load course items (don't load all at once)
- ✅ Use pagination for large folder contents

### UX
- ✅ Show loading spinners during API calls
- ✅ Display error messages clearly
- ✅ Confirm before deleting users
- ✅ Auto-refresh tree after subscription changes

---

## 📞 Quick Command Reference

### Backend
```bash
# Start API
cd C:\LMSSystem\LMS.API
dotnet run

# Create migration
dotnet ef migrations add MigrationName

# Apply migration
dotnet ef database update

# Drop database
dotnet ef database drop
```

### Frontend
```bash
# Start dev server
cd C:\LMSSystem\LMSUI
ng serve

# Build for production
ng build --configuration production

# Run tests
ng test
```

---

## ✅ Definition of Done Checklist

- [ ] Backend migration applied successfully
- [ ] All new API endpoints tested in Swagger
- [ ] Frontend models updated
- [ ] Services updated with new methods
- [ ] Components created/updated
- [ ] Resizable panels working
- [ ] EPUB viewer functional
- [ ] User subscriptions working
- [ ] Admin panel has 3 tabs
- [ ] Scanner creates categories correctly
- [ ] Tree view shows categories → courses → content
- [ ] Table view shows folder contents
- [ ] Viewer supports all file types
- [ ] Logout works correctly
- [ ] Roles restrict access properly

---

**Version:** 2.0  
**Last Updated:** January 2026  
**Status:** Backend Complete ✅ | Frontend In Progress 🔄
