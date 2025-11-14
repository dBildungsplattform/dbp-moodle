# Default Virtual Host configuration.

# Let Apache know we're behind a SSL reverse proxy
SetEnvIf X-Forwarded-Proto https HTTPS=on

<VirtualHost _default_:8080>
  DocumentRoot "/opt/dbp-moodle/moodle"
  <Directory "/opt/dbp-moodle/moodle">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  <FilesMatch \.php$>
  # If you are using a TCP port, use the following format
  # replacing the IP and port as needed:
  SetHandler "proxy:fcgi://127.0.0.1:9000"

  # If you are using a Unix socket, use the following format,
  # rewriting the path to the socket to match your php-fpm configuration 
  # SetHandler "proxy:unix:/var/run/php-fpm/www.sock|fcgi://localhost" 

  </FilesMatch>

  # Error Documents
  ErrorDocument 503 /503.html

  RewriteEngine On
  RewriteRule ^/phpmyadmin - [L,NC]
  RewriteRule "(\/vendor\/)" - [F]
  RewriteRule "(\/node_modules\/)" - [F]
  RewriteRule "(^|/)\.(?!well-known\/)" - [F]
  RewriteRule "(composer\.json)" - [F]
  RewriteRule "(\.lock)" - [F]
  RewriteRule "(\/environment.xml)" - [F]
  Options -Indexes
  RewriteRule "(\/install.xml)" - [F]
  RewriteRule "(\/README)" - [F]
  RewriteRule "(\/readme)" - [F]
  RewriteRule "(\/moodle_readme)" - [F]
  RewriteRule "(\/upgrade\.txt)" - [F]
  RewriteRule "(phpunit\.xml\.dist)" - [F]
  RewriteRule "(\/tests\/behat\/)" - [F]
  RewriteRule "(\/fixtures\/)" - [F]
  RewriteRule "(\/package\.json)" - [F]
  RewriteRule "(\/Gruntfile\.js)" - [F]
</VirtualHost>

