# Learning Management System (LMS) - Project Summary

## 📚 Project Overview

A comprehensive Learning Management System built with modern web technologies, designed to organize educational content into categories, courses, and hierarchical content structures. The system supports multiple file formats including videos, audio, documents (PDF, TXT, HTML, EPUB), and provides an intuitive interface for both administrators and students.

---

## 🎯 Key Features

### 1. **Category-Based Course Organization**
- **Root folders** → Categories (e.g., Books, Courses, Documents)
- **First-level subfolders** → Course Titles
- **Subsequent levels** → Course Content (folders, files)
- Hierarchical tree-view navigation
- Easy course discovery and browsing

### 2. **Admin Panel (3 Tabs)**

#### Tab 1: Course Scanner
- Scan file system directories to import courses
- Automatic category detection from root folders
- Real-time scanning progress with detailed statistics
- Shows: Categories added, Courses added, Folders added, Files added

#### Tab 2: Database Backup & Restore
- Backup database to file
- Restore from backup
- Database management utilities

#### Tab 3: User Management
- Create, view, edit, and delete users
- User roles: Admin, Student
- Course subscription management per user
- Subscribe/Unsubscribe users to specific courses
- Visual checkboxes for course enrollment

### 3. **Content Viewer Interface**

#### Top Navigation Bar
- **Top Left:** Application name "Learning Management System"
- **Center:** Logged-in user's full name and role (Admin/Student)
- **Top Right:** Admin panel button (for admins) | Logout button

#### Left Panel: Tree Navigation
- **Categories** → Expandable to show courses
- **Courses** → Expandable to show course content
- **Folder Click** → Displays table view of folder contents in main panel
- **File Click** → Opens file in right viewer panel

#### Right Panel: File Viewer
Supports multiple formats:
- **Video:** `.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.webm`, `.flv`, `.m4v`
- **Audio:** `.mp3`, `.wav`, `.ogg`, `.m4a`, `.flac`, `.aac`
- **Documents:** 
  - PDF viewer
  - Text file reader (`.txt`)
  - HTML renderer (`.html`, `.htm`)
  - EPUB reader (`.epub`)
- **Images:** `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.svg`, `.webp`
- **Download Option:** For unsupported file types

#### Resizable Split Panel
- Adjustable splitter between left tree-view and right viewer
- Both panels auto-adjust content to fit available space
- Drag splitter left/right for preferred layout

### 4. **User Authentication & Authorization**
- Email/password login
- Role-based access control (Admin, Student)
- Session management
- User profile with first name, last name, sex, email

### 5. **Course Subscription System**
- Users can subscribe/unsubscribe to courses
- Admin can manage user subscriptions
- Students see only subscribed courses (optional filter)
- Track enrollment dates

---

## 🛠️ Tech Stack

### Backend
- **Framework:** ASP.NET Core (latest)
- **Language:** C# 12
- **Database:** SQL Server
- **ORM:** Entity Framework Core
- **Architecture:** RESTful API
- **Design Pattern:** Repository + Service Layer
- **Logging:** ILogger (built-in)
- **API Documentation:** Swagger/OpenAPI

### Frontend
- **Framework:** Angular 18+ (Standalone Components)
- **Language:** TypeScript 5+
- **UI Library:** Angular Material
- **State Management:** Service-based (RxJS)
- **Styling:** SCSS + Material Theming
- **HTTP Client:** Angular HttpClient
- **Tree Component:** Angular CDK Tree
- **Responsive:** Mobile-friendly design

### Database Schema
**Tables:**
1. **Categories** - Root-level organization
2. **Courses** - Course titles linked to categories
3. **CourseItems** - Files and folders (hierarchical)
4. **Users** - User accounts with roles
5. **UserCourseSubscriptions** - User-Course enrollment mapping

---

## 📊 Database Structure

### Categories
```
Id (PK), Name, Path, CreatedDate
```

### Courses
```
Id (PK), CategoryId (FK), Name, Path, CreatedDate
```

### CourseItems
```
Id (PK), CourseId (FK), ParentId (FK), Name, Path, Type, Extension, Size
```

### Users
```
Id (PK), Email, PasswordHash, FirstName, LastName, Sex, Role, IsActive, CreatedDate, LastLoginDate
```

### UserCourseSubscriptions
```
Id (PK), UserId (FK), CourseId (FK), SubscribedDate
```

**Relationships:**
- Category → Courses (One-to-Many)
- Course → CourseItems (One-to-Many)
- CourseItem → CourseItem (Self-referencing Parent-Child)
- User → UserCourseSubscriptions (One-to-Many)
- Course → UserCourseSubscriptions (One-to-Many)

---

## 🚀 API Endpoints

### Authentication
```
POST   /api/auth/login
GET    /api/auth/users
GET    /api/auth/users/{id}
POST   /api/auth/users
PUT    /api/auth/users/{id}
DELETE /api/auth/users/{id}
```

### Categories & Courses
```
GET    /api/courses/categories
GET    /api/courses/categories/{categoryId}/courses
GET    /api/courses
GET    /api/courses/{id}
GET    /api/courses/{id}/items
GET    /api/courses/folders/{folderId}/contents
POST   /api/courses/scan
```

### Subscriptions
```
GET    /api/subscriptions/user/{userId}
GET    /api/subscriptions/user/{userId}/course-ids
POST   /api/subscriptions/subscribe
POST   /api/subscriptions/unsubscribe
GET    /api/subscriptions/check?userId={userId}&courseId={courseId}
```

