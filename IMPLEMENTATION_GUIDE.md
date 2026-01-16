# LMS System v2.0 - Implementation Guide

## 🚀 What's New in v2.0

### Backend Changes
✅ **Categories Model** - Root folders become categories
✅ **User Roles** - Admin and Student roles added
✅ **Course Subscriptions** - Users can subscribe to courses
✅ **New API Endpoints** - Categories, subscriptions, folder contents
✅ **Enhanced Course Scanner** - 3-level hierarchy support

### Database Schema Changes
- Added `Categories` table
- Added `UserCourseSubscriptions` table
- Added `Role` column to `Users` table
- Added `CategoryId` foreign key to `Courses` table

---

## 📋 Step-by-Step Migration Instructions

### Step 1: Apply Database Migration

**Option A: Using PowerShell Script (Recommended)**
```powershell
cd C:\LMSSystem
.\apply-migration.ps1
```

**Option B: Manual Commands**
```bash
cd C:\LMSSystem\LMS.API
dotnet ef migrations add CategoryAndSubscriptionFeatures
dotnet ef database update
```

### Step 2: Verify Database Schema

After migration, your database should have these tables:
- ✅ Categories
- ✅ Courses (with CategoryId column)
- ✅ CourseItems
- ✅ Users (with Role column)
- ✅ UserCourseSubscriptions

### Step 3: Update Existing User Data

Run this SQL to add role to existing users:
```sql
-- Set first user as Admin
UPDATE Users SET Role = 'Admin' WHERE Id = 1;

-- Set other users as Students
UPDATE Users SET Role = 'Student' WHERE Id > 1;
```

### Step 4: Test Backend API

Start the API:
```bash
cd C:\LMSSystem\LMS.API
dotnet run
```

Test in browser: `http://localhost:5000/swagger`

**Verify these endpoints exist:**
- GET `/api/courses/categories`
- GET `/api/subscriptions/user/{userId}`
- POST `/api/subscriptions/subscribe`

---

## 🎯 Frontend Implementation Tasks

The backend is now complete. Here are the frontend components that need to be created/updated:

### Priority 1: Update Models

**File:** `LMSUI/src/app/models/course.model.ts`
```typescript
export interface Category {
  id: number;
  name: string;
  path: string;
  createdDate: Date;
  courses?: Course[];
}

export interface Course {
  id: number;
  categoryId: number;
  name: string;
  path: string;
  createdDate: Date;
  category?: Category;
}

// CourseItem stays the same
```

**File:** `LMSUI/src/app/models/subscription.model.ts` (NEW)
```typescript
export interface UserCourseSubscription {
  id: number;
  userId: number;
  courseId: number;
  subscribedDate: Date;
}

export interface SubscriptionRequest {
  userId: number;
  courseId: int;
}
```

**File:** `LMSUI/src/app/models/user.model.ts` (UPDATE)
```typescript
export interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  sex: string;
  role: string; // 'Admin' or 'Student'
  isActive: boolean;
  createdDate: Date;
  lastLoginDate?: Date;
}
```

### Priority 2: Update Services

**File:** `LMSUI/src/app/services/course.service.ts`
```typescript
// Add these methods:
getCategories(): Observable<Category[]>
getCoursesByCategory(categoryId: number): Observable<Course[]>
getFolderContents(folderId: number): Observable<CourseItem[]>
```

**File:** `LMSUI/src/app/services/subscription.service.ts` (NEW)
```typescript
// Create new service with methods:
getUserSubscriptions(userId: number)
getUserSubscribedCourseIds(userId: number)
subscribe(userId: number, courseId: number)
unsubscribe(userId: number, courseId: number)
isSubscribed(userId: number, courseId: number)
```

### Priority 3: Update Components

#### 3.1 Admin Component - Add 3 Tabs

**File:** `LMSUI/src/app/components/admin/admin.component.ts`

