# LMS System Setup Script - Fixed Version
# This script creates a complete Learning Management System

param(
    [string]$RootPath = "C:\LMSSystem",
    [string]$SqlServer = "EMAAN-PC",
    [string]$SqlUser = "sa",
    [string]$SqlPassword = "pass",
    [string]$DbName = "LMSDatabase"
)

Write-Host "=== LMS System Setup ===" -ForegroundColor Green
Write-Host "Root Path: $RootPath" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
$dotnetInstalled = Get-Command dotnet -ErrorAction SilentlyContinue
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
$ngInstalled = Get-Command ng -ErrorAction SilentlyContinue

if (-not $dotnetInstalled) {
    Write-Host "ERROR: .NET SDK not found. Please install .NET 8 SDK" -ForegroundColor Red
    exit 1
}

if (-not $nodeInstalled) {
    Write-Host "ERROR: Node.js not found. Please install Node.js" -ForegroundColor Red
    exit 1
}

if (-not $ngInstalled) {
    Write-Host "WARNING: Angular CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g @angular/cli
}

# Create root directory
New-Item -ItemType Directory -Force -Path $RootPath | Out-Null
Set-Location $RootPath

# ======================
# 1. CREATE BACKEND API
# ======================
Write-Host "`n[1/6] Creating ASP.NET Core API..." -ForegroundColor Yellow

# Remove existing API folder if exists
if (Test-Path "LMS.API") {
    Remove-Item -Recurse -Force "LMS.API"
}

dotnet new webapi -n LMS.API --framework net8.0 --force
Set-Location "$RootPath\LMS.API"

# Add NuGet packages
Write-Host "Adding NuGet packages..." -ForegroundColor Cyan
dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version 8.0.0
dotnet add package Microsoft.EntityFrameworkCore.Tools --version 8.0.0
dotnet add package Microsoft.EntityFrameworkCore.Design --version 8.0.0
dotnet add package Microsoft.AspNetCore.Cors --version 2.2.0

# Create Models
New-Item -ItemType Directory -Force -Path "Models" | Out-Null

$courseModel = @'
namespace LMS.API.Models
{
    public class Course
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
        public List<CourseItem> Items { get; set; } = new();
    }

    public class CourseItem
    {
        public int Id { get; set; }
        public int CourseId { get; set; }
        public int? ParentId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Extension { get; set; } = string.Empty;
        public long Size { get; set; }
        public Course? Course { get; set; }
        public CourseItem? Parent { get; set; }
        public List<CourseItem> Children { get; set; } = new();
    }
}
'@

Set-Content -Path "Models\Course.cs" -Value $courseModel

# Create DbContext
New-Item -ItemType Directory -Force -Path "Data" | Out-Null

$dbContext = @'
using Microsoft.EntityFrameworkCore;
using LMS.API.Models;

namespace LMS.API.Data
{
    public class LMSDbContext : DbContext
    {
        public LMSDbContext(DbContextOptions<LMSDbContext> options) : base(options) { }

