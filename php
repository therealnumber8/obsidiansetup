# Global Apache configuration
<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

# API Directory Configuration
<Directory /var/www/html/api>
    RewriteEngine On
    RewriteRule ^.+$ index.php [L,QSA]
</Directory>

# Public Directory Configuration
<Directory /var/www/html/public>
    RewriteEngine On
    
    # Rewrite note requests without '.html' to the actual .html file
    RewriteCond %{REQUEST_FILENAME} .*/notes/.*
    RewriteCond %{REQUEST_FILENAME}.html -f
    RewriteRule !.*\.html$ %{REQUEST_FILENAME}.html [L]
</Directory>

# Root Directory Configuration
<Directory /var/www/html>
    RewriteEngine On

    # Rewrite API requests to api/index.php
    RewriteRule ^api/(.*)$ api/index.php [L,QSA]

    # Fallback for other requests to public directory
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ public/$1 [L]
</Directory>

# PHP configuration
<IfModule mod_php.c>
    php_value display_errors Off
    php_value log_errors On
    php_value error_log /tmp/php_errors.log
    php_value upload_max_filesize 10M
    php_value post_max_size 10M
</IfModule>

