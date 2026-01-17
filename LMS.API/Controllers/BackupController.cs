using LMS.API.Data;
using LMS.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IO.Compression;

namespace LMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BackupController : ControllerBase
    {
        private readonly LMSDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly ILogger<BackupController> _logger;

        public BackupController(LMSDbContext context, IConfiguration configuration, ILogger<BackupController> logger)
        {
            _context = context;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost("create")]
        public async Task<IActionResult> CreateBackup()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var backupFolder = Path.Combine(Directory.GetCurrentDirectory(), "Backups");
                
                if (!Directory.Exists(backupFolder))
                {
                    Directory.CreateDirectory(backupFolder);
                }

                var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                var backupFileName = $"LMSDB_Backup_{timestamp}.bak";
                var backupPath = Path.Combine(backupFolder, backupFileName);

                // Extract database name from connection string
                var dbName = "LMSDatabase";
                
                var backupCommand = $@"
                    BACKUP DATABASE [{dbName}] 
                    TO DISK = '{backupPath}' 
                    WITH FORMAT, INIT, NAME = 'Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10
                ";

                await _context.Database.ExecuteSqlRawAsync(backupCommand);

                var fileInfo = new FileInfo(backupPath);
                
                return Ok(new
                {
                    success = true,
                    message = "Backup created successfully",
                    fileName = backupFileName,
                    filePath = backupPath,
                    fileSize = fileInfo.Length,
                    timestamp = timestamp
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating database backup");
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        [HttpGet("list")]
        public IActionResult ListBackups()
        {
            try
            {
                var backupFolder = Path.Combine(Directory.GetCurrentDirectory(), "Backups");
                
                if (!Directory.Exists(backupFolder))
                {
                    return Ok(new List<object>());
                }

                var backupFiles = Directory.GetFiles(backupFolder, "*.bak")
                    .Select(f => new FileInfo(f))
                    .OrderByDescending(f => f.CreationTime)
                    .Select(f => new
                    {
                        fileName = f.Name,
                        filePath = f.FullName,
                        fileSize = f.Length,
                        createdDate = f.CreationTime,
                        formattedSize = FormatFileSize(f.Length)
                    })
                    .ToList();

                return Ok(backupFiles);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error listing backups");
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        [HttpPost("restore")]
        public async Task<IActionResult> RestoreBackup([FromBody] RestoreBackupRequest request)
        {
            try
            {
                var backupFolder = Path.Combine(Directory.GetCurrentDirectory(), "Backups");
                var backupPath = Path.Combine(backupFolder, request.FileName);

                if (!System.IO.File.Exists(backupPath))
                {
                    return NotFound(new { success = false, message = "Backup file not found" });
                }

                var dbName = "LMSDatabase";

                // Set database to single user mode, restore, then back to multi-user
                var restoreCommands = $@"
                    USE master;
                    ALTER DATABASE [{dbName}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                    
                    RESTORE DATABASE [{dbName}] 
                    FROM DISK = '{backupPath}' 
                    WITH REPLACE, RECOVERY;
                    
                    ALTER DATABASE [{dbName}] SET MULTI_USER;
                ";

                await _context.Database.ExecuteSqlRawAsync(restoreCommands);

                return Ok(new
                {
                    success = true,
                    message = "Database restored successfully",
                    fileName = request.FileName
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error restoring database");
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        [HttpDelete("delete/{fileName}")]
        public IActionResult DeleteBackup(string fileName)
        {
            try
            {
                var backupFolder = Path.Combine(Directory.GetCurrentDirectory(), "Backups");
                var backupPath = Path.Combine(backupFolder, fileName);

                if (!System.IO.File.Exists(backupPath))
                {
                    return NotFound(new { success = false, message = "Backup file not found" });
                }

                System.IO.File.Delete(backupPath);

                return Ok(new
                {
                    success = true,
                    message = "Backup deleted successfully",
                    fileName = fileName
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting backup");
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        private string FormatFileSize(long bytes)
        {
            string[] sizes = { "B", "KB", "MB", "GB", "TB" };
            double len = bytes;
            int order = 0;
            while (len >= 1024 && order < sizes.Length - 1)
            {
                order++;
                len = len / 1024;
            }
            return $"{len:0.##} {sizes[order]}";
        }
    }

    public class RestoreBackupRequest
    {
        public string FileName { get; set; } = string.Empty;
    }
}
