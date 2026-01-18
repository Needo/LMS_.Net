using LMS.API.Data;
using LMS.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SearchController : ControllerBase
    {
        private readonly LMSDbContext _context;
        private readonly ILogger<SearchController> _logger;

        public SearchController(LMSDbContext context, ILogger<SearchController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<List<SearchResultDto>>> Search([FromQuery] string query, [FromQuery] int? userId)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(query))
                {
                    return Ok(new List<SearchResultDto>());
                }

                var searchTerm = query.ToLower();

                // Base query - search in files/folders
                var itemsQuery = _context.CourseItems
                    .Include(i => i.Course)
                    .ThenInclude(c => c.Category)
                    .Where(i => i.Name.ToLower().Contains(searchTerm))
                    .AsQueryable();

                // If userId is provided, filter by user's subscribed courses
                if (userId.HasValue)
                {
                    var subscribedCourseIds = await _context.UserCourseSubscriptions
                        .Where(s => s.UserId == userId.Value)
                        .Select(s => s.CourseId)
                        .ToListAsync();

                    itemsQuery = itemsQuery.Where(i => subscribedCourseIds.Contains(i.CourseId));
                }

                var results = await itemsQuery
                    .OrderBy(i => i.Name)
                    .Take(100) // Limit results
                    .Select(i => new SearchResultDto
                    {
                        Id = i.Id,
                        CourseId = i.CourseId,
                        CourseName = i.Course.Name,
                        CategoryName = i.Course.Category.Name,
                        Name = i.Name,
                        Path = i.Path,
                        Type = i.Type,
                        Extension = i.Extension,
                        Size = i.Size,
                        ParentId = i.ParentId
                    })
                    .ToListAsync();

                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching");
                return StatusCode(500, new { message = ex.Message });
            }
        }
    }

    public class SearchResultDto
    {
        public int Id { get; set; }
        public int CourseId { get; set; }
        public string CourseName { get; set; } = string.Empty;
        public string CategoryName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Extension { get; set; } = string.Empty;
        public long Size { get; set; }
        public int? ParentId { get; set; }
    }
}
