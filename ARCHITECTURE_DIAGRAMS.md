# LMS System v2.0 - Visual Architecture Diagrams

## 1. Database Schema Diagram

```
┌─────────────────────┐
│    Categories       │
├─────────────────────┤
│ Id (PK)            │
│ Name               │
│ Path               │
│ CreatedDate        │
└─────────┬───────────┘
          │ 1
          │
          │ Many
┌─────────▼───────────┐
│      Courses        │
├─────────────────────┤
│ Id (PK)            │
│ CategoryId (FK) ───┼──────┐
│ Name               │      │
│ Path               │      │
│ CreatedDate        │      │
└─────────┬───────────┘      │
          │ 1                │
          │                  │
          │ Many             │
┌─────────▼───────────┐      │
│    CourseItems      │      │
├─────────────────────┤      │
│ Id (PK)            │      │
│ CourseId (FK) ─────┼──────┘
│ ParentId (FK)      │ (self-reference)
│ Name               │
│ Path               │
│ Type               │
│ Extension          │
│ Size               │
└─────────────────────┘

┌─────────────────────┐
│       Users         │
├─────────────────────┤
│ Id (PK)            │
│ Email              │
│ PasswordHash       │
│ FirstName          │
│ LastName           │
│ Sex                │
│ Role               │ ← NEW
│ IsActive           │
│ CreatedDate        │
│ LastLoginDate      │
└─────────┬───────────┘
          │ 1
          │
          │ Many
┌─────────▼────────────────┐
│ UserCourseSubscriptions  │ ← NEW TABLE
├──────────────────────────┤
│ Id (PK)                 │
│ UserId (FK) ────────────┼─────┐
│ CourseId (FK) ──────────┼──┐  │
│ SubscribedDate          │  │  │
└─────────────────────────┘  │  │
                             │  │
     ┌───────────────────────┘  │
     │                          │
     ▼                          ▼
   Courses                    Users
```

---

## 2. File System to Database Mapping

```
File System:                        Database:
───────────────────────────────    ─────────────────────────────

C:\LMS_Content\                    (Root - not stored)
│
├── Books\                    ───► Category
│   │                              (Name: "Books")
│   ├── Math101\             ───► Course
│   │   │                          (Name: "Math101", CategoryId: Books)
│   │   ├── Chapter1\        ───► CourseItem
│   │   │   │                      (Type: "folder", ParentId: NULL)
│   │   │   ├── video1.mp4   ───► CourseItem
│   │   │   │                      (Type: "video", ParentId: Chapter1)
│   │   │   └── notes.pdf    ───► CourseItem
│   │   │                          (Type: "document", ParentId: Chapter1)
│   │   └── Chapter2\        ───► CourseItem
│   │       └── quiz.pdf          (Type: "folder", ParentId: NULL)
│   │
│   └── Physics201\          ───► Course
│       └── ...                    (Name: "Physics201", CategoryId: Books)
│
├── Courses\                 ───► Category
│   └── WebDev\             ───► Course
│       └── ...
│
└── Documents\               ───► Category
    └── Reference\          ───► Course
        └── ...
```

---

## 3. API Request Flow Diagram

### User Login Flow
```
┌────────┐         POST /api/auth/login        ┌─────────────┐
│ Client │  ──────────────────────────────►   │ AuthController│
└────────┘   { email, password }              └──────┬──────┘
    ▲                                                 │
    │                                                 ▼
    │                                          ┌─────────────┐
    │                                          │ AuthService │
    │                                          └──────┬──────┘
    │                                                 │ Verify password
    │                                                 │ Get user from DB
    │                                                 ▼
    │           { userId, email, firstName,    ┌─────────────┐
    │             lastName, role, token }      │   Database  │
    └──────────────────────────────────────    └─────────────┘
```

