using Microsoft.AspNetCore.Mvc;
using LMS.API.Services;
using LMS.API.Models;

namespace LMS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SubscriptionsController : ControllerBase
    {
        private readonly ISubscriptionService _subscriptionService;
        private readonly ILogger<SubscriptionsController> _logger;

        public SubscriptionsController(ISubscriptionService subscriptionService, ILogger<SubscriptionsController> logger)
        {
            _subscriptionService = subscriptionService;
            _logger = logger;
        }

        [HttpGet("user/{userId}")]
        public async Task<ActionResult<List<UserCourseSubscription>>> GetUserSubscriptions(int userId)
        {
            try
            {
                var subscriptions = await _subscriptionService.GetUserSubscriptionsAsync(userId);
                return Ok(subscriptions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user subscriptions");
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("user/{userId}/course-ids")]
        public async Task<ActionResult<List<int>>> GetUserSubscribedCourseIds(int userId)
        {
            try
            {
                var courseIds = await _subscriptionService.GetUserSubscribedCourseIdsAsync(userId);
                return Ok(courseIds);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting subscribed course IDs");
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("subscribe")]
        public async Task<ActionResult> Subscribe([FromBody] SubscriptionRequest request)
        {
            try
            {
                var result = await _subscriptionService.SubscribeUserToCourseAsync(request.UserId, request.CourseId);
                if (result)
                {
                    return Ok(new { message = "Subscribed successfully" });
                }
                return BadRequest(new { message = "Failed to subscribe" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error subscribing user to course");
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("unsubscribe")]
        public async Task<ActionResult> Unsubscribe([FromBody] SubscriptionRequest request)
        {
            try
            {
                var result = await _subscriptionService.UnsubscribeUserFromCourseAsync(request.UserId, request.CourseId);
                if (result)
                {
                    return Ok(new { message = "Unsubscribed successfully" });
                }
                return BadRequest(new { message = "Failed to unsubscribe" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error unsubscribing user from course");
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("check")]
        public async Task<ActionResult<bool>> CheckSubscription([FromQuery] int userId, [FromQuery] int courseId)
        {
            try
            {
                var isSubscribed = await _subscriptionService.IsUserSubscribedAsync(userId, courseId);
                return Ok(new { isSubscribed });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking subscription");
                return StatusCode(500, ex.Message);
            }
        }
    }

    public class SubscriptionRequest
    {
        public int UserId { get; set; }
        public int CourseId { get; set; }
    }
}
