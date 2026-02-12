{{https_listen_configuration}}
{{before_vhost_configuration}}
<VirtualHost {{https_listen_addresses}}>
  {{server_name_configuration}}
  SSLEngine on
  SSLCertificateFile "/opt/dbp-moodle/apache/certs/tls.crt"
  SSLCertificateKeyFile "/opt/dbp-moodle/apache/certs/tls.key"
  {{additional_https_configuration}}
  {{additional_configuration}}
</VirtualHost>