Add Angular Material Tabs:
```typescript
import { MatTabsModule } from '@angular/material/tabs';

// Template with 3 tabs:
// Tab 1: Scanner (existing)
// Tab 2: Backup/Restore (new)
// Tab 3: User Management (new)
```

**Tab 2: Database Backup/Restore**
- Add export database button
- Add import database button
- Show backup history table

**Tab 3: User Management**
- Display users table with columns:
  - Email, Name, Sex, Role, Active
  - For each user, show all courses with checkboxes
  - Check = Subscribed, Uncheck = Unsubscribed
- Add create/edit/delete user buttons

#### 3.2 Header Component - Update Navigation

**File:** `LMSUI/src/app/components/header/header.component.ts`

Update template:
```html
<mat-toolbar color="primary">
  <!-- Left: App Name -->
  <span class="app-title">Learning Management System</span>
  
  <!-- Center: User Info -->
  <span class="user-info">
    {{ currentUser.firstName }} {{ currentUser.lastName }} 
    ({{ currentUser.role }})
  </span>
  
  <!-- Right: Buttons -->
  <span class="spacer"></span>
  <button mat-button *ngIf="currentUser.role === 'Admin'" 
          (click)="navigateToAdmin()">
    <mat-icon>admin_panel_settings</mat-icon>
    Admin Panel
  </button>
  <button mat-button (click)="logout()">
    <mat-icon>logout</mat-icon>
    Logout
  </button>
</mat-toolbar>
```

#### 3.3 Sidebar Component - Category Tree View

**File:** `LMSUI/src/app/components/sidebar/sidebar.component.ts`

Update to show:
```
📚 Category Name (e.g., Books)
  📖 Course Name (e.g., Math 101)
  📖 Course Name (e.g., Physics 201)
📚 Category Name (e.g., Courses)
  📖 Course Name
```

When course is clicked:
- Load top-level course items
- Show them in tree below course node

When folder is clicked:
- Emit event to show folder contents in table view

When file is clicked:
- Emit event to open file in viewer panel

#### 3.4 Create Content Table Component (NEW)

**File:** `LMSUI/src/app/components/content-table/content-table.component.ts`

Create a table view component to display folder contents:

**Columns:**
- Icon
- Name
- Type
- Size
- Actions (View button)

**Features:**
- Click row to select
- Double-click to open in viewer
- Sort by name, type, size
- Filter by type

#### 3.5 Update Viewer Component

**File:** `LMSUI/src/app/components/viewer/viewer.component.ts`

Add EPUB viewer support:
```typescript
// Add epub.js library
npm install epubjs

// In component:
if (selectedItem.extension === '.epub') {
  // Render EPUB book
}
```

#### 3.6 Main Layout - Resizable Panels

**File:** `LMSUI/src/app/components/main-layout/main-layout.component.ts`

Install Angular Split library:
```bash
npm install angular-split
```

Update template:
```html
<as-split direction="horizontal" unit="percent">
  <!-- Left Panel: Sidebar -->
  <as-split-area [size]="25" [minSize]="15" [maxSize]="50">
    <app-sidebar (fileSelected)="onFileSelected($event)"
                 (folderSelected)="onFolderSelected($event)">
    </app-sidebar>
  </as-split-area>
  
  <!-- Right Panel: Table or Viewer -->
  <as-split-area [size]="75">
    <app-content-table *ngIf="showTable" 
                       [items]="folderContents">
    </app-content-table>
    <app-viewer *ngIf="!showTable" 
                [selectedItem]="selectedFile">
    </app-viewer>
  </as-split-area>
</as-split>
```

---

## 🧪 Testing Checklist

### Backend Testing
- [ ] Scan courses with 3-level folder structure
- [ ] Verify categories are created from root folders
- [ ] Verify courses are created from first-level folders
- [ ] Subscribe user to course
- [ ] Unsubscribe user from course
- [ ] Get user's subscribed courses
- [ ] Get folder contents by folder ID

