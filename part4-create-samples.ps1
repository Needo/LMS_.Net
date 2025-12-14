# Part 4 - Create Sample Courses
# Run this after Part 3

param(
    [string]$SamplePath = "C:\Courses"
)

Write-Host "=== Part 4: Creating Sample Courses ===" -ForegroundColor Green

if (Test-Path $SamplePath) {
    Write-Host "Sample courses already exist at: $SamplePath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=== Setup Complete! ===" -ForegroundColor Green
    Write-Host "Run: C:\LMSSystem\run-all.bat to start the system" -ForegroundColor Cyan
    exit
}

Write-Host "Creating course directories..." -ForegroundColor Yellow

# Create course structure
New-Item -ItemType Directory -Force -Path "$SamplePath\Web Development\Week 1 - HTML" | Out-Null
New-Item -ItemType Directory -Force -Path "$SamplePath\Web Development\Week 2 - CSS" | Out-Null
New-Item -ItemType Directory -Force -Path "$SamplePath\Web Development\Week 3 - JavaScript" | Out-Null
New-Item -ItemType Directory -Force -Path "$SamplePath\Python Programming\Module 1 - Basics" | Out-Null
New-Item -ItemType Directory -Force -Path "$SamplePath\Python Programming\Module 2 - Advanced" | Out-Null
New-Item -ItemType Directory -Force -Path "$SamplePath\Data Science\Introduction" | Out-Null
New-Item -ItemType Directory -Force -Path "$SamplePath\Data Science\Machine Learning" | Out-Null

Write-Host "Creating sample files..." -ForegroundColor Yellow

# Web Development README
$webDevReadme = "# Welcome to Web Development Course

This course will teach you:
1. HTML fundamentals
2. CSS styling
3. JavaScript programming
4. Building real-world projects

Start with Week 1 - HTML"

Set-Content -Path "$SamplePath\Web Development\README.txt" -Value $webDevReadme

# Individual lesson files
Set-Content -Path "$SamplePath\Web Development\Week 1 - HTML\lesson.txt" -Value "Week 1: Introduction to HTML - Learn about tags, elements, and document structure"
Set-Content -Path "$SamplePath\Web Development\Week 2 - CSS\lesson.txt" -Value "Week 2: CSS Fundamentals - Styling your HTML with CSS"
Set-Content -Path "$SamplePath\Web Development\Week 3 - JavaScript\lesson.txt" -Value "Week 3: JavaScript Basics - Adding interactivity to your websites"

# Python course files
$pythonReadme = "# Python Programming Course

Learn Python from basics to advanced concepts:
- Variables and Data Types
- Control Flow
- Functions and Modules
- Object-Oriented Programming
- Advanced Python Features"

Set-Content -Path "$SamplePath\Python Programming\README.txt" -Value $pythonReadme
Set-Content -Path "$SamplePath\Python Programming\Module 1 - Basics\intro.txt" -Value "Python Basics - Variables, Data Types, Control Flow"
Set-Content -Path "$SamplePath\Python Programming\Module 2 - Advanced\intro.txt" -Value "Advanced Python - OOP, Decorators, Generators"

# Data Science course files
$dsReadme = "# Data Science Course

Topics covered:
- Statistics and Probability
- Data Analysis with Pandas
- Machine Learning Algorithms
- Deep Learning Basics"

Set-Content -Path "$SamplePath\Data Science\README.txt" -Value $dsReadme
Set-Content -Path "$SamplePath\Data Science\Introduction\overview.txt" -Value "Introduction to Data Science - Statistics, Python libraries, and data visualization"
Set-Content -Path "$SamplePath\Data Science\Machine Learning\concepts.txt" -Value "Machine Learning - Supervised and unsupervised learning algorithms"

Write-Host ""
Write-Host "=== Part 4 Complete! ===" -ForegroundColor Green
Write-Host "Sample courses created at: $SamplePath" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All Setup Steps Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To Start the LMS System:" -ForegroundColor Yellow
Write-Host "  1. Run: C:\LMSSystem\run-all.bat" -ForegroundColor White
Write-Host "     (Starts both API and UI)" -ForegroundColor Gray
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Frontend:  http://localhost:4200" -ForegroundColor White
Write-Host "  API:       http://localhost:5000" -ForegroundColor White
Write-Host "  Swagger:   http://localhost:5000/swagger" -ForegroundColor White
Write-Host ""
Write-Host "Quick Start:" -ForegroundColor Yellow
Write-Host "  1. Click Admin button (top right)" -ForegroundColor White
Write-Host "  2. Enter path: $SamplePath" -ForegroundColor White
Write-Host "  3. Click 'Scan Courses'" -ForegroundColor White
Write-Host "  4. Explore courses in the sidebar!" -ForegroundColor White
Write-Host ""