### Get Categories and Courses Flow
```
┌────────┐     GET /api/courses/categories    ┌──────────────────┐
│ Client │  ────────────────────────────────► │ CoursesController│
└────────┘                                     └────────┬─────────┘
    ▲                                                   │
    │                                                   ▼
    │                                            ┌──────────────┐
    │                                            │CourseService │
    │                                            └──────┬───────┘
    │                                                   │ GetAllCategoriesAsync()
    │                                                   │ Include(c => c.Courses)
    │                                                   ▼
    │          [{ id: 1, name: "Books",          ┌────────────┐
    │            courses: [                      │  Database  │
    │              { id: 1, name: "Math101" },   └────────────┘
    │              { id: 2, name: "Physics" }
    │            ]},
    │            { id: 2, name: "Courses", ... }
    │          ]
    └────────────────────────────────────────
```

### Subscribe User to Course Flow
```
┌────────┐    POST /api/subscriptions/subscribe   ┌───────────────────────┐
│ Client │  ──────────────────────────────────►  │ SubscriptionsController│
└────────┘   { userId: 1, courseId: 5 }          └──────────┬────────────┘
    ▲                                                        │
    │                                                        ▼
    │                                                 ┌──────────────────┐
    │                                                 │SubscriptionService│
    │                                                 └──────────┬───────┘
    │                                                            │
    │                                                            │ 1. Check if exists
    │                                                            │ 2. Create subscription
    │                                                            │ 3. Save to DB
    │                                                            ▼
    │           { message: "Subscribed successfully" }   ┌────────────┐
    └──────────────────────────────────────────────────  │  Database  │
                                                          └────────────┘
```

---

## 4. Frontend Component Hierarchy

```
┌──────────────────────────────────────────────────────┐
│                    AppComponent                       │
└────────────────────┬─────────────────────────────────┘
                     │
                     ├─► LoginComponent (if not logged in)
                     │
                     └─► MainLayoutComponent (if logged in)
                         │
                         ├─► HeaderComponent
                         │   ├─ App Name (left)
                         │   ├─ User Info (center)
                         │   └─ Admin Button + Logout (right)
                         │
                         ├─► SidebarComponent (left panel, 25%)
                         │   └─ Tree View:
                         │      ├─ Category Node
                         │      │  └─ Course Node
                         │      │     └─ Folder Node
                         │      │        └─ File Node
                         │      └─ ...
                         │
                         └─► Content Area (right panel, 75%)
                             │
                             ├─► ContentTableComponent
                             │   └─ Shows folder contents
                             │      when folder is clicked
                             │
                             └─► ViewerComponent
                                 └─ Shows file content
                                    when file is clicked
```

### Admin Panel Component Structure
```
┌──────────────────────────────────────┐
│         AdminComponent                │
└──────────────┬───────────────────────┘
               │
               ├─► Tab 1: ScannerComponent
               │   └─ Path input + Scan button
               │
               ├─► Tab 2: BackupComponent
               │   ├─ Export button
               │   └─ Import button
               │
               └─► Tab 3: UserManagementComponent
                   ├─ Users table
                   └─ For each user:
                      └─ Course checkboxes
                         (checked = subscribed)
```

---

## 5. Data Flow: From File Click to Viewer

```
1. User clicks file in sidebar
   │
   ▼
2. SidebarComponent emits fileSelected event
   │
   ▼
3. MainLayoutComponent receives event
   │
   ▼
4. Updates selectedFile property
   │
   ▼
5. Hides ContentTableComponent
   Shows ViewerComponent
   │
   ▼
6. ViewerComponent receives selectedFile input
   │
   ▼
7. Determines file type from extension
   │
   ├─► If video: Show video player
   ├─► If audio: Show audio player
   ├─► If PDF: Show PDF viewer
   ├─► If TXT: Fetch and show text
   ├─► If HTML: Show in iframe
   ├─► If EPUB: Show EPUB reader
   └─► If other: Show download button
   │
   ▼
8. Calls API: GET /api/files?path={filePath}
   │
   ▼
9. Backend streams file content
   │
   ▼
10. Viewer displays content
```

