# LMS v2.0 Implementation Checklist

Use this checklist to track your implementation progress.

---

## 📋 Phase 1: Backend Setup & Migration

### Database Migration
- [ ] Navigate to `C:\LMSSystem`
- [ ] Run `.\apply-migration.ps1`
- [ ] Verify migration succeeded (check console output)
- [ ] Open SQL Server Management Studio
- [ ] Verify `Categories` table exists
- [ ] Verify `UserCourseSubscriptions` table exists
- [ ] Verify `Users` table has `Role` column
- [ ] Verify `Courses` table has `CategoryId` column

### Test Backend API
- [ ] Start backend: `cd C:\LMSSystem\LMS.API && dotnet run`
- [ ] Open browser to `http://localhost:5000/swagger`
- [ ] Test `GET /api/courses/categories` endpoint
- [ ] Test `GET /api/subscriptions/user/{userId}` endpoint
- [ ] Test `POST /api/subscriptions/subscribe` endpoint
- [ ] Verify all endpoints return expected responses

### Initial Data Setup
- [ ] Create admin user via SQL or API
- [ ] Run SQL: `UPDATE Users SET Role = 'Admin' WHERE Id = 1`
- [ ] Create test folder structure:
  ```
  C:\LMS_TestContent\
    Books\
      Math101\
        Chapter1\
          video.mp4
      Physics\
    Courses\
      WebDev\
  ```
- [ ] Use Scanner to import test content
- [ ] Verify categories, courses, and items created correctly

---

## 📋 Phase 2: Frontend Models & Services

### Update Models
- [ ] Open `LMSUI/src/app/models/course.model.ts`
- [ ] Add `Category` interface:
  ```typescript
  export interface Category {
    id: number;
    name: string;
    path: string;
    createdDate: Date;
    courses?: Course[];
  }
  ```
- [ ] Update `Course` interface to add `categoryId` and `category`
- [ ] Save file

- [ ] Open `LMSUI/src/app/models/user.model.ts`
- [ ] Add `role: string` property to `User` interface
- [ ] Update `LoginResponse` to include `role`
- [ ] Save file

- [ ] Create `LMSUI/src/app/models/subscription.model.ts`
- [ ] Add subscription interfaces
- [ ] Save file

### Update Course Service
- [ ] Open `LMSUI/src/app/services/course.service.ts`
- [ ] Add method: `getCategories(): Observable<Category[]>`
- [ ] Add method: `getCoursesByCategory(categoryId: number): Observable<Course[]>`
- [ ] Add method: `getFolderContents(folderId: number): Observable<CourseItem[]>`
- [ ] Save file
- [ ] Test methods using console.log()

### Create Subscription Service
- [ ] Create `LMSUI/src/app/services/subscription.service.ts`
- [ ] Implement `getUserSubscriptions(userId: number)`
- [ ] Implement `subscribe(userId: number, courseId: number)`
- [ ] Implement `unsubscribe(userId: number, courseId: number)`
- [ ] Implement `isSubscribed(userId: number, courseId: number)`
- [ ] Save file
- [ ] Test methods

---

## 📋 Phase 3: Update Existing Components

### Update Header Component
- [ ] Open `LMSUI/src/app/components/header/header.component.ts`
- [ ] Add property: `currentUser: User | null = null`
- [ ] Subscribe to `authService.currentUser$` in ngOnInit
- [ ] Update template to show:
  - [ ] App name "Learning Management System" (left)
  - [ ] User name and role (center)
  - [ ] Admin button if user.role === 'Admin' (right)
  - [ ] Logout button (right)
- [ ] Add `navigateToAdmin()` method
- [ ] Add `logout()` method
- [ ] Test layout and buttons

### Update Sidebar Component
- [ ] Open `LMSUI/src/app/components/sidebar/sidebar.component.ts`
- [ ] Change from loading courses to loading categories
- [ ] Update `ngOnInit` to call `courseService.getCategories()`
- [ ] Update tree structure to show: Category → Courses → CourseItems
- [ ] Update template to handle 3-level tree
- [ ] Add `@Output() folderSelected = new EventEmitter<CourseItem>()`
- [ ] Emit folder selection when folder node clicked
- [ ] Test category tree expansion

