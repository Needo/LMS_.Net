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
