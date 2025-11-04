# Dynamic PHP Configuration - PrestaShop

This guide explains how to manage PHP configuration via environment variables to facilitate the transition from development to production.

## Architecture

PHP configuration is now **entirely dynamic** and is generated automatically at container startup:

1. Environment variables are defined in [.env](.env)
2. The [docker-compose.yml](docker-compose.yml) passes them to the container
3. The [entrypoint.sh](docker/prestashop/entrypoint.sh) script automatically generates `/usr/local/etc/php/conf.d/custom.ini`
4. PHP loads this configuration at startup

## Advantages

- **Flexibility**: Change PHP config without rebuilding the image
- **Multiple environments**: .env for dev, .env.prod for production
- **Traceability**: All config is visible in .env
- **Performance**: OPcache optimized with dedicated variables
- **Security**: Secure production configuration by default

## Available Variables

### Memory & Performance

| Variable | Dev | Prod | Description |
|----------|-----|------|-------------|
| `PHP_MEMORY_LIMIT` | 512M | 256M | Max memory per script |
| `PHP_MAX_EXECUTION_TIME` | 600 | 300 | Max execution time (seconds) |
| `PHP_MAX_INPUT_TIME` | 600 | 300 | Data parsing time |
| `PHP_MAX_INPUT_VARS` | 10000 | 10000 | Max number of variables (PrestaShop) |

### Upload & Post

| Variable | Dev | Prod | Description |
|----------|-----|------|-------------|
| `PHP_UPLOAD_MAX_FILESIZE` | 64M | 32M | Max uploaded file size |
| `PHP_POST_MAX_SIZE` | 64M | 32M | Max POST data size |

### Error Reporting

| Variable | Dev | Prod | Description |
|----------|-----|------|-------------|
| `PHP_DISPLAY_ERRORS` | On | **Off** | Display errors |
| `PHP_DISPLAY_STARTUP_ERRORS` | On | **Off** | Display startup errors |
| `PHP_ERROR_REPORTING` | E_ALL | E_ALL & ~E_DEPRECATED | Reporting level |

### OPcache (Performance)

| Variable | Dev | Prod | Description |
|----------|-----|------|-------------|
| `PHP_OPCACHE_ENABLE` | 1 | 1 | Enable OPcache |
| `PHP_OPCACHE_MEMORY` | 256 | 256 | OPcache memory (MB) |
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS` | 1 | **0** | Check for file modifications |
| `PHP_OPCACHE_REVALIDATE_FREQ` | 2 | 2 | Revalidation frequency (sec) |
| `PHP_OPCACHE_MAX_FILES` | 20000 | 20000 | Max number of cached files |

### Build Arguments

| Variable | Dev | Prod | Description |
|----------|-----|------|-------------|
| `INSTALL_XDEBUG` | true | **false** | Xdebug installation |

## Usage

### Development

1. Use the provided [.env](.env) file (dev configuration by default)
2. Start services:
   ```bash
   docker-compose up -d --build
   ```

3. Verify the applied PHP configuration in logs:
   ```bash
   docker logs prestashop
   ```

   You will see:
   ```
   === PrestaShop Container Initialization ===
   Generating PHP configuration from environment variables...
   PHP configuration generated successfully
     - memory_limit: 512M
     - upload_max_filesize: 64M
     - max_execution_time: 600
     - display_errors: On
   OPcache enabled with validate_timestamps=1
   ```

4. To modify a value, edit [.env](.env) then restart:
   ```bash
   docker-compose restart prestashop
   ```

### Production

#### Method 1: Copy the example file

```bash
cp .env.prod.example .env
nano .env  # Adjust values
docker-compose up -d --build
```

#### Method 2: Modify existing environment

Edit [.env](.env) and change critical values:

```bash
# Error Reporting - CRITICAL
PHP_DISPLAY_ERRORS=Off
PHP_DISPLAY_STARTUP_ERRORS=Off
PHP_ERROR_REPORTING=E_ALL & ~E_DEPRECATED & ~E_STRICT

# OPcache - Maximum performance
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0

