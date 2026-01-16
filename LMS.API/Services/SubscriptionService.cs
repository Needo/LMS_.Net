using LMS.API.Data;
using LMS.API.Models;
using Microsoft.EntityFrameworkCore;

namespace LMS.API.Services
{
    public interface ISubscriptionService
    {
        Task<List<UserCourseSubscription>> GetUserSubscriptionsAsync(int userId);
        Task<List<int>> GetUserSubscribedCourseIdsAsync(int userId);
        Task<bool> SubscribeUserToCourseAsync(int userId, int courseId);
        Task<bool> UnsubscribeUserFromCourseAsync(int userId, int courseId);
        Task<bool> IsUserSubscribedAsync(int userId, int courseId);
    }

    public class SubscriptionService : ISubscriptionService
    {
        private readonly LMSDbContext _context;
        private readonly ILogger<SubscriptionService> _logger;

        public SubscriptionService(LMSDbContext context, ILogger<SubscriptionService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<UserCourseSubscription>> GetUserSubscriptionsAsync(int userId)
        {
            return await _context.UserCourseSubscriptions
                .Include(s => s.Course)
                    .ThenInclude(c => c!.Category)
                .Where(s => s.UserId == userId)
                .ToListAsync();
        }

        public async Task<List<int>> GetUserSubscribedCourseIdsAsync(int userId)
        {
            return await _context.UserCourseSubscriptions
                .Where(s => s.UserId == userId)
                .Select(s => s.CourseId)
                .ToListAsync();
        }

        public async Task<bool> SubscribeUserToCourseAsync(int userId, int courseId)
        {
            try
            {
                // Check if already subscribed
                var exists = await _context.UserCourseSubscriptions
                    .AnyAsync(s => s.UserId == userId && s.CourseId == courseId);

                if (exists)
                {
                    return true; // Already subscribed
                }

                var subscription = new UserCourseSubscription
                {
                    UserId = userId,
                    CourseId = courseId,
                    SubscribedDate = DateTime.Now
                };

                _context.UserCourseSubscriptions.Add(subscription);
                await _context.SaveChangesAsync();

                _logger.LogInformation("User {UserId} subscribed to course {CourseId}", userId, courseId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error subscribing user {UserId} to course {CourseId}", userId, courseId);
                return false;
            }
        }

        public async Task<bool> UnsubscribeUserFromCourseAsync(int userId, int courseId)
        {
            try
            {
                var subscription = await _context.UserCourseSubscriptions
                    .FirstOrDefaultAsync(s => s.UserId == userId && s.CourseId == courseId);

                if (subscription == null)
                {
                    return true; // Not subscribed anyway
                }

                _context.UserCourseSubscriptions.Remove(subscription);
                await _context.SaveChangesAsync();

                _logger.LogInformation("User {UserId} unsubscribed from course {CourseId}", userId, courseId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error unsubscribing user {UserId} from course {CourseId}", userId, courseId);
                return false;
            }
        }

        public async Task<bool> IsUserSubscribedAsync(int userId, int courseId)
        {
            return await _context.UserCourseSubscriptions
                .AnyAsync(s => s.UserId == userId && s.CourseId == courseId);
        }
    }
}
