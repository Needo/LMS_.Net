# Improve Scan Feedback and Summary
# Adds detailed scan results and better UI feedback

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Improving Scan Feedback ===" -ForegroundColor Green

# Update API to return scan statistics
Write-Host "[1/2] Updating API to return scan statistics..." -ForegroundColor Yellow

Set-Location "$RootPath\LMS.API"

# Update CourseService to return scan results
$courseService = @'
using LMS.API.Data;
using LMS.API.Models;
using Microsoft.EntityFrameworkCore;

namespace LMS.API.Services
{
    public class ScanResult
    {
        public int CoursesAdded { get; set; }
        public int FoldersAdded { get; set; }
        public int FilesAdded { get; set; }
        public string Message { get; set; } = string.Empty;
    }

    public interface ICourseService
    {
        Task<List<Course>> GetAllCoursesAsync();
        Task<Course?> GetCourseByIdAsync(int id);
        Task<List<CourseItem>> GetCourseItemsAsync(int courseId);
        Task<ScanResult> ScanCoursesAsync(string rootPath);
    }

    public class CourseService : ICourseService
    {
        private readonly LMSDbContext _context;
        private readonly ILogger<CourseService> _logger;
        private int _foldersCount = 0;
        private int _filesCount = 0;

        public CourseService(LMSDbContext context, ILogger<CourseService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<Course>> GetAllCoursesAsync()
        {
            return await _context.Courses
                .Select(c => new Course
                {
                    Id = c.Id,
                    Name = c.Name,
                    Path = c.Path,
                    CreatedDate = c.CreatedDate
                })
                .ToListAsync();
        }

        public async Task<Course?> GetCourseByIdAsync(int id)
        {
            return await _context.Courses
                .Where(c => c.Id == id)
                .Select(c => new Course
                {
                    Id = c.Id,
                    Name = c.Name,
                    Path = c.Path,
                    CreatedDate = c.CreatedDate
                })
                .FirstOrDefaultAsync();
        }

        public async Task<List<CourseItem>> GetCourseItemsAsync(int courseId)
        {
            var items = await _context.CourseItems
                .Where(i => i.CourseId == courseId && i.ParentId == null)
                .ToListAsync();

            return await LoadChildrenRecursive(items);
        }

        private async Task<List<CourseItem>> LoadChildrenRecursive(List<CourseItem> items)
        {
            var result = new List<CourseItem>();

            foreach (var item in items)
            {
                var newItem = new CourseItem
                {
                    Id = item.Id,
                    CourseId = item.CourseId,
                    ParentId = item.ParentId,
                    Name = item.Name,
                    Path = item.Path,
                    Type = item.Type,
                    Extension = item.Extension,
                    Size = item.Size,
                    Children = new List<CourseItem>()
                };

                var children = await _context.CourseItems
                    .Where(i => i.ParentId == item.Id)
                    .ToListAsync();

                if (children.Any())
                {
                    newItem.Children = await LoadChildrenRecursive(children);
                }

                result.Add(newItem);
            }

            return result;
        }

        public async Task<ScanResult> ScanCoursesAsync(string rootPath)
        {
            if (!Directory.Exists(rootPath))
            {
                throw new DirectoryNotFoundException($"Path not found: {rootPath}");
            }

            _logger.LogInformation("Starting scan of: {RootPath}", rootPath);
            
            // Reset counters
            _foldersCount = 0;
            _filesCount = 0;

            // Clear existing data
            _context.CourseItems.RemoveRange(_context.CourseItems);
            _context.Courses.RemoveRange(_context.Courses);
            await _context.SaveChangesAsync();

            var directories = Directory.GetDirectories(rootPath);
            _logger.LogInformation("Found {Count} course directories", directories.Length);

            int coursesAdded = 0;

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

                _logger.LogInformation("Created course: {CourseName} (ID: {CourseId})", course.Name, course.Id);
                coursesAdded++;

                await ScanDirectoryAsync(dirInfo, course.Id, null);
            }

            await _context.SaveChangesAsync();
            
            var result = new ScanResult
            {
                CoursesAdded = coursesAdded,
                FoldersAdded = _foldersCount,
                FilesAdded = _filesCount,
                Message = $"Scan completed successfully! Added {coursesAdded} course(s), {_foldersCount} folder(s), and {_filesCount} file(s)."
            };

            _logger.LogInformation("Scan completed: {Result}", result.Message);
            
            return result;
        }

