namespace LMS.API.Models
{
    public class Course
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
        public List<CourseItem> Items { get; set; } = new();
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
}
