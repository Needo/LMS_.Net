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

            _logger.LogInformation("Starting optimized scan of: {RootPath}", rootPath);

            _foldersCount = 0;
            _filesCount = 0;

            // Clear existing data
            _context.CourseItems.RemoveRange(_context.CourseItems);
            _context.Courses.RemoveRange(_context.Courses);
            await _context.SaveChangesAsync();

            var directories = Directory.GetDirectories(rootPath);
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
                await _context.SaveChangesAsync(); // Save to get course ID

                _logger.LogInformation("Scanning course: {CourseName}", course.Name);
                coursesAdded++;

                // Scan directory with proper hierarchy
                await ScanDirectoryAsync(dirInfo, course.Id, null);
            }

            var result = new ScanResult
            {
                CoursesAdded = coursesAdded,
                FoldersAdded = _foldersCount,
                FilesAdded = _filesCount,
                Message = $"Scan completed! Added {coursesAdded} course(s), {_foldersCount} folder(s), and {_filesCount} file(s)."
            };

            _logger.LogInformation("Scan completed: {Result}", result.Message);
            return result;
        }

        private async Task ScanDirectoryAsync(DirectoryInfo directory, int courseId, int? parentId)
        {
            try
            {
                // Process folders first and get their IDs
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

                    // Save immediately to get the folder ID
                    _context.CourseItems.Add(folderItem);
                    await _context.SaveChangesAsync();
                    _foldersCount++;

                    // Recursively scan subdirectory with THIS folder as parent
                    await ScanDirectoryAsync(subDir, courseId, folderItem.Id);
                }

                // Process files in this directory
                foreach (var file in directory.GetFiles())
                {
                    var fileType = GetFileType(file.Extension);
                    var fileItem = new CourseItem
                    {
                        CourseId = courseId,
                        ParentId = parentId, // Files belong to current folder
                        Name = file.Name,
                        Path = file.FullName,
                        Type = fileType,
                        Extension = file.Extension,
                        Size = file.Length
                    };

                    _context.CourseItems.Add(fileItem);
                    _filesCount++;
                }

                // Save files in batch
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
            
            // Video files
            if (new[] { ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".webm", ".flv", ".m4v" }.Contains(ext))
                return "video";
            
            // Audio files
            if (new[] { ".mp3", ".wav", ".ogg", ".m4a", ".flac", ".aac" }.Contains(ext))
                return "audio";
            
            // Document files
            if (new[] { ".pdf", ".doc", ".docx", ".txt", ".ppt", ".pptx", ".xls", ".xlsx" }.Contains(ext))
                return "document";
            
            // eBook files
            if (new[] { ".epub", ".mobi", ".azw", ".azw3" }.Contains(ext))
                return "ebook";
            
            // Image files
            if (new[] { ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".webp" }.Contains(ext))
                return "image";
            
            // Code files
            if (new[] { ".js", ".ts", ".html", ".css", ".json", ".xml", ".py", ".java", ".cs", ".cpp", ".c", ".h" }.Contains(ext))
                return "code";
            
            // Archive files
            if (new[] { ".zip", ".rar", ".7z", ".tar", ".gz" }.Contains(ext))
                return "archive";
            
            return "file";
        }
    }
}
