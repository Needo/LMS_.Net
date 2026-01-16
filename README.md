# Learning Management System (LMS) v2.0

A modern, full-stack Learning Management System built with ASP.NET Core and Angular, featuring category-based course organization, user subscriptions, and multi-format content viewing.

---

## 🎯 Quick Start

### Prerequisites
- .NET 8+ SDK
- Node.js 18+ & npm
- SQL Server 2019+
- Visual Studio Code or Visual Studio 2022

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd LMSSystem
```

2. **Setup Backend**
```bash
cd LMS.API
dotnet restore
dotnet ef database update
dotnet run
```
Backend runs at: `http://localhost:5000`

3. **Setup Frontend**
```bash
cd LMSUI
npm install
ng serve
```
Frontend runs at: `http://localhost:4200`

4. **Apply Database Migration**
```powershell
cd C:\LMSSystem
.\apply-migration.ps1
```

---

## 📚 Features

### For Students
- Browse courses by category
- View subscribed courses
- Navigate course content with tree view
- View files in table or viewer mode
- Play videos and audio
- Read documents (PDF, TXT, HTML, EPUB)
- Download files
- Resizable interface panels

### For Administrators
- Scan file system to import courses
- Organize content into categories
- Manage users (create, edit, delete)
- Manage course subscriptions
- Backup and restore database
- View system analytics

---

## 🏗️ Architecture

### Backend (ASP.NET Core)
```
LMS.API/
├── Controllers/      # API endpoints
├── Services/         # Business logic
├── Models/           # Data entities
├── Data/             # EF Core context
└── Migrations/       # Database migrations
```

### Frontend (Angular)
```
LMSUI/src/app/
├── components/       # UI components
├── services/         # HTTP services
├── models/           # TypeScript interfaces
└── guards/           # Route guards
```

### Database (SQL Server)
- **Categories** - Course categories (Books, Courses, etc.)
- **Courses** - Individual courses
- **CourseItems** - Files and folders
- **Users** - User accounts
- **UserCourseSubscriptions** - User enrollments

---

## 🗂️ Folder Structure

### Content Organization
```
Root Directory (e.g., C:\LMS_Content)
├── Category1 (e.g., Books)
│   ├── Course1 (e.g., Math 101)
│   │   ├── Folder1 (e.g., Chapter 1)
│   │   │   ├── video.mp4
│   │   │   └── notes.pdf
│   │   └── Folder2
│   └── Course2
├── Category2
│   └── Course3
└── Category3
```

---

## 🔌 API Endpoints

### Authentication
```http
POST   /api/auth/login
GET    /api/auth/users
POST   /api/auth/users
PUT    /api/auth/users/{id}
DELETE /api/auth/users/{id}
```

### Categories & Courses
```http
GET    /api/courses/categories
GET    /api/courses/categories/{id}/courses
GET    /api/courses
GET    /api/courses/{id}
GET    /api/courses/{id}/items
GET    /api/courses/folders/{id}/contents
POST   /api/courses/scan
```

### Subscriptions
```http
GET    /api/subscriptions/user/{userId}
POST   /api/subscriptions/subscribe
POST   /api/subscriptions/unsubscribe
GET    /api/subscriptions/check
```

### Files
```http
GET    /api/files?path={filePath}
```

Full API documentation: `http://localhost:5000/swagger`

---

## 🎨 UI Components

### Main Layout
- **Header:** App name, user info, admin button, logout
- **Sidebar:** Category and course tree view (25% width)
- **Content Area:** Table view or file viewer (75% width)
- **Resizable Splitter:** Drag to adjust panel sizes

### Admin Panel (3 Tabs)
1. **Scanner:** Import courses from file system
2. **Backup:** Export/import database
3. **User Management:** Manage users and subscriptions

---

## 🔧 Configuration

### Backend Configuration

**appsettings.json**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=SERVER_NAME;Database=LMSDB;..."
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

### Frontend Configuration

**environment.ts**
```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:5000/api'
};
```

---

## 🧪 Testing

### Run Backend Tests
```bash
cd LMS.API.Tests
dotnet test
```

### Run Frontend Tests
```bash
cd LMSUI
ng test
```

### Run E2E Tests
```bash
cd LMSUI
ng e2e
```

---

## 📦 Supported File Types

### Videos
`.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.webm`, `.flv`, `.m4v`

### Audio
`.mp3`, `.wav`, `.ogg`, `.m4a`, `.flac`, `.aac`