        private async Task ScanDirectoryAsync(DirectoryInfo directory, int courseId, int? parentId)
        {
            try
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
                    _foldersCount++;

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
                    _filesCount++;
                }

                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scanning directory: {Directory}", directory.FullName);
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

Set-Content -Path "Services\CourseService.cs" -Value $courseService -Force

# Update Controller to return the scan result
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
        public async Task<ActionResult<ScanResult>> ScanCourses([FromBody] ScanRequest request)
        {
            try
            {
                var result = await _courseService.ScanCoursesAsync(request.RootPath);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scanning courses");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    public class ScanRequest
    {
        public string RootPath { get; set; } = string.Empty;
    }
}
'@

Set-Content -Path "Controllers\CoursesController.cs" -Value $coursesController -Force

# Update Angular Admin Component
Write-Host "[2/2] Updating Angular Admin component..." -ForegroundColor Yellow

Set-Location "$RootPath\LMSUI\src\app\components\admin"

$adminTs = @'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { CourseService } from '../../services/course.service';

interface ScanResult {
  coursesAdded: number;
  foldersAdded: number;
  filesAdded: number;
  message: string;
}

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [
    CommonModule, 
    FormsModule, 
    MatCardModule, 
    MatFormFieldModule, 
    MatInputModule, 
    MatButtonModule, 
    MatIconModule,
    MatProgressBarModule
  ],
  template: `
    <div class="admin-panel">
      <button mat-icon-button (click)="goBack()">
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
            <input matInput [(ngModel)]="rootPath" placeholder="C:\\Courses" [disabled]="scanning">
            <mat-hint>Enter the path containing your course folders</mat-hint>
          </mat-form-field>
          
          @if (scanning) {
            <mat-progress-bar mode="indeterminate" color="primary"></mat-progress-bar>
            <p class="scanning-text">
              <mat-icon>sync</mat-icon>
              Scanning courses... Please wait
            </p>
          }
          
          <button mat-raised-button color="primary" (click)="scanCourses()" [disabled]="scanning">
            <mat-icon>{{ scanning ? 'hourglass_empty' : 'search' }}</mat-icon>
            {{ scanning ? 'Scanning...' : 'Scan Courses' }}
          </button>
          
          @if (scanResult) {
            <div class="result-summary success">
              <mat-icon>check_circle</mat-icon>
              <div class="result-details">
                <h3>Scan Completed Successfully!</h3>
                <div class="stats">
                  <div class="stat-item">
                    <mat-icon>school</mat-icon>
                    <span><strong>{{ scanResult.coursesAdded }}</strong> Course(s)</span>
                  </div>
                  <div class="stat-item">
                    <mat-icon>folder</mat-icon>
                    <span><strong>{{ scanResult.foldersAdded }}</strong> Folder(s)</span>
                  </div>
                  <div class="stat-item">
                    <mat-icon>insert_drive_file</mat-icon>
                    <span><strong>{{ scanResult.filesAdded }}</strong> File(s)</span>
                  </div>
                </div>
                <p class="message">{{ scanResult.message }}</p>
                <button mat-button color="primary" (click)="goBack()">
                  <mat-icon>visibility</mat-icon>
                  View Courses
                </button>
              </div>
            </div>
          }
          
          @if (error) {
            <div class="result-summary error">
              <mat-icon>error</mat-icon>
              <div class="result-details">
                <h3>Scan Failed</h3>
                <p class="message">{{ error }}</p>
                <button mat-button color="warn" (click)="clearError()">
                  <mat-icon>close</mat-icon>
                  Dismiss
                </button>
              </div>
            </div>
          }
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .admin-panel {
      padding: 24px;
      max-width: 800px;
      margin: 0 auto;
    }
    .full-width {
      width: 100%;
      margin: 16px 0;
    }
    button[mat-raised-button] {
      margin-top: 8px;
    }
    .scanning-text {
      display: flex;
      align-items: center;
      gap: 8px;
      color: #666;
      margin: 16px 0;
      font-style: italic;
    }
    .scanning-text mat-icon {
      animation: spin 2s linear infinite;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .result-summary {
      margin-top: 24px;
      padding: 20px;
      border-radius: 8px;
      display: flex;
      gap: 16px;
      align-items: flex-start;
    }
    .result-summary.success {
      background: #e8f5e9;
      border: 2px solid #4caf50;
    }
    .result-summary.error {
      background: #ffebee;
      border: 2px solid #f44336;
    }
    .result-summary > mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
    }
    .result-summary.success > mat-icon {
      color: #4caf50;
    }
    .result-summary.error > mat-icon {
      color: #f44336;
    }
    .result-details {
      flex: 1;
    }
    .result-details h3 {
      margin: 0 0 16px 0;
      color: #333;
    }
    .stats {
      display: flex;
      gap: 24px;
      margin: 16px 0;
      flex-wrap: wrap;
    }
    .stat-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      background: white;
      border-radius: 4px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .stat-item mat-icon {
      color: #1976d2;
    }
    .stat-item strong {
      color: #1976d2;
      font-size: 18px;
    }
    .message {
      color: #666;
      margin: 12px 0;
      line-height: 1.5;
    }
    mat-progress-bar {
      margin: 16px 0;
    }
  `]
})
export class AdminComponent {
  rootPath = 'C:\\Courses';
  scanning = false;
  scanResult: ScanResult | null = null;
  error = '';

  constructor(
    private courseService: CourseService,
    private router: Router
  ) {}

  scanCourses() {
    this.scanning = true;
    this.scanResult = null;
    this.error = '';
    
    this.courseService.scanCourses(this.rootPath).subscribe({
      next: (response: ScanResult) => {
        this.scanning = false;
        this.scanResult = response;
        console.log('Scan result:', response);
      },
      error: (err) => {
        this.scanning = false;
        this.error = err.message || 'Failed to scan courses. Please check the path and try again.';
        console.error('Scan error:', err);
      }
    });
  }

  clearError() {
    this.error = '';
  }

  goBack() {
    this.router.navigate(['/']);
  }
}
'@

Set-Content -Path "admin.component.ts" -Value $adminTs -Force

Write-Host ""
Write-Host "=== Improvement Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Restart both API and Angular:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. API:" -ForegroundColor White
Write-Host "   cd $RootPath\LMS.API" -ForegroundColor Gray
Write-Host "   dotnet run --urls=http://localhost:5000" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Angular:" -ForegroundColor White
Write-Host "   cd $RootPath\LMSUI" -ForegroundColor Gray
Write-Host "   ng serve" -ForegroundColor Gray
Write-Host ""
Write-Host "Now when you scan, you'll see:" -ForegroundColor Green
Write-Host "  - Progress indicator while scanning" -ForegroundColor White
Write-Host "  - Detailed summary with counts" -ForegroundColor White
Write-Host "  - Success/error messages" -ForegroundColor White
Write-Host "  - Quick link to view courses" -ForegroundColor White
Write-Host ""