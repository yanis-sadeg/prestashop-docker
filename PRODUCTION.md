# Production Deployment Guide

This guide explains how to transition from development environment to production securely.

## Security Differences: Dev vs Prod

| Feature | Development | Production |
|----------------|---------------|------------|
| Traefik Dashboard | ✅ Accessible (port 8080) | ❌ Disabled |
| Traefik API | ✅ Enabled (insecure) | ❌ Disabled |
| SSL Certificate | Self-signed | Let's Encrypt |
| HTTPS Redirect | ❌ No | ✅ Forced |
| Xdebug | ✅ Installed | ❌ Disabled |
| PHP Errors | Displayed | Hidden |
| OPcache | Validation active | Validation disabled |
| phpMyAdmin | Public (port 8081) | Local only |
| Traefik Logs | INFO | ERROR |

## Pre-Production Checklist

### 1. Environment Configuration

```bash
# Copy the .env.prod.example file to .env
cp .env.prod.example .env
```

Edit `.env` with your production values:

```bash
# IMPORTANT: Change these values!
DOMAIN=your-domain.com
LETSENCRYPT_EMAIL=contact@your-domain.com

# PHP Security
PHP_DISPLAY_ERRORS=Off
PHP_DISPLAY_STARTUP_ERRORS=Off
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0
INSTALL_XDEBUG=false
```

### 2. DNS Configuration

Make sure your domain points to your server:

```bash
# Check DNS resolution
dig your-domain.com +short
# or
nslookup your-domain.com
```

The result should display your server's public IP.

### 3. Database Security

**CRITICAL**: Change default passwords!

Edit in `docker-compose.yml`:

```yaml
mariadb:
  environment:
    - MYSQL_ROOT_PASSWORD=A_STRONG_PASSWORD_HERE
    - MYSQL_DATABASE=prestashop

prestashop:
  environment:
    - DB_PASSWD=THE_SAME_PASSWORD
```

## Production Deployment

### Method 1: Use docker-compose.prod.yml (Recommended)

```bash
# Stop the dev environment
docker compose down

# Start in production mode
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check the logs
docker compose logs -f traefik
```

### Method 2: Manually modify the configuration

If you prefer to edit `docker-compose.yml` directly:

1. **Remove port 8080 in the traefik section**:
```yaml
ports:
  - "80:80"
  - "443:443"
  # - "8080:8080"  # REMOVE THIS LINE
```

2. **Use traefik.prod.yml**:
```yaml
volumes:
  - ./docker/traefik/traefik.prod.yml:/traefik.yml:ro
```

3. **Restart**:
```bash
docker compose down
docker compose up -d
```

## Post-Deployment Verification

### 1. Verify that Traefik dashboard is NOT accessible

```bash
# This command should fail (Connection refused)
curl http://your-domain.com:8080
```

If you get "Connection refused" → Good!
If you see the dashboard → SECURITY ISSUE

### 2. Verify HTTPS redirect

```bash
# Test HTTP → HTTPS redirect
curl -I http://your-domain.com
# Should return: HTTP/1.1 301 Moved Permanently
# Location: https://your-domain.com/
```

### 3. Verify SSL certificate

```bash
# Check Let's Encrypt certificate
curl -I https://your-domain.com
# or
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### 4. Test PrestaShop access

Open your browser: `https://your-domain.com`

### 5. Check logs

```bash
# Traefik logs (should be minimal in prod)
docker logs traefik --tail 50

# PrestaShop logs
docker logs prestashop --tail 50
```

##  Post-Installation Security

### 1. Remove PrestaShop installation folder

```bash
# After completing PrestaShop installation
docker exec prestashop rm -rf /var/www/html/install
```

### 2. Rename admin folder

PrestaShop generates a random name for the admin folder (e.g., `admin123abc`). Make sure to note it!

### 3. Configure firewall

```bash
# Example with UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# DO NOT open port 8080!
```

### 4. Automatic backups

Configure regular backups:

```bash
# Backup script (to be adapted)
#!/bin/bash
BACKUP_DIR="/backups/prestashop"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker exec mariadb mysqldump -uroot -p'YOUR_PASSWORD' prestashop > "$BACKUP_DIR/db_$DATE.sql"

# Files backup
tar -czf "$BACKUP_DIR/files_$DATE.tar.gz" ./src
```

## Maintenance

### View Traefik logs (in production)

```bash
# Logs are stored in ./docker/traefik/logs/
tail -f docker/traefik/logs/access.log
tail -f docker/traefik/logs/traefik.log
```

### Certificate renewal

Let's Encrypt automatically renews certificates. Check:

```bash
# View acme.json file content
docker exec traefik cat /letsencrypt/acme.json | jq
```

### Access phpMyAdmin in production

In production, phpMyAdmin is only accessible locally. Use an SSH tunnel:

```bash
# From your local machine
ssh -L 8081:localhost:8081 user@your-server.com

# Then open in your browser
http://localhost:8081
```

## Rollback to Dev

If you need to return to development:

```bash
# Stop prod
docker compose down

# Copy dev config
cp .env.example .env

# Restart in dev
docker compose up -d
```

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [PrestaShop Security](https://devdocs.prestashop-project.org/8/basics/keeping-up-to-date/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

## Important Notes

1. **Test first with Let's Encrypt Staging** to avoid hitting rate limits
2. **Back up everything** before going to production
3. **Monitor your logs** for the first few days
4. **Update regularly** PrestaShop, PHP and Traefik
5. **NEVER commit** the `.env` file with your real passwords
