#!/bin/bash
set -e

echo "=== PrestaShop Container Initialization ==="

# ======================================
# 1. Dynamic PHP configuration generation
# ======================================
echo "Generating PHP configuration from environment variables..."

cat > /usr/local/etc/php/conf.d/custom.ini <<EOF
; PHP configuration generated dynamically
; Modify environment variables in docker-compose.yml or .env

; Memory & Performance
memory_limit = ${PHP_MEMORY_LIMIT:-512M}
max_execution_time = ${PHP_MAX_EXECUTION_TIME:-600}
max_input_time = ${PHP_MAX_INPUT_TIME:-600}
max_input_vars = ${PHP_MAX_INPUT_VARS:-10000}

; Upload & Post
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE:-64M}
post_max_size = ${PHP_POST_MAX_SIZE:-64M}
file_uploads = On

; Error Reporting
display_errors = ${PHP_DISPLAY_ERRORS:-On}
display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS:-On}
error_reporting = ${PHP_ERROR_REPORTING:-E_ALL}
log_errors = On
error_log = /var/log/php_errors.log

; Session Security
session.gc_maxlifetime = ${PHP_SESSION_GC_MAXLIFETIME:-1440}
session.cookie_lifetime = ${PHP_SESSION_COOKIE_LIFETIME:-0}
session.cookie_httponly = On
session.cookie_secure = ${PHP_SESSION_COOKIE_SECURE:-Off}
session.use_strict_mode = On
session.cookie_samesite = ${PHP_SESSION_COOKIE_SAMESITE:-Lax}

; Date
date.timezone = ${PHP_TIMEZONE:-Europe/Paris}

; Realpath Cache (performance)
realpath_cache_size = ${PHP_REALPATH_CACHE_SIZE:-4096k}
realpath_cache_ttl = ${PHP_REALPATH_CACHE_TTL:-600}

; Security Settings
expose_php = Off
allow_url_fopen = On
allow_url_include = Off

; Disable dangerous functions in production
; Remove functions needed by PrestaShop (proc_open, proc_close for some modules)
disable_functions = ${PHP_DISABLE_FUNCTIONS:-pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,system,exec,shell_exec,passthru,phpinfo,show_source,highlight_file,popen,proc_nice,dl}

; File Limits
max_file_uploads = 20
EOF

# Dynamic OPcache configuration
if [ "${PHP_OPCACHE_ENABLE:-1}" = "1" ]; then
    cat > /usr/local/etc/php/conf.d/opcache-dynamic.ini <<EOF
; OPcache Configuration
opcache.enable = 1
opcache.memory_consumption = ${PHP_OPCACHE_MEMORY:-256}
opcache.interned_strings_buffer = ${PHP_OPCACHE_INTERNED_STRINGS:-16}
opcache.max_accelerated_files = ${PHP_OPCACHE_MAX_FILES:-20000}
opcache.revalidate_freq = ${PHP_OPCACHE_REVALIDATE_FREQ:-2}
opcache.validate_timestamps = ${PHP_OPCACHE_VALIDATE_TIMESTAMPS:-0}
opcache.fast_shutdown = 1
opcache.enable_cli = 0
EOF
    echo "OPcache enabled with validate_timestamps=${PHP_OPCACHE_VALIDATE_TIMESTAMPS:-0}"
else
    echo "opcache.enable = 0" > /usr/local/etc/php/conf.d/opcache-dynamic.ini
    echo "OPcache disabled"
fi

echo "PHP configuration generated successfully"
echo "  - memory_limit: ${PHP_MEMORY_LIMIT:-512M}"
echo "  - upload_max_filesize: ${PHP_UPLOAD_MAX_FILESIZE:-64M}"
echo "  - max_execution_time: ${PHP_MAX_EXECUTION_TIME:-600}"
echo "  - display_errors: ${PHP_DISPLAY_ERRORS:-On}"

# ======================================
# 2. Create missing directories
# ======================================
echo "Creating missing directories..."
mkdir -p /var/www/html/app/Resources/translations 2>/dev/null || true
mkdir -p /var/www/html/var/cache 2>/dev/null || true
mkdir -p /var/www/html/var/logs 2>/dev/null || true

# ======================================
# 3. Fix permissions
# ======================================
echo "Fixing PrestaShop permissions..."
chown -R www-data:www-data /var/www/html/var/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/mails/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/translations/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/app/Resources/translations/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/img/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/download/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/upload/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/config/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/cache/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/log/ 2>/dev/null || true

# ======================================
# 4. Fix Windows paths (WSL)
# ======================================
for cache_file in /var/www/html/var/cache/*/class_index.php; do
    if [ -f "$cache_file" ]; then
        echo "Fixing Windows paths in $cache_file"
        sed -i "s/\\\\\\\\/\//g" "$cache_file"
    fi
done

echo "=== Initialization complete. Starting Apache... ==="
echo ""

# Execute the command passed as argument (apache2-foreground)
exec "$@"
