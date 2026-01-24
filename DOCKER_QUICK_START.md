# Docker Deployment - Quick Reference

## Files Created

1. **Dockerfile** - Multi-stage build for Angular + .NET Core
2. **docker-compose.yml** - Orchestrates SQL Server + LMS App
3. **init-db.sql** - Database schema and default users
4. **.dockerignore** - Excludes unnecessary files from build
5. **deploy.sh** - Automated deployment script for Ubuntu
6. **DOCKER_DEPLOYMENT.md** - Complete deployment guide

## Quick Start Commands

### On Ubuntu VM:

```bash
# 1. Copy LMSSystem directory to Ubuntu
scp -r C:\LMSSystem user@ubuntu-ip:/home/user/

# 2. Run deployment script
cd /home/user/LMSSystem
chmod +x deploy.sh
./deploy.sh

# 3. Access application
http://ubuntu-ip:5000
```

## Default Credentials
- Admin: admin@lms.com / password123
- Student: student@lms.com / password123

## Key Features

✅ **Single Command Deployment** - Just run `./deploy.sh`
✅ **All Dependencies Included** - SQL Server, .NET, Angular, Node.js
✅ **Automatic Database Setup** - Schema and users created automatically
✅ **Persistent Data** - Database and files survive container restarts
✅ **Production Ready** - Optimized builds, health checks, restart policies

## Architecture

```
┌─────────────────────────────────────┐
│         Docker Compose              │
├─────────────────┬───────────────────┤
│  SQL Server     │   LMS App         │
│  Container      │   Container       │
│                 │                   │
│  - Database     │   - .NET Backend  │
│  - Port 1433    │   - Angular SPA   │
│                 │   - Port 5000     │
└─────────────────┴───────────────────┘
         │                 │
         └────────┬────────┘
                  │
         Docker Network (lms-network)
```

## Volume Mounts

- `./Courses` → `/app/courses` (Course files)
- `mssql-data` → SQL Server database files
- `lms-data` → Application data

## Common Operations

```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop all
docker-compose down

# Update and rebuild
git pull
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Backup database
docker exec lms-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd -C -Q "BACKUP DATABASE LMSDatabase TO DISK = '/var/opt/mssql/backup/backup.bak'"
```

## Port Configuration

Default ports:
- 5000: LMS Application
- 1433: SQL Server

To change ports, edit `docker-compose.yml`:
```yaml
ports:
  - "8080:5000"  # Change 8080 to desired port
```

## Security Notes

**IMPORTANT**: Before production deployment:
1. Change SQL Server password in docker-compose.yml
2. Update default user passwords
3. Configure firewall (only allow port 5000)
4. Use HTTPS with reverse proxy (nginx)
5. Regular backups

## Troubleshooting

**Container won't start?**
```bash
docker-compose logs mssql
docker-compose logs lms-app
```

**Database connection fails?**
```bash
docker-compose restart mssql
sleep 30
docker-compose restart lms-app
```

**Out of space?**
```bash
docker system prune -a
```

## Next Steps After Deployment

1. Login as admin (admin@lms.com / password123)
2. Go to Admin Panel → Scanner
3. Scan your course directory: `/app/courses`
4. Create student users
5. Assign course subscriptions

---

For complete documentation, see **DOCKER_DEPLOYMENT.md**
