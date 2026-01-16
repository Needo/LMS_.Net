using LMS.API.Data;
using LMS.API.Models;
using Microsoft.EntityFrameworkCore;

namespace LMS.API.Services
{
    public class ScanResult
    {
        public int CategoriesAdded { get; set; }
        public int CoursesAdded { get; set; }
        public int FoldersAdded { get; set; }
        public int FilesAdded { get; set; }
        public string Message { get; set; } = string.Empty;
    }

    public interface ICourseService
    {
        Task<List<Category>> GetAllCategoriesAsync();
        Task<List<Course>> GetAllCoursesAsync();
        Task<List<Course>> GetCoursesByCategoryAsync(int categoryId);
        Task<Course?> GetCourseByIdAsync(int id);
        Task<List<CourseItem>> GetCourseItemsAsync(int courseId);
        Task<List<CourseItem>> GetFolderContentsAsync(int folderId);
        Task<ScanResult> ScanCoursesAsync(string rootPath);
    }

    public class CourseService : ICourseService
    {
        private readonly LMSDbContext _context;
        private readonly ILogger<CourseService> _logger;
        private int _categoriesCount = 0;
        private int _foldersCount = 0;
        private int _filesCount = 0;

        public CourseService(LMSDbContext context, ILogger<CourseService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<Category>> GetAllCategoriesAsync()
        {
            return await _context.Categories
                .Include(c => c.Courses)
                .OrderBy(c => c.Name)
                .ToListAsync();
        }

        public async Task<List<Course>> GetAllCoursesAsync()
        {
            return await _context.Courses
                .Include(c => c.Category)
                .OrderBy(c => c.Name)
                .ToListAsync();
        }

        public async Task<List<Course>> GetCoursesByCategoryAsync(int categoryId)
        {
            return await _context.Courses
                .Where(c => c.CategoryId == categoryId)
                .OrderBy(c => c.Name)
                .ToListAsync();
        }

        public async Task<Course?> GetCourseByIdAsync(int id)
        {
            return await _context.Courses
                .Include(c => c.Category)
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<List<CourseItem>> GetCourseItemsAsync(int courseId)
        {
            // Get only top-level items (no parent) for the course
            var items = await _context.CourseItems
                .Where(i => i.CourseId == courseId && i.ParentId == null)
                .OrderBy(i => i.Type == "folder" ? 0 : 1)
                .ThenBy(i => i.Name)
                .ToListAsync();

            return items;
        }

        public async Task<List<CourseItem>> GetFolderContentsAsync(int folderId)
        {
            // Get direct children of a folder
            var items = await _context.CourseItems
                .Where(i => i.ParentId == folderId)
                .OrderBy(i => i.Type == "folder" ? 0 : 1)
                .ThenBy(i => i.Name)
                .ToListAsync();

            return items;
        }

        public async Task<ScanResult> ScanCoursesAsync(string rootPath)
        {
            if (!Directory.Exists(rootPath))
            {
                throw new DirectoryNotFoundException($"Path not found: {rootPath}");
            }

            _logger.LogInformation("Starting category-based scan of: {RootPath}", rootPath);

            _categoriesCount = 0;
            _foldersCount = 0;
            _filesCount = 0;

            // Clear existing data
            _context.CourseItems.RemoveRange(_context.CourseItems);
            _context.Courses.RemoveRange(_context.Courses);
            _context.Categories.RemoveRange(_context.Categories);
            await _context.SaveChangesAsync();

            // Root folders become Categories (e.g., Books, Courses, Documents)
            var categoryDirectories = Directory.GetDirectories(rootPath);
            int coursesAdded = 0;

            foreach (var categoryDir in categoryDirectories)
            {
                var categoryInfo = new DirectoryInfo(categoryDir);
                
                // Create Category
                var category = new Category
                {
                    Name = categoryInfo.Name,
                    Path = categoryInfo.FullName,
                    CreatedDate = DateTime.Now
                };

                _context.Categories.Add(category);
                await _context.SaveChangesAsync(); // Save to get category ID
                _categoriesCount++;

                _logger.LogInformation("Created category: {CategoryName}", category.Name);

                // First-level subfolders become Courses
                var courseDirectories = Directory.GetDirectories(categoryDir);

                foreach (var courseDir in courseDirectories)
                {
                    var courseInfo = new DirectoryInfo(courseDir);

                    // Create Course
                    var course = new Course
                    {
                        CategoryId = category.Id,
                        Name = courseInfo.Name,
                        Path = courseInfo.FullName,
                        CreatedDate = DateTime.Now
                    };

                    _context.Courses.Add(course);
                    await _context.SaveChangesAsync(); // Save to get course ID
                    coursesAdded++;

                    _logger.LogInformation("Created course: {CourseName} in category: {CategoryName}", 
                        course.Name, category.Name);

                    // Scan course contents (subfolders and files)
                    await ScanDirectoryAsync(courseInfo, course.Id, null);
                }
            }

            var result = new ScanResult
            {
                CategoriesAdded = _categoriesCount,
                CoursesAdded = coursesAdded,
                FoldersAdded = _foldersCount,
                FilesAdded = _filesCount,
                Message = $"Scan completed! Added {_categoriesCount} categor(ies), {coursesAdded} course(s), {_foldersCount} folder(s), and {_filesCount} file(s)."
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
            
            // eBook files (EPUB support added)
            if (new[] { ".epub", ".mobi", ".azw", ".azw3" }.Contains(ext))
                return "ebook";
            
            // HTML files
            if (ext == ".html" || ext == ".htm")
                return "html";
            
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
