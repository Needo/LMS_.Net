namespace LMS.API.Models
{
    public class Category
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
        public List<Course> Courses { get; set; } = new();
    }

    public class Course
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
        public Category? Category { get; set; }
        public List<CourseItem> Items { get; set; } = new();
        public List<UserCourseSubscription> Subscriptions { get; set; } = new();
    }

    public class CourseItem
    {
        public int Id { get; set; }
        public int CourseId { get; set; }
        public int? ParentId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Extension { get; set; } = string.Empty;
        public long Size { get; set; }
        public Course? Course { get; set; }
        public CourseItem? Parent { get; set; }
        public List<CourseItem> Children { get; set; } = new();
    }

    public class UserCourseSubscription
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int CourseId { get; set; }
        public DateTime SubscribedDate { get; set; }
        public User? User { get; set; }
        public Course? Course { get; set; }
    }
}
