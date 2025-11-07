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
  {{htaccess_include}}
</VirtualHost>