### Documents
`.pdf`, `.doc`, `.docx`, `.txt`, `.html`, `.htm`, `.ppt`, `.pptx`, `.xls`, `.xlsx`

### eBooks
`.epub`, `.mobi`, `.azw`, `.azw3`

### Images
`.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.svg`, `.webp`

### Code
`.js`, `.ts`, `.html`, `.css`, `.json`, `.xml`, `.py`, `.java`, `.cs`

### Archives
`.zip`, `.rar`, `.7z`, `.tar`, `.gz`

---

## 🚀 Deployment

### Production Build

**Backend:**
```bash
cd LMS.API
dotnet publish -c Release -o ./publish
```

**Frontend:**
```bash
cd LMSUI
ng build --configuration production
```

### IIS Deployment
1. Create new website in IIS
2. Point to published backend folder
3. Copy Angular dist files to `wwwroot`
4. Configure connection string
5. Set up SSL certificate

### Docker Deployment (Optional)
```bash
docker-compose up -d
```

---

## 🔐 Security

### Current Implementation
- Password hashing
- Role-based access control (Admin, Student)
- CORS configuration
- Input validation

### Recommended for Production
- JWT token authentication
- Refresh tokens
- Password complexity requirements
- Rate limiting
- XSS protection
- CSRF protection
- SQL injection prevention (via EF Core)

---

## 📊 Database Migrations

### Create Migration
```bash
cd LMS.API
dotnet ef migrations add MigrationName
```

### Apply Migration
```bash
dotnet ef database update
```

### Rollback Migration
```bash
dotnet ef database update PreviousMigrationName
```

### Drop Database (Development Only)
```bash
dotnet ef database drop
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue:** Migration fails
```bash
# Solution: Drop and recreate database
dotnet ef database drop
dotnet ef database update
```

**Issue:** CORS error
```bash
# Solution: Verify CORS policy in Program.cs
# Check frontend is calling http://localhost:5000
```

**Issue:** File not found
```bash
# Solution: Check file path in database
# Verify file exists on disk
# Check permissions
```

**Issue:** Login fails
```bash
# Solution: Verify user exists in database
# Check password hash is correct
# Check Role column has value
```

---

## 📚 Documentation

Comprehensive documentation is available in the project:

- **PROJECT_SUMMARY.md** - Project overview and features
- **IMPLEMENTATION_GUIDE.md** - Step-by-step implementation
- **QUICK_REFERENCE.md** - API and command reference
- **ARCHITECTURE_DIAGRAMS.md** - Visual architecture diagrams
- **IMPLEMENTATION_CHECKLIST.md** - Implementation tracking
- **PROJECT_ANALYSIS.md** - Detailed code analysis

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Implement feature with tests
3. Run all tests
4. Submit pull request
5. Code review
6. Merge to `main`

### Code Standards
- Follow C# coding conventions
- Use TypeScript strict mode
- Write unit tests for new features
- Document public APIs
- Use meaningful commit messages

---

## 📝 License

Proprietary - All rights reserved

---

## 👥 Team

**Development Team:**
- Backend Developer
- Frontend Developer
- UI/UX Designer
- QA Engineer

---

## 📞 Support

For issues and questions:
- Check documentation files
- Review troubleshooting section
- Contact development team

---

## 🎯 Roadmap

### v2.0 (Current)
- ✅ Category-based organization
- ✅ User subscriptions
- ✅ Enhanced admin panel
- 🔄 Resizable panels
- 🔄 EPUB viewer

### v2.1 (Planned)
- 📋 Video progress tracking
- 📋 Course completion tracking
- 📋 Search functionality
- 📋 Favorites/bookmarks

### v3.0 (Future)
- 📋 Quiz system
- 📋 Discussion forums
- 📋 Certificates
- 📋 Mobile app

---

## 📜 Version History

### v2.0.0 (January 2026)
- Added category-based organization
- Implemented user-course subscriptions
- Enhanced admin panel with 3 tabs
- Improved file viewer
- Added role-based access control

### v1.0.0 (Previous)
- Basic course scanning
- Tree-view navigation
- Video/Audio/PDF viewer
- Basic authentication

---

## 🙏 Acknowledgments

Built with:
- ASP.NET Core
- Angular
- Angular Material
- Entity Framework Core
- SQL Server

---

**Last Updated:** January 2026  
**Version:** 2.0.0  
**Status:** Active Development 🚀
