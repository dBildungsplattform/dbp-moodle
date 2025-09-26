# Default Virtual Host configuration.

# Let Apache know we're behind a SSL reverse proxy
SetEnvIf X-Forwarded-Proto https HTTPS=on

<VirtualHost _default_:8080>
  DocumentRoot "$APACHE_BASE_DIR/htdocs"
  <Directory "$APACHE_BASE_DIR/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  <FilesMatch \.php$>
  # If you are using a TCP port, use the following format
  # replacing the IP and port as needed:
  # SetHandler "proxy:fcgi://127.0.0.1:9000" 

  # If you are using a Unix socket, use the following format,
  # rewriting the path to the socket to match your php-fpm configuration 
  SetHandler "proxy:unix:/var/run/php-fpm/www.sock|fcgi://localhost" 

  </FilesMatch>

  # Error Documents
  ErrorDocument 503 /503.html
</VirtualHost>

