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
