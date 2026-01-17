using LMS.API.Data;
using LMS.API.Models;
using LMS.API.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly LMSDbContext _context;
        private readonly IAuthService _authService;
        private readonly ILogger<UsersController> _logger;

        public UsersController(LMSDbContext context, IAuthService authService, ILogger<UsersController> logger)
        {
            _context = context;
            _authService = authService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<List<UserDto>>> GetAllUsers()
        {
            try
            {
                var users = await _context.Users
                    .Where(u => u.IsActive)
                    .Select(u => new UserDto
                    {
                        Id = u.Id,
                        Email = u.Email,
                        FirstName = u.FirstName,
                        LastName = u.LastName,
                        Sex = u.Sex,
                        Role = u.Role,
                        CreatedDate = u.CreatedDate,
                        LastLoginDate = u.LastLoginDate
                    })
                    .OrderBy(u => u.FirstName)
                    .ToListAsync();

                return Ok(users);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting users");
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetUser(int id)
        {
            try
            {
                var user = await _context.Users.FindAsync(id);
                
                if (user == null || !user.IsActive)
                {
                    return NotFound(new { message = "User not found" });
                }

                var userDto = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Sex = user.Sex,
                    Role = user.Role,
                    CreatedDate = user.CreatedDate,
                    LastLoginDate = user.LastLoginDate
                };

                return Ok(userDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user");
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserDto request)
        {
            try
            {
                // Check if email already exists
                if (await _authService.EmailExistsAsync(request.Email))
                {
                    return BadRequest(new { message = "Email already exists" });
                }

                var createRequest = new CreateUserRequest
                {
                    Email = request.Email,
                    Password = request.Password,
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    Sex = request.Sex,
                    Role = request.Role
                };

                var user = await _authService.CreateUserAsync(createRequest);

                var userDto = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Sex = user.Sex,
                    Role = user.Role,
                    CreatedDate = user.CreatedDate,
                    LastLoginDate = user.LastLoginDate
                };

                return CreatedAtAction(nameof(GetUser), new { id = user.Id }, userDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<UserDto>> UpdateUser(int id, [FromBody] UpdateUserDto request)
        {
            try
            {
                var updateRequest = new UpdateUserRequest
                {
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    Sex = request.Sex,
                    Role = request.Role,
                    NewPassword = request.NewPassword
                };

                var user = await _authService.UpdateUserAsync(id, updateRequest);
                
                if (user == null)
                {
                    return NotFound(new { message = "User not found" });
                }

                var userDto = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Sex = user.Sex,
                    Role = user.Role,
                    CreatedDate = user.CreatedDate,
                    LastLoginDate = user.LastLoginDate
                };

                return Ok(userDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user");
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            try
            {
                var result = await _authService.DeleteUserAsync(id);
                
                if (!result)
                {
                    return NotFound(new { message = "User not found" });
                }

                return Ok(new { message = "User deleted successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user");
                return StatusCode(500, new { message = ex.Message });
            }
        }

        [HttpGet("{userId}/subscriptions")]
        public async Task<ActionResult<List<CourseDto>>> GetUserSubscriptions(int userId)
        {
            try
            {
                var subscriptions = await _context.UserCourseSubscriptions
                    .Where(s => s.UserId == userId)
                    .Include(s => s.Course)
                    .ThenInclude(c => c.Category)
                    .Select(s => new CourseDto
                    {
                        Id = s.Course.Id,
                        CategoryId = s.Course.CategoryId,
                        CategoryName = s.Course.Category.Name,
                        Name = s.Course.Name,
                        Path = s.Course.Path,
                        CreatedDate = s.Course.CreatedDate,
                        SubscribedDate = s.SubscribedDate
                    })
                    .OrderBy(c => c.CategoryName)
                    .ThenBy(c => c.Name)
                    .ToListAsync();

                return Ok(subscriptions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user subscriptions");
                return StatusCode(500, new { message = ex.Message });
            }
        }
    }

    public class UserDto
    {
        public int Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Sex { get; set; } = string.Empty;
        public string Role { get; set; } = "Student";
        public DateTime CreatedDate { get; set; }
        public DateTime? LastLoginDate { get; set; }
    }

    public class CreateUserDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Sex { get; set; } = string.Empty;
        public string Role { get; set; } = "Student";
    }

    public class UpdateUserDto
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Sex { get; set; } = string.Empty;
        public string Role { get; set; } = "Student";
        public string? NewPassword { get; set; }
    }

    public class CourseDto
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
        public DateTime? SubscribedDate { get; set; }
    }
}
