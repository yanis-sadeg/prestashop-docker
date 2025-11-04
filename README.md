# PrestaShop 8.1.7 - Docker Development Environment

Containerized PrestaShop 8.1.7 development environment with Docker, optimized for WSL2/Linux with full Xdebug and phpMyAdmin support. If you need another version, simply modify the src/ content.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Installation](#installation)
- [Service Access](#service-access)
- [Configuration](#configuration)
- [Email Configuration](#email-configuration)
- [Production Deployment](#production-deployment)
- [Known Issues and Solutions](#known-issues-and-solutions)
- [Useful Commands](#useful-commands)

## Prerequisites

### Required Software

- **Docker** (version 20.10 or higher) and **Docker Compose** (version 2.0 or higher)
  - WSL2: [Install Docker Engine on WSL2](https://docs.docker.com/engine/install/ubuntu/)
  - Or Docker Desktop with WSL2 backend: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Linux: [Install Docker Engine](https://docs.docker.com/engine/install/)
- **Git** (optional, for version control)
- Modern **web browser** (Chrome, Firefox, Edge)

### Minimum System Requirements

- **RAM**: 8 GB minimum (16 GB recommended)
- **Disk Space**: 10 GB minimum
- **Processor**: Virtualization support enabled in BIOS

### Docker Installation Verification

```bash
docker --version
docker compose version
```

## Architecture

### Docker Services

The project uses Docker Compose with 3 main services:

```
┌─────────────────────────────────────────────────────┐
│                   prestashop:8080                   │
│  - PrestaShop 9.1                                   │
│  - PHP 8.1 with Xdebug                              │
│  - Apache 2.4                                       │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ DB Connection
                  ▼
┌─────────────────────────────────────────────────────┐
│                   mariadb:3306                      │
│  - MariaDB 10.11                                    │
│  - Persistent database                              │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ DB Access
                  ▼
┌─────────────────────────────────────────────────────┐
│                 phpmyadmin:8181                     │
│  - MySQL management interface                       │
└─────────────────────────────────────────────────────┘
```

### Project Structure

```
prestashop/
├── docker/
│   ├── prestashop/
│   │   ├── Dockerfile           # Custom PrestaShop image
│   │   └── entrypoint.sh        # Automatic startup script
│   └── mariadb/
│       ├── Dockerfile           # MariaDB image
│       ├── my.cnf               # MySQL configuration
│       └── import.sql           # DB initialization script
├── src/                         # PrestaShop source code (mounted as volume)
├── docker-compose.yml           # Service orchestration
└── README.md                    # This file
```

## Installation

### 1. Clone or Prepare the Project

```bash
# Navigate to your project directory
cd ~/workspace/prestashop
# Or any other path where you want to setup the project
```

### 2. Verify File Structure

Ensure the following files exist:
- `docker-compose.yml`
- `docker/prestashop/Dockerfile`
- `docker/prestashop/entrypoint.sh`
- `docker/mariadb/Dockerfile`
- `src/` (containing PrestaShop sources)

### 3. Build Docker Images

```bash
docker compose build
```

This command will:
- Build the PrestaShop image with PHP 8.1, Apache and Xdebug
- Build the custom MariaDB image
- Download the phpMyAdmin image

**Estimated duration**: 3-5 minutes (first time)

### 4. Start Containers

```bash
docker compose up -d
```

The `-d` option launches containers in the background (detached mode).

### 5. Verify Service Status

```bash
docker compose ps
```

Wait until all services are **healthy**:

```
NAME          STATUS
prestashop    Up (healthy)
mariadb       Up (healthy)
phpmyadmin    Up
```

**Startup time**: 30-60 seconds

### 6. Access PrestaShop Installer

Open your browser and navigate to:

**http://localhost:8080/install**

Follow the PrestaShop installation steps:

#### Step 1: Language
- Select your language

#### Step 2: License
- Accept the terms

#### Step 3: System Compatibility
- Verify all tests are green
- Click "Next"

#### Step 4: Store Information
- Fill in your store information
- Create your administrator account

#### Step 5: Database Configuration
```
Database server: mariadb
Database name: prestashop
Username: root
Password: root
```

#### Step 6: Installation
- Wait during installation (2-3 minutes)

#### Step 7: Finalization
- **IMPORTANT**: Delete the installation folder:
```bash
docker exec prestashop rm -rf /var/www/html/install
```

## Service Access

| Service | URL | Credentials |
|---------|-----|--------------|
| **PrestaShop Front Office** | http://localhost:8080 | - |
| **PrestaShop Back Office** | http://localhost:8080/admin | Per your installation |
| **phpMyAdmin** | http://localhost:8181 | User: `root` / Pass: `root` |
| **Mailhog** (Dev only) | http://localhost:8025 | No authentication |
| **Traefik Dashboard** (Dev only) | http://localhost:8080 | No authentication |

### SSH Connection to PrestaShop Container

```bash
docker exec -it prestashop bash
```

### SSH Connection to MariaDB Container

```bash
docker exec -it mariadb bash
```

## Configuration

### PrestaShop Environment Variables

Modifiable in `docker-compose.yml`:

```yaml
environment:
  - TZ=Europe/Paris          # Timezone
  - PS_DEV_MODE=1            # Development mode (1=enabled, 0=disabled)
  - PS_INSTALL_AUTO=0        # Automatic installation
  - DB_SERVER=mariadb        # Database service name
  - DB_USER=root             # MySQL user
  - DB_PASSWD=root           # MySQL password
  - DB_NAME=prestashop       # Database name
```

### Xdebug Configuration

Xdebug is pre-configured in `docker/prestashop/Dockerfile`:

```ini
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=host.docker.internal
xdebug.client_port=9000
```

#### VS Code Configuration (launch.json)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9000,
      "pathMappings": {
        "/var/www/html": "${workspaceFolder}/src"
      }
    }
  ]
}
```

#### PhpStorm Configuration

1. Go to **Settings > PHP > Servers**
2. Create a new server:
   - **Name**: prestashop
   - **Host**: localhost
   - **Port**: 8080
   - **Debugger**: Xdebug
3. Configure path mapping:
   - **Local path**: `~/workspace/prestashop/src` (or your actual project path)
   - **Remote path**: `/var/www/html`

### Custom PHP Configuration

PHP settings are defined in the Dockerfile:

```ini
memory_limit=512M
upload_max_filesize=64M
post_max_size=64M
max_execution_time=600
max_input_vars=10000
display_errors=On
error_reporting=E_ALL
```

To modify these values, edit `docker/prestashop/Dockerfile` then rebuild the image:

```bash
docker compose build prestashop
docker compose up -d prestashop
```

## Known Issues and Solutions

### 1. MariaDB in "unhealthy" Status

**Problem**: MariaDB container doesn't start properly.

**Cause**: Recent MariaDB versions use `mariadb-admin` instead of `mysqladmin`.

**Solution**: Already fixed in `docker-compose.yml` (line 37):
```yaml
test: [ "CMD-SHELL", "mariadb-admin ping -h 127.0.0.1 -uroot -proot --silent || exit 1" ]
```

### 2. Error "Failed opening required classes\\Tools.php"

**Problem**: Error 500 with incorrect paths in logs.

**Cause**: PrestaShop cache may contain incorrect path separators or cached paths from different environments.

**Solution**: The `entrypoint.sh` script automatically cleans cache at startup.

**Manual action if needed**:
```bash
docker exec prestashop rm -rf /var/www/html/var/cache/*
docker compose restart prestashop
```

### 3. Permission Error "var/cache"

**Problem**: PrestaShop cannot write to certain folders.

**Cause**: Docker volumes may have incorrect permissions, especially when files are created outside the container.

**Solution**: The `entrypoint.sh` script automatically corrects permissions at startup:
```bash
chown -R www-data:www-data /var/www/html/var/
chown -R www-data:www-data /var/www/html/mails/
chown -R www-data:www-data /var/www/html/translations/
# ... etc
```

**Manual action if needed**:
```bash
docker exec prestashop sh -c "chown -R www-data:www-data /var/www/html/var/"
```

### 4. Port Already in Use

**Problem**: Error "port is already allocated".

**Solution**: Modify ports in `docker-compose.yml`:
```yaml
ports:
  - "8081:80"  # Instead of 8080:80
```

Then restart:
```bash
docker compose down
docker compose up -d
```

### 5. Slow or Crashing Containers

**Possible causes**:
- Insufficient Docker resources
- High I/O load on WSL2 filesystem

**Solutions**:
1. Increase Docker resources (if using Docker Desktop):
   - Settings > Resources
   - CPU: 4+ cores
   - Memory: 8+ GB

2. For WSL2 users, ensure your project is in the WSL2 filesystem (not /mnt/c/):
   - Use `~/workspace/prestashop` instead of `/mnt/c/Users/...`
   - This significantly improves performance

## Useful Commands

### Container Management

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a specific service
docker compose restart prestashop

# View logs in real-time
docker compose logs -f

# View logs of a specific service
docker compose logs -f prestashop

# View container status
docker compose ps

# Stop AND remove volumes (⚠️ deletes database)
docker compose down -v
```

### Image Rebuild

```bash
# Rebuild all images
docker compose build

# Rebuild a specific image
docker compose build prestashop

# Rebuild without cache
docker compose build --no-cache

# Rebuild and restart
docker compose up -d --build
```

### Database Management

```bash
# Backup database
docker exec mariadb mysqldump -uroot -proot prestashop > backup.sql

# Restore database
docker exec -i mariadb mysql -uroot -proot prestashop < backup.sql

# Access MySQL command line
docker exec -it mariadb mysql -uroot -proot prestashop
```

### PrestaShop Cache Management

```bash
# Clear PrestaShop cache
docker exec prestashop rm -rf /var/www/html/var/cache/*

# Fix permissions
docker exec prestashop chown -R www-data:www-data /var/www/html/var/

# Fix Windows paths in cache
docker exec prestashop sh -c "php /tmp/fix_paths.php"
```

### Debugging

```bash
# View running processes in container
docker exec prestashop ps aux

# Check PHP configuration
docker exec prestashop php -i | grep -i xdebug

# Test database connection
docker exec prestashop php -r "new PDO('mysql:host=mariadb;dbname=prestashop', 'root', 'root');"

# View Apache errors
docker exec prestashop tail -f /var/log/apache2/error.log
```

### Cleanup

```bash
# Remove stopped containers
docker compose rm -f

# Clean unused images
docker image prune -a

# Clean everything (images, containers, volumes)
docker system prune -a --volumes
```

## Maintenance

### PrestaShop Update

1. Backup your database:
```bash
docker exec mariadb mysqldump -uroot -proot prestashop > backup_$(date +%Y%m%d).sql
```

2. Backup your custom files

3. Update sources in `src/`

4. Rebuild containers:
```bash
docker compose build
docker compose up -d
```

### Docker Image Update

```bash
# Download latest versions
docker compose pull

# Rebuild with new base images
docker compose build --pull

# Restart with new images
docker compose up -d
```

## Support and Resources

### Official Documentation

- [PrestaShop Documentation](https://devdocs.prestashop-project.org/)
- [Docker Documentation](https://docs.docker.com/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)

### Important Logs

- **PrestaShop Logs**: `src/var/logs/`
- **Apache Logs**: In container `/var/log/apache2/`
- **Docker Logs**: `docker compose logs`

### Key Configuration Files

- `docker-compose.yml`: Service orchestration
- `docker/prestashop/Dockerfile`: PrestaShop image
- `docker/prestashop/entrypoint.sh`: Startup script
- `docker/mariadb/my.cnf`: MySQL configuration
- `src/.env`: PrestaShop configuration

## Email Configuration

### Development (Mailhog)

This project includes **Mailhog** for email testing in development. Mailhog captures all outgoing emails without actually sending them.

**Access Mailhog:**
- Web UI: http://localhost:8025
- SMTP Server: `mailhog:1025` (inside Docker)

**Start with Mailhog:**
```bash
# Include Mailhog in development
docker compose --profile dev up -d

# Or set profile in environment
COMPOSE_PROFILES=dev docker compose up -d
```

**Features:**
- 📧 Captures all emails from PrestaShop
- 🌐 View emails in web interface
- 🚫 No real emails sent (safe testing)
- 🔍 Inspect HTML, plain text, and headers

### Production (Real SMTP)

In production, use a real SMTP server:
- Gmail (with App Password)
- SendGrid
- AWS SES
- Mailgun
- Brevo (Sendinblue)

Configure in `.env`:
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_ENCRYPTION=tls
SMTP_AUTH=true
```

**Complete email configuration guide:** [EMAIL-SETUP.md](EMAIL-SETUP.md)

## Production Deployment

⚠️ **Security Warning**: This setup is configured for DEVELOPMENT. Do NOT use it as-is in production!

### Key Security Differences

**Development Mode:**
- Traefik dashboard accessible on port 8080 (INSECURE)
- Self-signed SSL certificates
- Xdebug enabled (performance impact)
- PHP errors displayed
- phpMyAdmin publicly accessible

**Production Mode:**
- ✅ Traefik dashboard DISABLED
- ✅ Let's Encrypt SSL certificates
- ✅ Forced HTTPS redirection
- ✅ Xdebug removed
- ✅ PHP errors hidden
- ✅ phpMyAdmin accessible locally only

### Production Setup

For a complete production deployment guide, see **[PRODUCTION.md](PRODUCTION.md)**

Quick start:

```bash
# 1. Copy production environment template
cp .env.prod.example .env

# 2. Edit with your domain and credentials
nano .env

# 3. Deploy with production configuration
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Production Files

- **[docker-compose.prod.yml](docker-compose.prod.yml)**: Production overrides
- **[docker/traefik/traefik.prod.yml](docker/traefik/traefik.prod.yml)**: Secure Traefik config (no dashboard)
- **[.env.prod.example](.env.prod.example)**: Production environment template
- **[PRODUCTION.md](PRODUCTION.md)**: Complete deployment guide

📚 **Read [PRODUCTION.md](PRODUCTION.md) before deploying to production!**

## License

This project uses PrestaShop which is licensed under [Open Software License v3.0](https://opensource.org/licenses/OSL-3.0).

## Author

Docker Configuration for PrestaShop 9.1 - 2025

---

**Note**: This README documents the specific configuration for a development environment on WSL2/Linux with Docker. For a production environment, security and performance adjustments are necessary.