### Frontend Testing (After Implementation)
- [ ] Login as Admin
- [ ] Navigate to Admin Panel
- [ ] Test Scanner tab
- [ ] Test User Management tab (subscribe/unsubscribe)
- [ ] View categories in tree
- [ ] Expand category to see courses
- [ ] Expand course to see contents
- [ ] Click folder to show table view
- [ ] Click file to show in viewer
- [ ] Test video playback
- [ ] Test PDF viewer
- [ ] Test EPUB viewer (once implemented)
- [ ] Test resizable splitter
- [ ] Logout

---

## 📦 Required npm Packages (Frontend)

Add these to your Angular project:

```bash
cd LMSUI

# For resizable panels
npm install angular-split

# For EPUB viewer
npm install epubjs
npm install @types/epubjs --save-dev

# For better table functionality
npm install @angular/material-table
```

---

## 🎨 UI Design Recommendations

### Color Scheme
- **Primary:** Material Blue (#1976d2)
- **Accent:** Material Orange (#ff9800)
- **Warn:** Material Red (#f44336)
- **Background:** Light Gray (#f5f5f5)

### Icons
- Category: `category` or `folder_open`
- Course: `school` or `book`
- Folder: `folder`
- Video: `play_circle`
- Audio: `audiotrack`
- Document: `description`
- EPUB: `menu_book`

### Spacing
- Panel padding: 16px
- Content margin: 24px
- Card spacing: 16px gap

---

## 🔄 Migration Strategy for Existing Data

If you have existing course data, run this SQL to migrate:

```sql
-- Step 1: Create a default category
INSERT INTO Categories (Name, Path, CreatedDate)
VALUES ('General', 'C:\Courses', GETDATE());

-- Step 2: Update all courses to use this category
DECLARE @CategoryId INT;
SELECT @CategoryId = Id FROM Categories WHERE Name = 'General';

UPDATE Courses SET CategoryId = @CategoryId WHERE CategoryId IS NULL OR CategoryId = 0;

-- Step 3: Verify
SELECT c.Name AS CourseName, cat.Name AS CategoryName
FROM Courses c
INNER JOIN Categories cat ON c.CategoryId = cat.Id;
```

---

## ⚠️ Important Notes

### Breaking Changes
1. **Course model changed:** Now requires `CategoryId`
2. **User model changed:** Now requires `Role`
3. **API responses changed:** Courses now include category information

### Backward Compatibility
- Old course items will still work
- File viewer functionality unchanged
- Authentication endpoints unchanged

### Performance Considerations
- Use lazy loading for large category trees
- Implement pagination for user management
- Cache category list (changes rarely)
- Index on `CategoryId` and foreign keys

---

## 📞 Troubleshooting

### Migration Fails
```bash
# Drop and recreate database
dotnet ef database drop
dotnet ef database update
```

### "CategoryId cannot be null" error
- Ensure all courses have a valid CategoryId
- Run the migration SQL script above

### CORS Issues
- Verify Program.cs has correct CORS policy
- Check frontend makes requests to `http://localhost:5000`

---

## 🎯 Next Steps After Implementation

1. ✅ Verify all backend endpoints work
2. ✅ Implement frontend models and services
3. ✅ Create new components
4. ✅ Update existing components
5. ✅ Add EPUB viewer
6. ✅ Implement resizable panels
7. ✅ Test entire workflow
8. ✅ Deploy to staging environment
9. ✅ Get user feedback
10. ✅ Deploy to production

---

## 📚 Additional Resources

- **Angular Split:** https://github.com/angular-split/angular-split
- **epub.js:** http://epubjs.org/
- **Angular Material:** https://material.angular.io/
- **EF Core Migrations:** https://docs.microsoft.com/ef/core/managing-schemas/migrations/

---

**Questions or Issues?**
Refer to the PROJECT_ANALYSIS.md for detailed architecture information.

Good luck with the implementation! 🚀