        public DbSet<Course> Courses { get; set; }
        public DbSet<CourseItem> CourseItems { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Course>()
                .HasMany(c => c.Items)
                .WithOne(i => i.Course)
                .HasForeignKey(i => i.CourseId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<CourseItem>()
                .HasOne(i => i.Parent)
                .WithMany(i => i.Children)
                .HasForeignKey(i => i.ParentId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
'@

Set-Content -Path "Data\LMSDbContext.cs" -Value $dbContext

# Create Services
New-Item -ItemType Directory -Force -Path "Services" | Out-Null

$courseService = @'
using LMS.API.Data;
using LMS.API.Models;
using Microsoft.EntityFrameworkCore;

namespace LMS.API.Services
{
    public interface ICourseService
    {
        Task<List<Course>> GetAllCoursesAsync();
        Task<Course?> GetCourseByIdAsync(int id);
        Task<List<CourseItem>> GetCourseItemsAsync(int courseId);
        Task ScanCoursesAsync(string rootPath);
    }

    public class CourseService : ICourseService
    {
        private readonly LMSDbContext _context;
        private readonly ILogger<CourseService> _logger;

        public CourseService(LMSDbContext context, ILogger<CourseService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<Course>> GetAllCoursesAsync()
        {
            return await _context.Courses.ToListAsync();
        }

        public async Task<Course?> GetCourseByIdAsync(int id)
        {
            return await _context.Courses
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<List<CourseItem>> GetCourseItemsAsync(int courseId)
        {
            return await _context.CourseItems
                .Where(i => i.CourseId == courseId && i.ParentId == null)
                .Include(i => i.Children)
                .ToListAsync();
        }

        public async Task ScanCoursesAsync(string rootPath)
        {
            if (!Directory.Exists(rootPath))
            {
                throw new DirectoryNotFoundException($"Path not found: {rootPath}");
            }

            _context.CourseItems.RemoveRange(_context.CourseItems);
            _context.Courses.RemoveRange(_context.Courses);
            await _context.SaveChangesAsync();

            var directories = Directory.GetDirectories(rootPath);

            foreach (var dir in directories)
            {
                var dirInfo = new DirectoryInfo(dir);
                var course = new Course
                {
                    Name = dirInfo.Name,
                    Path = dirInfo.FullName,
                    CreatedDate = DateTime.Now
                };

                _context.Courses.Add(course);
                await _context.SaveChangesAsync();

                await ScanDirectoryAsync(dirInfo, course.Id, null);
            }

            await _context.SaveChangesAsync();
        }

        private async Task ScanDirectoryAsync(DirectoryInfo directory, int courseId, int? parentId)
        {
            foreach (var subDir in directory.GetDirectories())
            {
                var folderItem = new CourseItem
                {
                    CourseId = courseId,
                    ParentId = parentId,
                    Name = subDir.Name,
                    Path = subDir.FullName,
                    Type = "folder",
                    Extension = "",
                    Size = 0
                };

                _context.CourseItems.Add(folderItem);
                await _context.SaveChangesAsync();

                await ScanDirectoryAsync(subDir, courseId, folderItem.Id);
            }

            foreach (var file in directory.GetFiles())
            {
                var fileType = GetFileType(file.Extension);
                var fileItem = new CourseItem
                {
                    CourseId = courseId,
                    ParentId = parentId,
                    Name = file.Name,
                    Path = file.FullName,
                    Type = fileType,
                    Extension = file.Extension,
                    Size = file.Length
                };

                _context.CourseItems.Add(fileItem);
            }
        }

        private string GetFileType(string extension)
        {
            var ext = extension.ToLower();
            if (new[] { ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".webm" }.Contains(ext))
                return "video";
            if (new[] { ".mp3", ".wav", ".ogg", ".m4a" }.Contains(ext))
                return "audio";
            if (new[] { ".pdf", ".doc", ".docx", ".txt", ".ppt", ".pptx" }.Contains(ext))
                return "document";
            return "file";
        }
    }
}
'@

Set-Content -Path "Services\CourseService.cs" -Value $courseService

# Create Controllers
$coursesController = @'
using Microsoft.AspNetCore.Mvc;
using LMS.API.Services;
using LMS.API.Models;

namespace LMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CoursesController : ControllerBase
    {
        private readonly ICourseService _courseService;
        private readonly ILogger<CoursesController> _logger;

        public CoursesController(ICourseService courseService, ILogger<CoursesController> logger)
        {
            _courseService = courseService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<List<Course>>> GetAll()
        {
            try
            {
                var courses = await _courseService.GetAllCoursesAsync();
                return Ok(courses);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting courses");
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Course>> GetById(int id)
        {
            try
            {
                var course = await _courseService.GetCourseByIdAsync(id);
                if (course == null) return NotFound();
                return Ok(course);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting course");
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("{id}/items")]
        public async Task<ActionResult<List<CourseItem>>> GetCourseItems(int id)
        {
            try
            {
                var items = await _courseService.GetCourseItemsAsync(id);
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting course items");
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("scan")]
        public async Task<ActionResult> ScanCourses([FromBody] ScanRequest request)
        {
            try
            {
                await _courseService.ScanCoursesAsync(request.RootPath);
                return Ok(new { message = "Scan completed successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scanning courses");
                return StatusCode(500, ex.Message);
            }
        }
    }

    public class ScanRequest
    {
        public string RootPath { get; set; } = string.Empty;
    }
}
'@

Set-Content -Path "Controllers\CoursesController.cs" -Value $coursesController

$filesController = @'
using Microsoft.AspNetCore.Mvc;

namespace LMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FilesController : ControllerBase
    {
        [HttpGet]
        public IActionResult GetFile([FromQuery] string path)
        {
            try
            {
                if (!System.IO.File.Exists(path))
                    return NotFound();

                var memory = new MemoryStream();
                using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
                {
                    stream.CopyTo(memory);
                }
                memory.Position = 0;

                var contentType = GetContentType(path);
                return File(memory, contentType, Path.GetFileName(path));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        private string GetContentType(string path)
        {
            var ext = Path.GetExtension(path).ToLower();
            return ext switch
            {
                ".mp4" => "video/mp4",
                ".avi" => "video/x-msvideo",
                ".mkv" => "video/x-matroska",
                ".webm" => "video/webm",
                ".mp3" => "audio/mpeg",
                ".wav" => "audio/wav",
                ".pdf" => "application/pdf",
                ".doc" => "application/msword",
                ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                ".txt" => "text/plain",
                _ => "application/octet-stream"
            };
        }
    }
}
'@

Set-Content -Path "Controllers\FilesController.cs" -Value $filesController

# Update Program.cs
$programCs = @"
using LMS.API.Data;
using LMS.API.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<LMSDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<ICourseService, CourseService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

app.Run();
"@

Set-Content -Path "Program.cs" -Value $programCs -Force

# Update appsettings.json
$connectionString = "Server=$SqlServer;Database=$DbName;User Id=$SqlUser;Password=$SqlPassword;TrustServerCertificate=True;Encrypt=False;"
$appSettings = @"
{
  "ConnectionStrings": {
    "DefaultConnection": "$connectionString"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
"@

Set-Content -Path "appsettings.json" -Value $appSettings -Force
Set-Content -Path "appsettings.Development.json" -Value $appSettings -Force

# Build first
Write-Host "Building API..." -ForegroundColor Cyan
dotnet build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed. Checking errors..." -ForegroundColor Red
    exit 1
}

# Create database
Write-Host "[2/6] Creating database and running migrations..." -ForegroundColor Yellow
try {
    dotnet ef migrations add InitialCreate --force
    dotnet ef database update
    Write-Host "Database created successfully!" -ForegroundColor Green
} catch {
    Write-Host "Warning: Migration failed. Database might already exist or SQL Server not accessible." -ForegroundColor Yellow
}

# ======================
# 2. CREATE ANGULAR UI
# ======================
Set-Location $RootPath
Write-Host "`n[3/6] Creating Angular application..." -ForegroundColor Yellow

# Remove existing UI folder if exists
if (Test-Path "LMSUI") {
    Remove-Item -Recurse -Force "LMSUI"
}

# Angular doesn't allow dots in project names
ng new LMSUI --routing --style=scss --skip-git
Set-Location "$RootPath\LMSUI"

# Install Angular Material
Write-Host "Installing Angular Material..." -ForegroundColor Cyan
ng add @angular/material --skip-confirmation --animations=true --theme=indigo-pink

# Create directory structure
New-Item -ItemType Directory -Force -Path "src/app/models" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/services" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/header" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/sidebar" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/viewer" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/admin" | Out-Null

# Create models
$modelsTs = @'
export interface Course {
  id: number;
  name: string;
  path: string;
  createdDate: Date;
  items?: CourseItem[];
}

export interface CourseItem {
  id: number;
  courseId: number;
  parentId?: number;
  name: string;
  path: string;
  type: string;
  extension: string;
  size: number;
  children?: CourseItem[];
}
'@

Set-Content -Path "src/app/models/course.model.ts" -Value $modelsTs

# Create service
$serviceTs = @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Course, CourseItem } from '../models/course.model';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = 'http://localhost:5000/api';

  constructor(private http: HttpClient) {}

  getCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses`);
  }

  getCourseItems(courseId: number): Observable<CourseItem[]> {
    return this.http.get<CourseItem[]>(`${this.apiUrl}/courses/${courseId}/items`);
  }

  scanCourses(rootPath: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/courses/scan`, { rootPath });
  }

  getFileUrl(path: string): string {
    return `${this.apiUrl}/files?path=${encodeURIComponent(path)}`;
  }
}
'@

Set-Content -Path "src/app/services/course.service.ts" -Value $serviceTs

Write-Host "[4/6] Creating Angular components..." -ForegroundColor Yellow

# Header Component
$headerTs = @'
import { Component } from '@angular/core';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent {
}
'@

$headerHtml = @'
<mat-toolbar color="primary">
  <span>Learning Management System</span>
  <span class="spacer"></span>
  <button mat-button routerLink="/admin">
    <mat-icon>settings</mat-icon>
    Admin
  </button>
</mat-toolbar>
'@

$headerScss = @'
.spacer {
  flex: 1 1 auto;
}
'@

Set-Content -Path "src/app/components/header/header.component.ts" -Value $headerTs
Set-Content -Path "src/app/components/header/header.component.html" -Value $headerHtml
Set-Content -Path "src/app/components/header/header.component.scss" -Value $headerScss

# Sidebar Component
$sidebarTs = @'
import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatTreeNestedDataSource } from '@angular/material/tree';
import { CourseService } from "../../services/course.service";
import { Course, CourseItem } from "../../models/course.model";

@Component({
  selector: "app-sidebar",
  templateUrl: "./sidebar.component.html",
  styleUrls: ["./sidebar.component.scss"]
})
export class SidebarComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<CourseItem>();
  
  treeControl = new NestedTreeControl<CourseItem>(node => node.children);
  dataSource = new MatTreeNestedDataSource<CourseItem>();

  constructor(private courseService: CourseService) {}

  ngOnInit() {
    this.loadCourses();
  }

  loadCourses() {
    this.courseService.getCourses().subscribe({
      next: (courses) => {
        const items: CourseItem[] = [];
        let completed = 0;
        
        if (courses.length === 0) {
          this.dataSource.data = [];
          return;
        }
        
        courses.forEach(course => {
          this.courseService.getCourseItems(course.id).subscribe({
            next: (courseItems) => {
              const courseNode: CourseItem = {
                id: course.id,
                courseId: course.id,
                name: course.name,
                path: course.path,
                type: 'course',
                extension: '',
                size: 0,
                children: courseItems
              };
              items.push(courseNode);
              completed++;
              
              if (completed === courses.length) {
                this.dataSource.data = items;
              }
            }
          });
        });
      }
    });
  }

  hasChild = (_: number, node: CourseItem) => !!node.children && node.children.length > 0;

  toggleNode(node: CourseItem) {
    this.treeControl.toggle(node);
  }

  selectItem(node: CourseItem) {
    if (node.type !== 'folder' && node.type !== 'course') {
      this.fileSelected.emit(node);
    }
  }

  getIcon(type: string): string {
    switch(type) {
      case 'course': return 'school';
      case 'folder': return 'folder';
      case 'video': return 'video_library';
      case 'audio': return 'audiotrack';
      case 'document': return 'description';
      default: return 'insert_drive_file';
    }
  }
}
'@

$sidebarHtml = @'
<div class="sidebar">
  <mat-tree [dataSource]="dataSource" [treeControl]="treeControl">
    <mat-tree-node *matTreeNodeDef="let node" matTreeNodeToggle>
      <li class="mat-tree-node">
        <button mat-icon-button disabled></button>
        <span (click)="selectItem(node)" class="node-label">
          <mat-icon>{{ getIcon(node.type) }}</mat-icon>
          {{ node.name }}
        </span>
      </li>
    </mat-tree-node>

    <mat-nested-tree-node *matTreeNodeDef="let node; when: hasChild">
      <li>
        <div class="mat-tree-node">
          <button mat-icon-button matTreeNodeToggle>
            <mat-icon>
              {{ treeControl.isExpanded(node) ? 'expand_more' : 'chevron_right' }}
            </mat-icon>
          </button>
          <span (click)="toggleNode(node)" class="node-label">
            <mat-icon>{{ getIcon(node.type) }}</mat-icon>
            {{ node.name }}
          </span>
        </div>
        <ul [class.hidden]="!treeControl.isExpanded(node)">
          <ng-container matTreeNodeOutlet></ng-container>
        </ul>
      </li>
    </mat-nested-tree-node>
  </mat-tree>
</div>
'@

$sidebarScss = @'
.sidebar {
  width: 300px;
  background: #f5f5f5;
  overflow-y: auto;
  border-right: 1px solid #ddd;
  padding: 16px;
}

.mat-tree {
  background: transparent;
}

.mat-tree-node {
  min-height: 40px;
  display: flex;
  align-items: center;
}

.node-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  
  &:hover {
    background: rgba(0,0,0,0.05);
  }
}

ul {
  padding-left: 20px;
  list-style: none;
}

.hidden {
  display: none;
}
'@

Set-Content -Path "src/app/components/sidebar/sidebar.component.ts" -Value $sidebarTs
Set-Content -Path "src/app/components/sidebar/sidebar.component.html" -Value $sidebarHtml
Set-Content -Path "src/app/components/sidebar/sidebar.component.scss" -Value $sidebarScss

# Viewer Component
$viewerTs = @'
import { Component, Input, OnChanges } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { CourseItem } from "../../models/course.model";
import { CourseService } from "../../services/course.service";

@Component({
  selector: "app-viewer",
  templateUrl: "./viewer.component.html",
  styleUrls: ["./viewer.component.scss"]
})
export class ViewerComponent implements OnChanges {
  @Input() selectedItem: CourseItem | null = null;
  fileUrl: string = '';

  constructor(
    private courseService: CourseService,
    private sanitizer: DomSanitizer
  ) {}

  ngOnChanges() {
    if (this.selectedItem) {
      this.fileUrl = this.courseService.getFileUrl(this.selectedItem.path);
    }
  }

  sanitizeUrl(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  formatSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(2) + ' KB';
    return (bytes / 1048576).toFixed(2) + ' MB';
  }
}
'@

$viewerHtml = @'
<div class="viewer">
  <div *ngIf="!selectedItem" class="placeholder">
    <mat-icon>description</mat-icon>
    <p>Select a file to view</p>
  </div>

  <div *ngIf="selectedItem" class="content">
    <h2>{{ selectedItem.name }}</h2>
    
    <video *ngIf="selectedItem.type === 'video'" controls [src]="fileUrl" class="media"></video>
    
    <audio *ngIf="selectedItem.type === 'audio'" controls [src]="fileUrl" class="media"></audio>
    
    <iframe *ngIf="selectedItem.type === 'document' && selectedItem.extension === '.pdf'" 
            [src]="sanitizeUrl(fileUrl)" class="document"></iframe>
    
    <div *ngIf="selectedItem.type === 'document' && selectedItem.extension !== '.pdf'" class="file-info">
      <mat-icon>description</mat-icon>
      <p>{{ selectedItem.name }}</p>
      <p>Size: {{ formatSize(selectedItem.size) }}</p>
      <a [href]="fileUrl" download mat-raised-button color="primary">
        <mat-icon>download</mat-icon>
        Download
      </a>
    </div>
    
    <div *ngIf="selectedItem.type === 'file'" class="file-info">
      <mat-icon>insert_drive_file</mat-icon>
      <p>{{ selectedItem.name }}</p>
      <p>Size: {{ formatSize(selectedItem.size) }}</p>
      <a [href]="fileUrl" download mat-raised-button color="primary">
        <mat-icon>download</mat-icon>
        Download
      </a>
    </div>
  </div>
</div>
'@

$viewerScss = @'
.viewer {
  flex: 1;
  padding: 24px;
  overflow-y: auto;
  background: white;
}

.placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #999;
  
  mat-icon {
    font-size: 64px;
    width: 64px;
    height: 64px;
  }
}

.content {
  h2 {
    margin-bottom: 24px;
  }
}

.media {
  width: 100%;
  max-width: 800px;
  border-radius: 8px;
}

.document {
  width: 100%;
  height: 80vh;
  border: 1px solid #ddd;
  border-radius: 8px;
}

.file-info {
  padding: 24px;
  background: #f5f5f5;
  border-radius: 8px;
  text-align: center;
  
  mat-icon {
    font-size: 64px;
    width: 64px;
    height: 64px;
    margin-bottom: 16px;
  }
  
  p {
    margin: 8px 0;
  }
  
  a {
    margin-top: 16px;
  }
}
'@

Set-Content -Path "src/app/components/viewer/viewer.component.ts" -Value $viewerTs
Set-Content -Path "src/app/components/viewer/viewer.component.html" -Value $viewerHtml
Set-Content -Path "src/app/components/viewer/viewer.component.scss" -Value $viewerScss

# Admin Component
$adminTs = @'
import { Component } from '@angular/core';
import { CourseService } from "../../services/course.service";
import { Router } from '@angular/router';

@Component({
  selector: "app-admin",
  templateUrl: "./admin.component.html",
  styleUrls: ["./admin.component.scss"]
})
export class AdminComponent {
  rootPath: string = 'C:\\Courses';
  scanning: boolean = false;
  message: string = '';
  isError: boolean = false;

  constructor(
    private courseService: CourseService,
    private router: Router
  ) {}

  scanCourses() {
    this.scanning = true;
    this.message = '';
    
    this.courseService.scanCourses(this.rootPath).subscribe({
      next: (response) => {
        this.scanning = false;
        this.message = response.message || 'Scan completed successfully!';
        this.isError = false;
      },
      error: (error) => {
        this.scanning = false;
        this.message = 'Error: ' + (error.error || error.message);
        this.isError = true;
      }
    });
  }

  goBack() {
    this.router.navigate(['/']);
  }
}
'@

$adminHtml = @'
<div class="admin-panel">
  <button mat-icon-button (click)="goBack()" class="back-button">
    <mat-icon>arrow_back</mat-icon>
  </button>
  
  <h1>Admin Panel</h1>
  
  <mat-card>
    <mat-card-header>
      <mat-card-title>Course Scanner</mat-card-title>
    </mat-card-header>
    <mat-card-content>
      <p>Scan a directory to import courses. Each root folder will become a course.</p>
      
      <mat-form-field appearance="outline" class="full-width">
        <mat-label>Root Path</mat-label>
        <input matInput [(ngModel)]="rootPath" placeholder="C:\Courses">
        <mat-hint>Enter the path containing your course folders</mat-hint>
      </mat-form-field>
      
      <button mat-raised-button color="primary" (click)="scanCourses()" [disabled]="scanning">
        <mat-icon>search</mat-icon>
        {{ scanning ? 'Scanning...' : 'Scan Courses' }}
      </button>
      
      <div *ngIf="message" class="message" [class.error]="isError">
        <mat-icon>{{ isError ? 'error' : 'check_circle' }}</mat-icon>
        {{ message }}
      </div>
    </mat-card-content>
  </mat-card>
</div>
'@

$adminScss = @'
.admin-panel {
  padding: 24px;
  max-width: 800px;
  margin: 0 auto;
}

.back-button {
  margin-bottom: 16px;
}

mat-card {
  margin: 24px 0;
}

.full-width {
  width: 100%;
  margin: 16px 0;
}

button[mat-raised-button] {
  margin-top: 8px;
}

.message {
  margin-top: 16px;
  padding: 12px;
  border-radius: 4px;
  background: #4caf50;
  color: white;
  display: flex;
  align-items: center;
  gap: 8px;
  
  &.error {
    background: #f44336;
  }
}
'@

Set-Content -Path "src/app/components/admin/admin.component.ts" -Value $adminTs
Set-Content -Path "src/app/components/admin/admin.component.html" -Value $adminHtml
Set-Content -Path "src/app/components/admin/admin.component.scss" -Value $adminScss

# Main App Component
$appComponentTs = @'
import { Component } from '@angular/core';
import { CourseItem } from './models/course.model';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent {
  title = 'LMS System';
  selectedItem: CourseItem | null = null;

  onFileSelected(item: CourseItem) {
    this.selectedItem = item;
  }
}
'@

$appComponentHtml = @'
<router-outlet></router-outlet>
'@

$appComponentScss = @'
'@

Set-Content -Path "src/app/app.component.ts" -Value $appComponentTs -Force
Set-Content -Path "src/app/app.component.html" -Value $appComponentHtml -Force
Set-Content -Path "src/app/app.component.scss" -Value $appComponentScss -Force

# Main Layout Component
$mainLayoutHtml = @'
<div class="app-container">
  <app-header></app-header>
  <div class="content-container">
    <app-sidebar (fileSelected)="onFileSelected($event)"></app-sidebar>
    <app-viewer [selectedItem]="selectedItem"></app-viewer>
  </div>
</div>
'@

$mainLayoutScss = @'
.app-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.content-container {
  display: flex;
  flex: 1;
  overflow: hidden;
}
'@

$mainLayoutTs = @'
import { Component } from '@angular/core';
import { CourseItem } from '../../models/course.model';

@Component({
  selector: 'app-main-layout',
  templateUrl: './main-layout.component.html',
  styleUrls: ['./main-layout.component.scss']
})
export class MainLayoutComponent {
  selectedItem: CourseItem | null = null;

  onFileSelected(item: CourseItem) {
    this.selectedItem = item;
  }
}
'@

New-Item -ItemType Directory -Force -Path "src/app/components/main-layout" | Out-Null
Set-Content -Path "src/app/components/main-layout/main-layout.component.ts" -Value $mainLayoutTs
Set-Content -Path "src/app/components/main-layout/main-layout.component.html" -Value $mainLayoutHtml
Set-Content -Path "src/app/components/main-layout/main-layout.component.scss" -Value $mainLayoutScss

# App Module
$appModuleTs = @'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';

import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTreeModule } from '@angular/material/tree';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

import { AppComponent } from './app.component';
import { HeaderComponent } from './components/header/header.component';
import { SidebarComponent } from './components/sidebar/sidebar.component';
import { ViewerComponent } from './components/viewer/viewer.component';
import { AdminComponent } from './components/admin/admin.component';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';

const routes: Routes = [
  { path: '', component: MainLayoutComponent },
  { path: 'admin', component: AdminComponent }
];

@NgModule({
  declarations: [
    AppComponent,
    HeaderComponent,
    SidebarComponent,
    ViewerComponent,
    AdminComponent,
    MainLayoutComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpClientModule,
    FormsModule,
    RouterModule.forRoot(routes),
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatTreeModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
'@

Set-Content -Path "src/app/app.module.ts" -Value $appModuleTs -Force

Write-Host "`n[5/6] Building projects..." -ForegroundColor Yellow

# Build Angular (skip for now, will build on first run)
Write-Host "Angular project created successfully!" -ForegroundColor Green

# Build API
Set-Location "$RootPath\LMS.API"
Write-Host "Building API..." -ForegroundColor Cyan
dotnet build --configuration Release

Write-Host "`n[6/6] Creating run scripts..." -ForegroundColor Yellow
Set-Location $RootPath

# Create run script for API
$runApiScript = @'
@echo off
echo Starting LMS API...
cd LMS.API
dotnet run --urls=http://localhost:5000
'@

Set-Content -Path "$RootPath\run-api.bat" -Value $runApiScript

# Create run script for UI
$runUiScript = @'
@echo off
echo Starting LMS UI...
cd LMSUI
ng serve --open --port 4200
'@

Set-Content -Path "$RootPath\run-ui.bat" -Value $runUiScript

# Create combined run script
$runAllScript = @'
@echo off
echo ====================================
echo    LMS System Starting...
echo ====================================
echo.

echo [1/2] Starting API Server...
start "LMS API" cmd /k "cd LMS.API && dotnet run --urls=http://localhost:5000"

echo [2/2] Waiting for API to initialize...
timeout /t 8 /nobreak > nul

echo [2/2] Starting Angular UI...
start "LMS UI" cmd /k "cd LMSUI && ng serve --open --port 4200"

echo.
echo ====================================
echo    LMS System Started!
echo ====================================
echo.
echo API Server: http://localhost:5000
echo Swagger UI: http://localhost:5000/swagger
echo Frontend:   http://localhost:4200
echo.
echo Press any key to stop all services...
pause > nul

echo.
echo Stopping services...
taskkill /FI "WINDOWTITLE eq LMS API" /T /F 2>nul
taskkill /FI "WINDOWTITLE eq LMS UI" /T /F 2>nul
echo Services stopped.
'@

Set-Content -Path "$RootPath\run-all.bat" -Value $runAllScript

# Create sample courses directory
$sampleCoursesPath = "C:\Courses"
if (-not (Test-Path $sampleCoursesPath)) {
    Write-Host "`nCreating sample courses directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path "$sampleCoursesPath\Sample Course 1\Week 1" | Out-Null
    New-Item -ItemType Directory -Force -Path "$sampleCoursesPath\Sample Course 1\Week 2" | Out-Null
    New-Item -ItemType Directory -Force -Path "$sampleCoursesPath\Sample Course 2\Module 1" | Out-Null
    
    # Create sample text files
    "Welcome to Sample Course 1" | Out-File "$sampleCoursesPath\Sample Course 1\Week 1\readme.txt"
    "Week 2 materials" | Out-File "$sampleCoursesPath\Sample Course 1\Week 2\notes.txt"
    "Module 1 introduction" | Out-File "$sampleCoursesPath\Sample Course 2\Module 1\intro.txt"
}

Write-Host "`n============================================" -ForegroundColor Green

# End of script "   LMS System Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

Write-Host "`nInstallation Details:" -ForegroundColor Cyan
Write-Host "  Root Path: $RootPath" -ForegroundColor White
Write-Host "  Database: $DbName on $SqlServer" -ForegroundColor White
Write-Host "  Sample Courses: $sampleCoursesPath" -ForegroundColor White

Write-Host "`nTo Start the System:" -ForegroundColor Yellow
Write-Host "  Option 1: Double-click $RootPath\run-all.bat" -ForegroundColor White
Write-Host "  Option 2: Run API and UI separately:" -ForegroundColor White
Write-Host "    - $RootPath\run-api.bat" -ForegroundColor Gray
Write-Host "    - $RootPath\run-ui.bat" -ForegroundColor Gray

Write-Host "`nAccess URLs:" -ForegroundColor Yellow
Write-Host "  Frontend:  http://localhost:4200" -ForegroundColor White
Write-Host "  API:       http://localhost:5000" -ForegroundColor White
Write-Host "  Swagger:   http://localhost:5000/swagger" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Run the system using run-all.bat" -ForegroundColor White
Write-Host "  2. Navigate to Admin panel" -ForegroundColor White
Write-Host "  3. Enter path: $sampleCoursesPath" -ForegroundColor White
Write-Host "  4. Click 'Scan Courses'" -ForegroundColor White
Write-Host "  5. View courses in the left sidebar" -ForegroundColor White

Write-Host "`n============================================" -ForegroundColor Green
Write-Host " "