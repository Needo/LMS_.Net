# Setup Authentication Backend

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Setting Up Authentication Backend ===" -ForegroundColor Green
Write-Host ""

Set-Location "$RootPath\LMS.API"

# Step 1: Create User Model
Write-Host "[1/6] Creating User model..." -ForegroundColor Yellow

$userModel = @'
using System.ComponentModel.DataAnnotations;

namespace LMS.API.Models
{
    public class User
    {
        public int Id { get; set; }
        
        [Required]
        [EmailAddress]
        [MaxLength(100)]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string PasswordHash { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(10)]
        public string Sex { get; set; } = "Male";
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedDate { get; set; } = DateTime.Now;
        
        public DateTime? LastLoginDate { get; set; }
    }
    
    public class LoginRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        public string Password { get; set; } = string.Empty;
    }
    
    public class LoginResponse
    {
        public int UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty;
    }
    
    public class CreateUserRequest
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        public string Sex { get; set; } = "Male";
    }
    
    public class UpdateUserRequest
    {
        [Required]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        public string Sex { get; set; } = "Male";
        
        public string? NewPassword { get; set; }
    }
}
'@

Set-Content -Path "Models\User.cs" -Value $userModel
Write-Host "  Created Models\User.cs" -ForegroundColor Green

# Step 2: Update DbContext
Write-Host ""
Write-Host "[2/6] Updating DbContext..." -ForegroundColor Yellow

$dbContext = Get-Content "Data\LMSDbContext.cs" -Raw

if (-not $dbContext.Contains("DbSet<User>")) {
    $dbContext = $dbContext -replace '(public DbSet<CourseItem> CourseItems \{ get; set; \})', "`$1`r`n        public DbSet<User> Users { get; set; }"
    Set-Content -Path "Data\LMSDbContext.cs" -Value $dbContext
    Write-Host "  Added Users DbSet to LMSDbContext" -ForegroundColor Green
} else {
    Write-Host "  Users DbSet already exists" -ForegroundColor Gray
}

# Step 3: Create Auth Service
Write-Host ""
Write-Host "[3/6] Creating Auth service..." -ForegroundColor Yellow