---

## 6. User Subscription Management Flow

```
Admin View:
───────────────────────────────────────────────────────

┌─────────────────────────────────────────────────────┐
│              User Management Tab                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Users List:                                         │
│  ┌────────────────────────────────────────────┐    │
│  │ ☑ John Doe (john@example.com) - Student    │    │
│  │   Subscribed Courses:                       │    │
│  │   ☑ Math 101                                │    │
│  │   ☑ Physics 201                             │    │
│  │   ☐ WebDev Basics                           │    │
│  │   ☐ Reference Docs                          │    │
│  │   [Save Changes]                            │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │ ☑ Jane Smith (jane@example.com) - Student  │    │
│  │   Subscribed Courses:                       │    │
│  │   ☐ Math 101                                │    │
│  │   ☑ Physics 201                             │    │
│  │   ☑ WebDev Basics                           │    │
│  │   ☐ Reference Docs                          │    │
│  │   [Save Changes]                            │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
│  [+ Add New User]                                   │
└─────────────────────────────────────────────────────┘

When admin checks/unchecks a course:
────────────────────────────────────
Check   → POST /api/subscriptions/subscribe
Uncheck → POST /api/subscriptions/unsubscribe
```

---

## 7. Responsive Layout with Resizable Panels

```
Desktop View (Default):
────────────────────────────────────────────────────────
┌──────────────────────────────────────────────────────┐
│  LMS          User: John (Admin)    [Admin] [Logout] │
├───────────────────┬──────────────────────────────────┤
│                   │                                  │
│    Categories     │      Content/Viewer              │
│    (25%)          │      (75%)                       │
│                   ║                                  │
│  ▼ Books          ║  ┌──────────────────────┐       │
│    ▸ Math         ║  │                      │       │
│    ▸ Physics      ║  │   Folder Table       │       │
│  ▸ Courses        ║  │   or                 │       │
│  ▸ Docs           ║  │   File Viewer        │       │
│                   ║  │                      │       │
│                   ║  └──────────────────────┘       │
│                   │                                  │
└───────────────────┴──────────────────────────────────┘
                    ▲
                    │
              Drag to resize
              (min: 15%, max: 50%)

After Dragging Left:
────────────────────────────────────────────────────────
┌──────────────────────────────────────────────────────┐
│  LMS          User: John (Admin)    [Admin] [Logout] │
├──────┬───────────────────────────────────────────────┤
│      │                                               │
│ Cat  │          Content/Viewer                       │
│(15%) │          (85%)                                │
│      ║                                               │
│ ▼ B  ║  ┌───────────────────────────────────┐       │
│  ▸ M ║  │                                   │       │
│  ▸ P ║  │      Wider Content Area           │       │
│ ▸ C  ║  │                                   │       │
│ ▸ D  ║  │                                   │       │
│      ║  └───────────────────────────────────┘       │
└──────┴───────────────────────────────────────────────┘
```

---

## 8. Scanner Processing Flow

```
Input: C:\LMS_Content\

Step 1: Detect Root Folders (Categories)
────────────────────────────────────────
C:\LMS_Content\
├── Books\          ─────► Create Category "Books"
├── Courses\        ─────► Create Category "Courses"  
└── Documents\      ─────► Create Category "Documents"

Step 2: For each Category, detect Courses
──────────────────────────────────────────
Books\
├── Math101\        ─────► Create Course "Math101" (CategoryId: Books)
└── Physics201\     ─────► Create Course "Physics201" (CategoryId: Books)

Courses\
└── WebDev\         ─────► Create Course "WebDev" (CategoryId: Courses)

Step 3: For each Course, scan contents recursively
───────────────────────────────────────────────────
Math101\
├── Chapter1\       ─────► CourseItem (folder, ParentId: NULL)
│   ├── video.mp4   ─────► CourseItem (video, ParentId: Chapter1)
│   └── notes.pdf   ─────► CourseItem (document, ParentId: Chapter1)
└── Chapter2\       ─────► CourseItem (folder, ParentId: NULL)
    └── quiz.pdf    ─────► CourseItem (document, ParentId: Chapter2)

Result in Database:
───────────────────
Categories Table:
  1 | Books     | C:\LMS_Content\Books
  2 | Courses   | C:\LMS_Content\Courses
  3 | Documents | C:\LMS_Content\Documents

Courses Table:
  1 | 1 | Math101    | C:\LMS_Content\Books\Math101
  2 | 1 | Physics201 | C:\LMS_Content\Books\Physics201
  3 | 2 | WebDev     | C:\LMS_Content\Courses\WebDev

CourseItems Table:
  1 | 1 | NULL | Chapter1  | folder
  2 | 1 | 1    | video.mp4 | video
  3 | 1 | 1    | notes.pdf | document
  4 | 1 | NULL | Chapter2  | folder
  5 | 1 | 4    | quiz.pdf  | document
```