### Update Viewer Component
- [ ] Open `LMSUI/src/app/components/viewer/viewer.component.ts`
- [ ] Install epub.js: `npm install epubjs @types/epubjs --save-dev`
- [ ] Import epub.js
- [ ] Add EPUB viewer logic for `.epub` files
- [ ] Test with sample EPUB file

---

## 📋 Phase 4: Create New Components

### Create Content Table Component
- [ ] Generate component: `ng g c components/content-table`
- [ ] Add `@Input() items: CourseItem[] = []`
- [ ] Add `@Output() fileSelected = new EventEmitter<CourseItem>()`
- [ ] Create table with columns: Icon, Name, Type, Size, Actions
- [ ] Add click handlers to emit file selection
- [ ] Add sorting by column
- [ ] Style with Material table
- [ ] Test with folder data

### Update Main Layout Component
- [ ] Open `LMSUI/src/app/components/main-layout/main-layout.component.ts`
- [ ] Install angular-split: `npm install angular-split`
- [ ] Import `AngularSplitModule`
- [ ] Add resizable splitter to template
- [ ] Left panel (25%): `<app-sidebar>`
- [ ] Right panel (75%): `<app-content-table>` OR `<app-viewer>`
- [ ] Add logic to switch between table and viewer
- [ ] Handle sidebar events (file click, folder click)
- [ ] Test resizing
- [ ] Test content switching

---

## 📋 Phase 5: Update Admin Panel

### Convert Admin to Tabs
- [ ] Open `LMSUI/src/app/components/admin/admin.component.ts`
- [ ] Import `MatTabsModule`
- [ ] Update template to use `<mat-tab-group>`
- [ ] Create 3 tabs: Scanner, Backup, User Management
- [ ] Move existing scanner content to first tab
- [ ] Test tab switching

### Create Backup Tab Component
- [ ] Generate component: `ng g c components/admin/tabs/backup`
- [ ] Add "Export Database" button
- [ ] Add "Import Database" button
- [ ] Add file upload input for import
- [ ] Add success/error messages
- [ ] Create backend endpoints (future):
  - [ ] `POST /api/database/backup`
  - [ ] `POST /api/database/restore`
- [ ] Test UI (backend functionality can be placeholder)

### Create User Management Tab Component
- [ ] Generate component: `ng g c components/admin/tabs/user-management`
- [ ] Load all users on init
- [ ] For each user, load their subscribed course IDs
- [ ] Display users in expandable panels or table
- [ ] For each user, show all courses with checkboxes
- [ ] Check box if user is subscribed
- [ ] Implement checkbox change handler:
  - [ ] If checked → call `subscriptionService.subscribe()`
  - [ ] If unchecked → call `subscriptionService.unsubscribe()`
- [ ] Add "Create User" button and dialog
- [ ] Add "Edit User" button
- [ ] Add "Delete User" button with confirmation
- [ ] Test subscription toggle
- [ ] Test CRUD operations

---

## 📋 Phase 6: Testing & Polish

### Functional Testing
- [ ] Test login as admin
- [ ] Test login as student
- [ ] Test admin can access admin panel
- [ ] Test student cannot access admin panel
- [ ] Test scanner creates categories correctly
- [ ] Test scanner creates courses under categories
- [ ] Test scanner creates course items
- [ ] Test category tree loads correctly
- [ ] Test course tree loads under category
- [ ] Test folder click shows table view
- [ ] Test file click shows viewer
- [ ] Test video playback
- [ ] Test audio playback
- [ ] Test PDF viewer
- [ ] Test text file viewer
- [ ] Test HTML viewer
- [ ] Test EPUB viewer (if implemented)
- [ ] Test download for unsupported files
- [ ] Test resizable splitter
- [ ] Test user subscription toggle
- [ ] Test logout