### Files
```
GET    /api/files?path={filePath}
```

---

## 📁 File Structure

```
LMSSystem/
├── LMS.API/                        # Backend
│   ├── Controllers/
│   │   ├── AuthController.cs
│   │   ├── CoursesController.cs
│   │   ├── SubscriptionsController.cs
│   │   └── FilesController.cs
│   ├── Services/
│   │   ├── AuthService.cs
│   │   ├── CourseService.cs
│   │   └── SubscriptionService.cs
│   ├── Models/
│   │   ├── Course.cs               # Category, Course, CourseItem, UserCourseSubscription
│   │   └── User.cs                 # User, LoginRequest/Response, etc.
│   ├── Data/
│   │   └── LMSDbContext.cs
│   └── Program.cs
│
└── LMSUI/                          # Frontend
    └── src/app/
        ├── components/
        │   ├── login/              # Login page
        │   ├── admin/              # Admin panel (3 tabs)
        │   │   ├── scanner/
        │   │   ├── backup/
        │   │   └── user-management/
        │   ├── main-layout/        # Main application layout
        │   ├── header/             # Top navigation bar
        │   ├── sidebar/            # Category/Course tree-view
        │   ├── content-table/      # Folder contents table view
        │   └── viewer/             # File viewer panel
        ├── services/
        │   ├── auth.service.ts
        │   ├── course.service.ts
        │   └── subscription.service.ts
        └── models/
            ├── course.model.ts
            ├── user.model.ts
            └── subscription.model.ts
```

---

## 🔧 Development Setup

### Prerequisites
- .NET 8+ SDK
- Node.js 18+ & npm
- SQL Server 2019+
- Visual Studio Code or Visual Studio 2022

### Backend Setup
```bash
cd LMS.API
dotnet restore
dotnet ef migrations add InitialCreate
dotnet ef database update
dotnet run
```

Backend runs on: `http://localhost:5000`

### Frontend Setup
```bash
cd LMSUI
npm install
ng serve
```

Frontend runs on: `http://localhost:4200`

---

## 🎨 UI/UX Features

### Responsive Design
- Mobile-friendly interface
- Touch-optimized navigation
- Adaptive layouts for tablets and desktops

### Visual Feedback
- Loading spinners during data fetch
- Progress indicators for scanning
- Success/error notifications
- Skeleton loaders for better UX

### Accessibility
- Keyboard navigation support
- ARIA labels for screen readers
- High-contrast mode support
- Focus indicators

---

## 🔐 Security Features

### Current Implementation
- Password hashing (basic)
- Role-based access control
- CORS configuration
- Input validation

### Planned Enhancements
- JWT token authentication
- Refresh token support
- Password complexity requirements
- Session timeout
- XSS protection
- CSRF tokens

---

## 📈 Performance Optimizations

- Lazy loading for course trees
- Pagination for large datasets
- Database indexing on frequently queried columns
- Batch file operations during scanning
- Efficient tree-loading queries
- Client-side caching with RxJS

---

## 🧪 Testing Strategy

### Backend
- Unit tests for services
- Integration tests for API endpoints
- Database migration tests

### Frontend
- Component unit tests
- Service tests
- E2E tests with Cypress/Playwright

---

## 📦 Deployment

### Production Checklist
- [ ] Update connection strings
- [ ] Configure SSL/TLS
- [ ] Set up database backups
- [ ] Configure logging
- [ ] Build Angular in production mode
- [ ] Publish API with Release configuration
- [ ] Set up reverse proxy (IIS/Nginx)
- [ ] Configure CORS for production domain

---

## 🛣️ Roadmap

### Phase 1 (Current)
- ✅ Category-based course organization
- ✅ Multi-format file viewer
- ✅ User authentication
- ✅ Course subscriptions
- ✅ Admin panel with scanner

### Phase 2 (In Progress)
- 🔄 Database backup/restore functionality
- 🔄 Enhanced user management UI
- 🔄 EPUB viewer integration
- 🔄 Resizable split panels

### Phase 3 (Planned)
- 📋 Video progress tracking
- 📋 Quiz and assessment system
- 📋 Discussion forums
- 📋 Course completion certificates
- 📋 Advanced search and filtering

---

## 👥 User Roles

### Admin
- Full access to all courses
- Can manage users
- Can scan and import courses
- Can backup/restore database
- Can manage user subscriptions

### Student
- Access to subscribed courses only
- Can view course content
- Can play videos/audio
- Can download files
- Limited to content viewer interface

---

## 📞 Support & Documentation

### API Documentation
Access Swagger UI: `http://localhost:5000/swagger`

### Database Migrations
```bash
# Add new migration
dotnet ef migrations add MigrationName

# Update database
dotnet ef database update

# Rollback migration
dotnet ef database update PreviousMigrationName
```

---

## 🤝 Contributing

### Code Standards
- Follow C# and TypeScript best practices
- Use async/await for all async operations
- Proper error handling with try-catch
- Write unit tests for new features
- Document complex logic

---

## 📄 License

Proprietary - All rights reserved

---

## 📝 Version History

**v2.0.0** (Current)
- Added category-based organization
- Implemented user-course subscriptions
- Enhanced admin panel with 3 tabs
- Improved file viewer with EPUB support
- Resizable split-panel layout

**v1.0.0** (Previous)
- Basic course scanning
- Simple tree-view navigation
- Video/Audio/PDF viewer
- Basic authentication

---

**Last Updated:** January 2026  
**Maintained By:** Development Team
