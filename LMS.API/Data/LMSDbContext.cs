using Microsoft.EntityFrameworkCore;
using LMS.API.Models;

namespace LMS.API.Data
{
    public class LMSDbContext : DbContext
    {
        public LMSDbContext(DbContextOptions<LMSDbContext> options) : base(options) { }

        public DbSet<Category> Categories { get; set; }
        public DbSet<Course> Courses { get; set; }
        public DbSet<CourseItem> CourseItems { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<UserCourseSubscription> UserCourseSubscriptions { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Category -> Courses
            modelBuilder.Entity<Category>()
                .HasMany(c => c.Courses)
                .WithOne(c => c.Category)
                .HasForeignKey(c => c.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);

            // Course -> CourseItems
            modelBuilder.Entity<Course>()
                .HasMany(c => c.Items)
                .WithOne(i => i.Course)
                .HasForeignKey(i => i.CourseId)
                .OnDelete(DeleteBehavior.Cascade);

            // CourseItem self-referencing (Parent-Child)
            modelBuilder.Entity<CourseItem>()
                .HasOne(i => i.Parent)
                .WithMany(i => i.Children)
                .HasForeignKey(i => i.ParentId)
                .OnDelete(DeleteBehavior.Restrict);

            // UserCourseSubscription relationships
            modelBuilder.Entity<UserCourseSubscription>()
                .HasOne(s => s.User)
                .WithMany(u => u.Subscriptions)
                .HasForeignKey(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserCourseSubscription>()
                .HasOne(s => s.Course)
                .WithMany(c => c.Subscriptions)
                .HasForeignKey(s => s.CourseId)
                .OnDelete(DeleteBehavior.Cascade);

            // Unique constraint: one user can only subscribe to a course once
            modelBuilder.Entity<UserCourseSubscription>()
                .HasIndex(s => new { s.UserId, s.CourseId })
                .IsUnique();
        }
    }
}
