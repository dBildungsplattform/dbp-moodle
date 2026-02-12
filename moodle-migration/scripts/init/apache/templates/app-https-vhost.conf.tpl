{{https_listen_configuration}}
{{before_vhost_configuration}}
<VirtualHost {{https_listen_addresses}}>
  {{server_name_configuration}}
  SSLEngine on
  SSLCertificateFile "/opt/dbp-moodle/apache/certs/tls.crt"
  SSLCertificateKeyFile "/opt/dbp-moodle/apache/certs/tls.key"
  DocumentRoot {{document_root}}
  <Directory "{{document_root}}">
    Options -Indexes +FollowSymLinks -MultiViews
    AllowOverride {{allow_override}}
    {{acl_configuration}}
    {{extra_directory_configuration}}
  </Directory>
  {{additional_https_configuration}}
  {{additional_configuration}}
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