$authService = @'
using LMS.API.Data;
using LMS.API.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace LMS.API.Services
{
    public interface IAuthService
    {
        Task<LoginResponse?> LoginAsync(LoginRequest request);
        Task<User?> GetUserByIdAsync(int id);
        Task<List<User>> GetAllUsersAsync();
        Task<User> CreateUserAsync(CreateUserRequest request);
        Task<User?> UpdateUserAsync(int id, UpdateUserRequest request);
        Task<bool> DeleteUserAsync(int id);
        Task<bool> EmailExistsAsync(string email);
    }

    public class AuthService : IAuthService
    {
        private readonly LMSDbContext _context;
        private readonly ILogger<AuthService> _logger;

        public AuthService(LMSDbContext context, ILogger<AuthService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<LoginResponse?> LoginAsync(LoginRequest request)
        {
            var passwordHash = HashPassword(request.Password);
            
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email && u.PasswordHash == passwordHash && u.IsActive);

            if (user == null)
                return null;

            user.LastLoginDate = DateTime.Now;
            await _context.SaveChangesAsync();

            return new LoginResponse
            {
                UserId = user.Id,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Token = GenerateToken(user.Id)
            };
        }

        public async Task<User?> GetUserByIdAsync(int id)
        {
            return await _context.Users.FindAsync(id);
        }

        public async Task<List<User>> GetAllUsersAsync()
        {
            return await _context.Users
                .Where(u => u.IsActive)
                .OrderBy(u => u.FirstName)
                .ToListAsync();
        }

        public async Task<User> CreateUserAsync(CreateUserRequest request)
        {
            var user = new User
            {
                Email = request.Email,
                PasswordHash = HashPassword(request.Password),
                FirstName = request.FirstName,
                LastName = request.LastName,
                Sex = request.Sex,
                CreatedDate = DateTime.Now
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return user;
        }

        public async Task<User?> UpdateUserAsync(int id, UpdateUserRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return null;

            user.FirstName = request.FirstName;
            user.LastName = request.LastName;
            user.Sex = request.Sex;

            if (!string.IsNullOrEmpty(request.NewPassword))
            {
                user.PasswordHash = HashPassword(request.NewPassword);
            }

            await _context.SaveChangesAsync();
            return user;
        }

        public async Task<bool> DeleteUserAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return false;

            user.IsActive = false;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> EmailExistsAsync(string email)
        {
            return await _context.Users.AnyAsync(u => u.Email == email && u.IsActive);
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var bytes = Encoding.UTF8.GetBytes(password);
            var hash = sha256.ComputeHash(bytes);
            return Convert.ToBase64String(hash);
        }

        private string GenerateToken(int userId)
        {
            return Convert.ToBase64String(Encoding.UTF8.GetBytes($"{userId}:{DateTime.Now.Ticks}"));
        }
    }
}
'@

Set-Content -Path "Services\AuthService.cs" -Value $authService
Write-Host "  Created Services\AuthService.cs" -ForegroundColor Green

# Step 4: Create Auth Controller
Write-Host ""
Write-Host "[4/6] Creating Auth controller..." -ForegroundColor Yellow

$authController = @'
using Microsoft.AspNetCore.Mvc;
using LMS.API.Services;
using LMS.API.Models;

namespace LMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
        {
            try
            {
                var response = await _authService.LoginAsync(request);
                
                if (response == null)
                    return Unauthorized(new { message = "Invalid email or password" });

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login error");
                return StatusCode(500, new { message = "Login failed" });
            }
        }

        [HttpGet("users")]
        public async Task<ActionResult<List<User>>> GetAllUsers()
        {
            try
            {
                var users = await _authService.GetAllUsersAsync();
                users.ForEach(u => u.PasswordHash = string.Empty);
                return Ok(users);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting users");
                return StatusCode(500, new { message = "Failed to get users" });
            }
        }

        [HttpGet("users/{id}")]
        public async Task<ActionResult<User>> GetUser(int id)
        {
            try
            {
                var user = await _authService.GetUserByIdAsync(id);
                
                if (user == null)
                    return NotFound();

                user.PasswordHash = string.Empty;
                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user");
                return StatusCode(500, new { message = "Failed to get user" });
            }
        }

        [HttpPost("users")]
        public async Task<ActionResult<User>> CreateUser([FromBody] CreateUserRequest request)
        {
            try
            {
                if (await _authService.EmailExistsAsync(request.Email))
                    return BadRequest(new { message = "Email already exists" });

                var user = await _authService.CreateUserAsync(request);
                user.PasswordHash = string.Empty;

                return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                return StatusCode(500, new { message = "Failed to create user" });
            }
        }

        [HttpPut("users/{id}")]
        public async Task<ActionResult<User>> UpdateUser(int id, [FromBody] UpdateUserRequest request)
        {
            try
            {
                var user = await _authService.UpdateUserAsync(id, request);
                
                if (user == null)
                    return NotFound();

                user.PasswordHash = string.Empty;
                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user");
                return StatusCode(500, new { message = "Failed to update user" });
            }
        }

        [HttpDelete("users/{id}")]
        public async Task<ActionResult> DeleteUser(int id)
        {
            try
            {
                var result = await _authService.DeleteUserAsync(id);
                
                if (!result)
                    return NotFound();

                return Ok(new { message = "User deleted successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user");
                return StatusCode(500, new { message = "Failed to delete user" });
            }
        }
    }
}
'@

Set-Content -Path "Controllers\AuthController.cs" -Value $authController
Write-Host "  Created Controllers\AuthController.cs" -ForegroundColor Green

# Step 5: Update Program.cs
Write-Host ""
Write-Host "[5/6] Updating Program.cs..." -ForegroundColor Yellow

$program = Get-Content "Program.cs" -Raw

if (-not $program.Contains("IAuthService")) {
    $program = $program -replace '(builder.Services.AddScoped<ICourseService, CourseService>\(\);)', "`$1`r`nbuilder.Services.AddScoped<IAuthService, AuthService>();"
    Set-Content -Path "Program.cs" -Value $program
    Write-Host "  Added AuthService registration" -ForegroundColor Green
} else {
    Write-Host "  AuthService already registered" -ForegroundColor Gray
}

# Step 6: Create and run migration
Write-Host ""
Write-Host "[6/6] Creating database migration..." -ForegroundColor Yellow

try {
    dotnet ef migrations add AddUserAuthentication
    dotnet ef database update
    Write-Host "  Database updated successfully" -ForegroundColor Green
} catch {
    Write-Host "  Migration failed - you may need to run manually" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Backend Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run setup-auth-frontend.ps1 to create login UI" -ForegroundColor Cyan
Write-Host ""