# Fix JSON Serialization Cycle Error
# This fixes the circular reference issue in the API

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Fixing JSON Serialization Cycle Error ===" -ForegroundColor Green

Set-Location "$RootPath\LMS.API"

Write-Host "Updating Program.cs with JSON options..." -ForegroundColor Yellow

# Update Program.cs to handle reference cycles
$programCs = @"
using LMS.API.Data;
using LMS.API.Services;
using Microsoft.EntityFrameworkCore;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// Add JSON options to handle cycles
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<LMSDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<ICourseService, CourseService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
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

Write-Host "Updating CourseService to not include parent references..." -ForegroundColor Yellow

# Update CourseService to load data without circular references
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

        public async Task ScanCoursesAsync(string rootPath)
        {
            if (!Directory.Exists(rootPath))
            {
                throw new DirectoryNotFoundException($"Path not found: {rootPath}");
            }

            _logger.LogInformation("Starting scan of: {RootPath}", rootPath);

            _context.CourseItems.RemoveRange(_context.CourseItems);
            _context.Courses.RemoveRange(_context.Courses);
            await _context.SaveChangesAsync();

            var directories = Directory.GetDirectories(rootPath);
            _logger.LogInformation("Found {Count} directories", directories.Length);

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

                await ScanDirectoryAsync(dirInfo, course.Id, null);
            }

            await _context.SaveChangesAsync();
            _logger.LogInformation("Scan completed successfully");
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

Write-Host ""
Write-Host "=== Fix Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Restart the API now:" -ForegroundColor Yellow
Write-Host "  cd LMS.API" -ForegroundColor White
Write-Host "  dotnet run --urls=http://localhost:5000" -ForegroundColor White
Write-Host ""
Write-Host "The JSON cycle error should be fixed!" -ForegroundColor Green
Write-Host ""