---

## 9. State Management Flow

```
Application State:
──────────────────────────────────────────────

┌─────────────────────────────────────────────┐
│          AuthService (Singleton)            │
│  ─────────────────────────────────────────  │
│  currentUser$: BehaviorSubject<User>        │
│  isAdmin$: Observable<boolean>              │
│  ─────────────────────────────────────────  │
│  login(email, password)                     │
│  logout()                                   │
│  getCurrentUser()                           │
└─────────────────────────────────────────────┘
                     ▲
                     │ Subscribe
                     │
         ┌───────────┴────────────┐
         │                        │
    HeaderComponent      MainLayoutComponent
         │
         └─► Shows user name & role
         └─► Shows/hides Admin button


┌─────────────────────────────────────────────┐
│        CourseService (Singleton)            │
│  ─────────────────────────────────────────  │
│  categories$: BehaviorSubject<Category[]>   │
│  selectedCourse$: BehaviorSubject<Course>   │
│  ─────────────────────────────────────────  │
│  getCategories() → cache in categories$     │
│  getCoursesByCategory(id)                   │
│  selectCourse(course)                       │
└─────────────────────────────────────────────┘
                     ▲
                     │ Subscribe
                     │
              SidebarComponent
                     │
                     └─► Displays category tree
                     └─► Emits course selection


┌─────────────────────────────────────────────┐
│     SubscriptionService (Singleton)         │
│  ─────────────────────────────────────────  │
│  userSubscriptions$: BehaviorSubject<[]>    │
│  ─────────────────────────────────────────  │
│  getUserSubscriptions(userId)               │
│  subscribe(userId, courseId)                │
│  unsubscribe(userId, courseId)              │
└─────────────────────────────────────────────┘
                     ▲
                     │ Subscribe
                     │
         UserManagementComponent
                     │
                     └─► Manages checkboxes
```

---

## 10. Security & Permission Flow

```
Every API Request:
──────────────────────────────────────────────

┌────────┐              Request              ┌──────────┐
│ Client │  ──────────────────────────────► │   API    │
└────────┘   Headers: { Authorization: ... } └────┬─────┘
                                                  │
                                                  ▼
                                          ┌───────────────┐
                                          │ JWT Middleware│
                                          │ (future)      │
                                          └──────┬────────┘
                                                 │
                                                 ▼ Token valid?
                                          ┌───────────────┐
                                          │  Controller   │
                                          └──────┬────────┘
                                                 │
                                                 ▼ Check role
                                          ┌───────────────┐
                                          │ Authorization │
                                          │ Check         │
                                          └──────┬────────┘
                                                 │
                              ┌──────────────────┼──────────────────┐
                              │                  │                  │
                              ▼                  ▼                  ▼
                         If Admin          If Student        If not logged in
                         ────────          ───────────       ────────────────
                         Full access       Limited access    Return 401
                         All endpoints     Subscribed        Unauthorized
                                          courses only
```

---

These diagrams provide a complete visual understanding of the new LMS system architecture!
