<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    # Enable .htaccess files
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted

        # Rewrite rules
        RewriteEngine On
        
        # If the request is for an actual file or directory, serve it directly
        RewriteCond %{REQUEST_FILENAME} -f [OR]
        RewriteCond %{REQUEST_FILENAME} -d
        RewriteRule ^ - [L]

        # Route /api requests to api/index.php
        RewriteRule ^api/ api/index.php [L]

        # Route all other requests to public/index.php
        RewriteRule ^ public/index.php [L]
    </Directory>

    # Set specific permissions for notes directory
    <Directory /var/www/html/public/notes>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
        
        # Additional security for notes directory
        <FilesMatch "\.(php|phar|phtml|php3|php4|php5|php7|phps)$">
            Require all denied
        </FilesMatch>
    </Directory>

    # Deny access to sensitive files
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