### UI/UX Testing
- [ ] Test responsive design on different screen sizes
- [ ] Test loading states show correctly
- [ ] Test error messages display properly
- [ ] Test success messages display properly
- [ ] Test empty states (no categories, no courses, etc.)
- [ ] Test long file names truncate properly
- [ ] Test tree view indentation is correct
- [ ] Test icons match file types
- [ ] Test color coding is consistent

### Performance Testing
- [ ] Test with 100+ courses
- [ ] Test with deeply nested folders (5+ levels)
- [ ] Test with large video files (>100MB)
- [ ] Test with 50+ users
- [ ] Verify no memory leaks (leave app open for 30 minutes)
- [ ] Check browser console for errors
- [ ] Verify API responses are fast (<500ms for most)

### Security Testing
- [ ] Verify student cannot access admin endpoints
- [ ] Verify role check works on frontend
- [ ] Verify file paths are sanitized
- [ ] Verify subscription check works
- [ ] Verify logout clears session
- [ ] Test with invalid tokens (future JWT)

---

## 📋 Phase 7: Documentation & Deployment

### Code Documentation
- [ ] Add JSDoc comments to services
- [ ] Add comments to complex logic
- [ ] Update README.md with setup instructions
- [ ] Document environment variables
- [ ] Document API endpoints in Swagger

### Deployment Preparation
- [ ] Build Angular in production mode
- [ ] Verify production build works
- [ ] Update connection string for production DB
- [ ] Configure CORS for production domain
- [ ] Set up SSL certificate
- [ ] Configure IIS or hosting platform
- [ ] Set up database backups
- [ ] Configure logging
- [ ] Create deployment script

### User Documentation
- [ ] Create admin user guide (PDF)
- [ ] Create student user guide (PDF)
- [ ] Create video tutorial for scanning courses
- [ ] Create FAQ document
- [ ] Create troubleshooting guide

---

## 📋 Phase 8: Optional Enhancements

### Nice-to-Have Features
- [ ] Implement JWT authentication
- [ ] Add password reset functionality
- [ ] Add "Remember Me" on login
- [ ] Add video progress tracking
- [ ] Add course completion tracking
- [ ] Add search functionality
- [ ] Add favorites/bookmarks
- [ ] Add recent files list
- [ ] Add file preview on hover
- [ ] Add keyboard shortcuts
- [ ] Add dark mode
- [ ] Add mobile app (future)

### Performance Optimizations
- [ ] Implement lazy loading for course items
- [ ] Add pagination to user management
- [ ] Cache categories in localStorage
- [ ] Implement virtual scrolling for large lists
- [ ] Add database indexes
- [ ] Optimize SQL queries
- [ ] Implement CDN for static files

---

## ✅ Completion Criteria

Mark this checklist complete when:
- [ ] All backend tests pass
- [ ] All frontend features work as expected
- [ ] No console errors in browser
- [ ] No warnings in API logs
- [ ] Documentation is complete
- [ ] Code is reviewed and clean
- [ ] Security checks pass
- [ ] Performance is acceptable
- [ ] User acceptance testing complete

---

## 📊 Progress Tracking

**Overall Progress:**
- Backend: ✅ 100% Complete
- Frontend Models: ⏳ 0%
- Frontend Services: ⏳ 0%
- Frontend Components: ⏳ 0%
- Testing: ⏳ 0%
- Documentation: ✅ 100%

**Estimated Time Remaining:** 2-3 days

---

## 🎯 Current Sprint Focus

**This Week:**
1. Apply database migration
2. Test backend API thoroughly
3. Update frontend models and services
4. Update sidebar to show categories

**Next Week:**
1. Create content table component
2. Add resizable panels
3. Update admin panel with tabs
4. Create user management interface

---

## 📝 Notes & Issues

Use this section to track any issues or notes during implementation:

```
Issue: [Date] - Description
Solution: Description

Example:
Issue: 2026-01-16 - Migration failed due to existing data
Solution: Cleared old data first, then ran migration successfully
```

---

**Last Updated:** [Update this date when you complete tasks]  
**Started By:** [Your name]  
**Status:** In Progress 🔄
