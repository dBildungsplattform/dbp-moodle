# Default SSL Virtual Host configuration.

<IfModule !ssl_module>
  LoadModule ssl_module modules/mod_ssl.so
</IfModule>

Listen 8443
SSLProtocol all -SSLv2 -SSLv3
SSLHonorCipherOrder on
SSLCipherSuite "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !EDH !RC4"
SSLPassPhraseDialog  builtin
SSLSessionCache "shmcb:{{APACHE_LOGS_DIR}}/ssl_scache(512000)"
SSLSessionCacheTimeout  300

<VirtualHost _default_:8443>
  DocumentRoot "/opt/dbp-moodle/moodle"
  SSLEngine on
  SSLCertificateFile "/opt/dbp-moodle/apache/certs/tls.crt"
  SSLCertificateKeyFile "/opt/dbp-moodle/apache/certs/tls.key"

  <Directory "/opt/dbp-moodle/moodle">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

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