# Build - Without Xdebug
INSTALL_XDEBUG=false
```

**IMPORTANT**: When changing `INSTALL_XDEBUG`, you MUST rebuild the image:
```bash
docker-compose up -d --build
```

## Configuration Verification

### View current PHP configuration

```bash
docker exec prestashop php -i | grep -E "memory_limit|upload_max_filesize|display_errors|opcache"
```

### View generated custom.ini file

```bash
docker exec prestashop cat /usr/local/etc/php/conf.d/custom.ini
```

### View OPcache configuration

```bash
docker exec prestashop cat /usr/local/etc/php/conf.d/opcache-dynamic.ini
```

### Create a phpinfo() page

Create the file `src/phpinfo.php`:
```php
<?php phpinfo(); ?>
```

Access http://localhost/phpinfo.php (remember to delete it afterwards!)

## Production Optimizations

### OPcache: The Key to Performance

OPcache is **CRITICAL** for production performance. It caches compiled PHP bytecode.

**Recommended configuration (already in .env.prod.example):**

```bash
PHP_OPCACHE_ENABLE=1
PHP_OPCACHE_MEMORY=256
PHP_OPCACHE_VALIDATE_TIMESTAMPS=0  # Important: disables file checking
PHP_OPCACHE_MAX_FILES=20000
```

**`PHP_OPCACHE_VALIDATE_TIMESTAMPS=0`** means PHP will NEVER check if files have changed, which drastically improves performance.

**Warning**: After each code deployment in production, you must clear OPcache:

```bash
docker exec prestashop php -r "opcache_reset();"
# OR
docker-compose restart prestashop
```

### Dev vs Prod Comparison

| Aspect | Development | Production |
|--------|-------------|------------|
| `display_errors` | On (easy debug) | **Off** (security) |
| `opcache.validate_timestamps` | 1 (detects changes) | **0** (max performance) |
| `memory_limit` | 512M (comfort) | 256M (economy) |
| Xdebug | Installed | **Not installed** |

## Troubleshooting

### .env changes are not applied

Restart the container:
```bash
docker-compose restart prestashop
```

### OPcache won't clear

```bash
docker exec prestashop php -r "opcache_reset();"
```

Or restart the container:
```bash
docker-compose restart prestashop
```

### Error "Fatal error: Allowed memory size exhausted"

Increase `PHP_MEMORY_LIMIT` in [.env](.env):
```bash
PHP_MEMORY_LIMIT=1024M
```

Then restart:
```bash
docker-compose restart prestashop
```

### PHP errors don't display

In development, check [.env](.env):
```bash
PHP_DISPLAY_ERRORS=On
PHP_ERROR_REPORTING=E_ALL
```

In production, this is **normal and desired**. Check logs:
```bash
docker logs prestashop
# or
docker exec prestashop tail -f /var/log/php_errors.log
```

## Production Deployment Checklist

- [ ] `PHP_DISPLAY_ERRORS=Off`
- [ ] `PHP_DISPLAY_STARTUP_ERRORS=Off`
- [ ] `PHP_OPCACHE_VALIDATE_TIMESTAMPS=0`
- [ ] `INSTALL_XDEBUG=false`
- [ ] Rebuild image: `docker-compose up -d --build`
- [ ] SSL enabled (see [SSL-SETUP.md](SSL-SETUP.md))
- [ ] DB passwords changed
- [ ] Verify phpinfo() (then delete the file!)

## Resources

- [PHP OPcache Documentation](https://www.php.net/manual/en/book.opcache.php)
- [PrestaShop Best Practices](https://devdocs.prestashop-project.org/)
- [SSL Guide](SSL-SETUP.md)

## File Structure

```
prestashop/
├── .env                           # Current config (dev by default)
├── .env.example                   # Dev template
├── .env.prod.example              # Production template
├── docker-compose.yml             # Passes variables to container
├── docker/
│   └── prestashop/
│       ├── Dockerfile             # Build args + ENV defaults
│       └── entrypoint.sh          # Generates custom.ini dynamically
├── PHP-CONFIG.md                  # This file
└── SSL-SETUP.md                   # SSL guide
```
