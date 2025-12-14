# Part 1 - Fix API Controllers
# Run this first to add missing controllers

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Part 1: Fixing API Controllers ===" -ForegroundColor Green
Set-Location "$RootPath\LMS.API"

# Create Controllers folder if missing
New-Item -ItemType Directory -Force -Path "Controllers" | Out-Null

Write-Host "Creating CoursesController..." -ForegroundColor Yellow

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
Write-Host "CoursesController created!" -ForegroundColor Green

Write-Host "Creating FilesController..." -ForegroundColor Yellow

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
Write-Host "FilesController created!" -ForegroundColor Green

Write-Host ""
Write-Host "Building API..." -ForegroundColor Yellow
dotnet build --configuration Release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Part 1 Complete! ===" -ForegroundColor Green
    Write-Host "Controllers created and API built successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Run part2-install-ui.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Build completed with warnings" -ForegroundColor Yellow
    Write-Host "You can proceed to Part 2" -ForegroundColor Yellow
}