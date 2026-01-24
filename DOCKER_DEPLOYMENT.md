# LMS Application - Docker Deployment Guide

## Overview
This guide will help you deploy the Learning Management System (LMS) application using Docker on Ubuntu.

## What's Included
- **SQL Server 2022** - Database server
- **ASP.NET Core Backend** - API server
- **Angular Frontend** - Built and served from backend
- **Everything in one package** - No external dependencies needed

## Prerequisites
- Ubuntu 20.04 or later
- Minimum 4GB RAM
- 10GB free disk space
- Internet connection (for initial setup)

## Quick Start (Automatic Installation)

### 1. Transfer Files to Ubuntu VM
Copy the entire `LMSSystem` directory to your Ubuntu VM:
```bash
# From your Windows machine, use SCP or SFTP
scp -r C:\LMSSystem user@ubuntu-vm-ip:/home/user/
```

### 2. Run the Deployment Script
```bash
cd /home/user/LMSSystem
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Install Docker and Docker Compose (if not already installed)
- Build the application images
- Start all services
- Initialize the database
- Create default users

### 3. Access the Application
Open your browser and navigate to:
```
http://ubuntu-vm-ip:5000
```

Default login credentials:
- **Admin**: admin@lms.com / password123
- **Student**: student@lms.com / password123

## Manual Installation Steps

If you prefer to deploy manually:

### 1. Install Docker
```bash
# Update package list
sudo apt-get update

# Install prerequisites
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and log back in for group changes to take effect
```

### 2. Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### 3. Build and Start Services
```bash
cd /home/user/LMSSystem

# Build images
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

## Configuration

### Change SQL Server Password
Edit `docker-compose.yml` and update the password in two places:
1. `mssql` service environment variable `SA_PASSWORD`
2. `lms-app` service connection string

```yaml
environment:
  - SA_PASSWORD=YourNewPassword123!
  - ConnectionStrings__DefaultConnection=Server=mssql;Database=LMSDatabase;User Id=sa;Password=YourNewPassword123!;TrustServerCertificate=True;
```

### Add Course Files
Place your course files in the `Courses` directory:
```bash
mkdir -p /home/user/LMSSystem/Courses
# Copy your course folders here
```

The directory structure should be:
```
Courses/
├── Category1/
│   ├── Course1/
│   │   ├── Lecture1.pdf
│   │   └── Lecture2.mp4
│   └── Course2/
└── Category2/
    └── Course3/
```

### Change Application Port
Edit `docker-compose.yml` to change the port:
```yaml
services:
  lms-app:
    ports:
      - "8080:5000"  # Change 8080 to your desired port
```

## Common Commands

### View Logs
```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs lms-app
docker-compose logs mssql
```

### Stop Services
```bash
docker-compose down
```

### Restart Services
```bash
docker-compose restart
```

### Rebuild Application
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Access Database
```bash
# Connect to SQL Server container
docker exec -it lms-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd -C

# Run SQL queries
SELECT * FROM Users;
GO
```

### Backup Database
```bash
# Create backup
docker exec lms-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd -C -Q "BACKUP DATABASE LMSDatabase TO DISK = '/var/opt/mssql/backup/LMSDatabase.bak'"

# Copy backup to host
docker cp lms-mssql:/var/opt/mssql/backup/LMSDatabase.bak ./backup.bak
```

### Update Application
```bash
# Pull latest changes (if using git)
git pull

# Rebuild and restart
docker-compose down
docker-compose build
docker-compose up -d
```

## Troubleshooting

### Containers won't start
```bash
# Check logs
docker-compose logs

# Check if ports are already in use
sudo netstat -tulpn | grep 5000
sudo netstat -tulpn | grep 1433
```

### Database connection errors
```bash
# Check SQL Server is healthy
docker-compose ps

# Restart database
docker-compose restart mssql

# Wait for database to be ready (30 seconds)
sleep 30
docker-compose restart lms-app
```

### Out of disk space
```bash
# Clean up unused Docker resources
docker system prune -a

# Remove old volumes
docker volume prune
```

### Permission denied errors
```bash
# Ensure your user is in docker group
sudo usermod -aG docker $USER

# Log out and log back in
```

## Security Recommendations

### Production Deployment
1. **Change default passwords**:
   - SQL Server SA password
   - Default user passwords

2. **Use HTTPS**:
   - Set up reverse proxy (nginx)
   - Configure SSL certificates

3. **Firewall configuration**:
```bash
# Allow only necessary ports
sudo ufw allow 5000/tcp
sudo ufw enable
```

4. **Environment variables**:
   - Store sensitive data in `.env` file
   - Never commit passwords to git

5. **Regular updates**:
   - Keep Docker images updated
   - Update base images regularly

## Performance Tuning

### Allocate more memory to SQL Server
Edit `docker-compose.yml`:
```yaml
services:
  mssql:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### Enable SQL Server logging
```yaml
services:
  mssql:
    environment:
      - MSSQL_ENABLE_TELEMETRY=0
      - MSSQL_COLLATION=SQL_Latin1_General_CP1_CI_AS
```

## File Structure
```
LMSSystem/
├── Dockerfile              # Application container definition
├── docker-compose.yml      # Multi-container orchestration
├── init-db.sql            # Database initialization script
├── .dockerignore          # Files to exclude from build
├── deploy.sh              # Automated deployment script
├── DOCKER_DEPLOYMENT.md   # This file
├── Courses/               # Course files directory
├── LMSBackend/            # ASP.NET Core backend
└── LMSUI/                 # Angular frontend
```

## Support

For issues or questions:
1. Check logs: `docker-compose logs -f`
2. Verify container status: `docker-compose ps`
3. Check database connectivity: Access http://localhost:5000/api/health

## Uninstallation

To completely remove the application:
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: This deletes all data)
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Optional: Clean up everything
docker system prune -a --volumes
```
