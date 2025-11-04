FROM mariadb:10.11

# Server config
COPY my.cnf /etc/mysql/conf.d/my.cnf

# Init scripts executed once if /var/lib/mysql is empty
# import.sql must be readable and UTF-8 encoded
COPY import.sql /docker-entrypoint-initdb.d/01-import.sql