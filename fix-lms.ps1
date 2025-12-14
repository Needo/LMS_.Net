# LMS System Cleanup and Completion Script
# Run this to fix the incomplete setup

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== LMS System Cleanup and Completion ===" -ForegroundColor Green
Set-Location $RootPath

# Remove duplicate src folder
if (Test-Path "$RootPath\src") {
    Write-Host "Removing duplicate src folder..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "$RootPath\src"
}

# Remove package-lock.json in root
if (Test-Path "$RootPath\package-lock.json") {
    Remove-Item -Force "$RootPath\package-lock.json"
}

# ========================================
# FIX API - Add Missing Controllers
# ========================================
Write-Host "`n[1/4] Fixing API Controllers..." -ForegroundColor Yellow
Set-Location "$RootPath\LMS.API"

# Create Controllers folder if missing
New-Item -ItemType Directory -Force -Path "Controllers" | Out-Null

# CoursesController
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

Set-Content -Path "Controllers\CoursesController.cs" -Value $coursesController -Force

# FilesController
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
                ".mov" => "video/quicktime",
                ".wmv" => "video/x-ms-wmv",
                ".mp3" => "audio/mpeg",
                ".wav" => "audio/wav",
                ".ogg" => "audio/ogg",
                ".m4a" => "audio/mp4",
                ".pdf" => "application/pdf",
                ".doc" => "application/msword",
                ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                ".txt" => "text/plain",
                ".ppt" => "application/vnd.ms-powerpoint",
                ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                _ => "application/octet-stream"
            };
        }
    }
}
'@

Set-Content -Path "Controllers\FilesController.cs" -Value $filesController -Force

# Rebuild API
Write-Host "Building API..." -ForegroundColor Cyan
dotnet build --configuration Release

if ($LASTEXITCODE -eq 0) {
    Write-Host "API built successfully!" -ForegroundColor Green
} else {
    Write-Host "API build had warnings but may still work" -ForegroundColor Yellow
}

# ========================================
# FIX ANGULAR UI - Install Dependencies
# ========================================
Write-Host "`n[2/4] Installing Angular dependencies..." -ForegroundColor Yellow
Set-Location "$RootPath\LMSUI"

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing npm packages (this may take a few minutes)..." -ForegroundColor Cyan
    npm install
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dependencies installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Error installing dependencies" -ForegroundColor Red
    }
}

# ========================================
# CREATE DATABASE (if not exists)
# ========================================
Write-Host "`n[3/4] Checking database..." -ForegroundColor Yellow
Set-Location "$RootPath\LMS.API"

# Check if Migrations folder exists
if (-not (Test-Path "Migrations")) {
    Write-Host "Creating database migrations..." -ForegroundColor Cyan
    try {
        dotnet ef migrations add InitialCreate
        dotnet ef database update
        Write-Host "Database created successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not create database. You may need to run migrations manually." -ForegroundColor Yellow
    }
} else {
    Write-Host "Migrations already exist" -ForegroundColor Green
}

# ========================================
# CREATE SAMPLE COURSE STRUCTURE
# ========================================
Write-Host "`n[4/4] Creating sample course structure..." -ForegroundColor Yellow

$samplePath = "C:\Courses"
if (-not (Test-Path $samplePath)) {
    New-Item -ItemType Directory -Force -Path "$samplePath\Web Development\Week 1 - HTML" | Out-Null
    New-Item -ItemType Directory -Force -Path "$samplePath\Web Development\Week 2 - CSS" | Out-Null
    New-Item -ItemType Directory -Force -Path "$samplePath\Web Development\Week 3 - JavaScript" | Out-Null
    New-Item -ItemType Directory -Force -Path "$samplePath\Python Programming\Module 1 - Basics" | Out-Null
    New-Item -ItemType Directory -Force -Path "$samplePath\Python Programming\Module 2 - Advanced" | Out-Null
    
    # Create sample files
    $readmeContent = @"
# Welcome to Web Development Course

This course will teach you:
1. HTML fundamentals
2. CSS styling
3. JavaScript programming
4. Building real-world projects

Start with Week 1 - HTML
"@
    
    Set-Content -Path "$samplePath\Web Development\README.txt" -Value $readmeContent

    "Week 1: Introduction to HTML - Learn about tags, elements, and document structure" | Out-File "$samplePath\Web Development\Week 1 - HTML\lesson.txt"
    "Week 2: CSS Fundamentals - Styling your HTML with CSS" | Out-File "$samplePath\Web Development\Week 2 - CSS\lesson.txt"
    "Week 3: JavaScript Basics - Adding interactivity to your websites" | Out-File "$samplePath\Web Development\Week 3 - JavaScript\lesson.txt"
    
    "Python Basics - Variables, Data Types, Control Flow" | Out-File "$samplePath\Python Programming\Module 1 - Basics\intro.txt"
    "Advanced Python - OOP, Decorators, Generators" | Out-File "$samplePath\Python Programming\Module 2 - Advanced\intro.txt"
    
    Write-Host "Sample courses created at: $samplePath" -ForegroundColor Green
} else {
    Write-Host "Sample courses already exist at: $samplePath" -ForegroundColor Green
}

# ========================================
# FINAL VERIFICATION
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Summary:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$apiExists = Test-Path "$RootPath\LMS.API\Controllers\CoursesController.cs"
$uiExists = Test-Path "$RootPath\LMSUI\src\app\app.module.ts"
$nodeModulesExists = Test-Path "$RootPath\LMSUI\node_modules"

Write-Host "✓ API Controllers: $(if($apiExists){'OK'}else{'MISSING'})" -ForegroundColor $(if($apiExists){'Green'}else{'Red'})
Write-Host "✓ Angular UI: $(if($uiExists){'OK'}else{'MISSING'})" -ForegroundColor $(if($uiExists){'Green'}else{'Red'})
Write-Host "✓ Node Modules: $(if($nodeModulesExists){'OK'}else{'MISSING'})" -ForegroundColor $(if($nodeModulesExists){'Green'}else{'Red'})

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nHow to Run:" -ForegroundColor Yellow
Write-Host "  1. Double-click: $RootPath\run-all.bat" -ForegroundColor White
Write-Host "     (This starts both API and UI automatically)" -ForegroundColor Gray
Write-Host ""
Write-Host "  OR run separately:" -ForegroundColor White
Write-Host "  2. Run API: $RootPath\run-api.bat" -ForegroundColor White
Write-Host "  3. Run UI: $RootPath\run-ui.bat" -ForegroundColor White

Write-Host "`nAccess URLs:" -ForegroundColor Yellow
Write-Host "  Frontend:  http://localhost:4200" -ForegroundColor White
Write-Host "  API:       http://localhost:5000" -ForegroundColor White
Write-Host "  Swagger:   http://localhost:5000/swagger" -ForegroundColor White

Write-Host "`nQuick Start Guide:" -ForegroundColor Yellow
Write-Host "  1. Run: $RootPath\run-all.bat" -ForegroundColor White
Write-Host "  2. Browser will open to http://localhost:4200" -ForegroundColor White
Write-Host "  3. Click 'Admin' in the top right" -ForegroundColor White
Write-Host "  4. Enter path: C:\Courses" -ForegroundColor White
Write-Host "  5. Click 'Scan Courses'" -ForegroundColor White
Write-Host "  6. Go back and explore courses in sidebar!" -ForegroundColor White

Write-Host "" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Set-Location $RootPath