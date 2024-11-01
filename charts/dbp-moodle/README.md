# dbp-moodle

![Version: 0.0.7](https://img.shields.io/badge/Version-0.0.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.1.13](https://img.shields.io/badge/AppVersion-4.1.13-informational?style=flat-square)

This is a Helm Chart bundling some of the bitnami resources to deploy Moodle for DBildungsplattform. Extending them with features such as
MariaDB and PostgreSQL support, Horizontal Autoscaling capabilities, Redis Session Store, Etherpad-Lite.
The Chart can be deployed without any modification but it is advised to set own secrets acccording to this readme.

**Homepage:** <https://dbildungsplattform.github.io/dbp-moodle/>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://charts/cronjob | cronjob | 0.1.0 |
| file://charts/cronjob | cronjob | 0.1.0 |
| file://charts/etherpad | etherpad | 0.1.0 |
| https://burningalchemist.github.io/sql_exporter/ | sql-exporter | 0.6.1 |
| https://charts.bitnami.com/bitnami | mariadb | 18.2.2 |
| https://charts.bitnami.com/bitnami | moodle | 22.2.7 |
| https://charts.bitnami.com/bitnami | postgresql | 15.5.7 |
| https://charts.bitnami.com/bitnami | postgresql | 15.5.7 |
| https://charts.bitnami.com/bitnami | redis | 19.5.3 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backup-cronjob.affinity | object | `{}` |  |
| backup-cronjob.clusterRole.create | bool | `false` |  |
| backup-cronjob.env[0].name | string | `"DATABASE_PASSWORD"` |  |
| backup-cronjob.env[0].valueFrom.secretKeyRef.key | string | `"mariadb-password"` |  |
| backup-cronjob.env[0].valueFrom.secretKeyRef.name | string | `"moodle"` |  |
| backup-cronjob.env[1].name | string | `"AWS_ACCESS_KEY_ID"` |  |
| backup-cronjob.env[1].valueFrom.secretKeyRef.key | string | `"s3_access_key"` |  |
| backup-cronjob.env[1].valueFrom.secretKeyRef.name | string | `"moodle-backup-s3"` |  |
| backup-cronjob.env[2].name | string | `"AWS_SECRET_ACCESS_KEY"` |  |
| backup-cronjob.env[2].valueFrom.secretKeyRef.key | string | `"s3_access_secret"` |  |
| backup-cronjob.env[2].valueFrom.secretKeyRef.name | string | `"moodle-backup-s3"` |  |
| backup-cronjob.env[3].name | string | `"S3_BACKUP_REGION_URL"` |  |
| backup-cronjob.env[3].valueFrom.secretKeyRef.key | string | `"s3_endpoint_url"` |  |
| backup-cronjob.env[3].valueFrom.secretKeyRef.name | string | `"moodle-backup-s3"` |  |
| backup-cronjob.extraVolumeMounts[0].mountPath | string | `"/scripts/"` |  |
| backup-cronjob.extraVolumeMounts[0].name | string | `"moodle-backup-script"` |  |
| backup-cronjob.extraVolumeMounts[1].mountPath | string | `"/mountData"` |  |
| backup-cronjob.extraVolumeMounts[1].name | string | `"moodle-pvc-data"` |  |
| backup-cronjob.extraVolumeMounts[2].mountPath | string | `"/etc/duply/default/"` |  |
| backup-cronjob.extraVolumeMounts[2].name | string | `"duply"` |  |
| backup-cronjob.extraVolumes[0].name | string | `"moodle-pvc-data"` |  |
| backup-cronjob.extraVolumes[0].persistentVolumeClaim.claimName | string | `"moodle-data"` |  |
| backup-cronjob.extraVolumes[1].configMap.defaultMode | int | `457` |  |
| backup-cronjob.extraVolumes[1].configMap.name | string | `"moodle-backup-script"` |  |
| backup-cronjob.extraVolumes[1].name | string | `"moodle-backup-script"` |  |
| backup-cronjob.extraVolumes[2].name | string | `"duply"` |  |
| backup-cronjob.extraVolumes[2].projected.defaultMode | int | `420` |  |
| backup-cronjob.extraVolumes[2].projected.sources[0].configMap.items[0].key | string | `"conf"` |  |
| backup-cronjob.extraVolumes[2].projected.sources[0].configMap.items[0].path | string | `"conf"` |  |
| backup-cronjob.extraVolumes[2].projected.sources[0].configMap.items[1].key | string | `"exclude"` |  |
| backup-cronjob.extraVolumes[2].projected.sources[0].configMap.items[1].path | string | `"exclude"` |  |
| backup-cronjob.extraVolumes[2].projected.sources[0].configMap.name | string | `"moodle-duply"` |  |
| backup-cronjob.extraVolumes[2].projected.sources[1].secret.name | string | `"moodle-backup-gpg-keys"` |  |
| backup-cronjob.image.repository | string | `"ghcr.io/dbildungsplattform/moodle-tools"` |  |
| backup-cronjob.image.tag | string | `"1.0.7"` |  |
| backup-cronjob.jobs[0].args[0] | string | `"/scripts/backup-script"` |  |
| backup-cronjob.jobs[0].command[0] | string | `"/bin/sh"` |  |
| backup-cronjob.jobs[0].command[1] | string | `"-c"` |  |
| backup-cronjob.jobs[0].failedJobsHistoryLimit | int | `1` |  |
| backup-cronjob.jobs[0].livenessProbe.exec.command[0] | string | `"cat"` |  |
| backup-cronjob.jobs[0].livenessProbe.exec.command[1] | string | `"/tmp/healthy"` |  |
| backup-cronjob.jobs[0].livenessProbe.initialDelaySeconds | int | `5` |  |
| backup-cronjob.jobs[0].livenessProbe.periodSeconds | int | `10` |  |
| backup-cronjob.jobs[0].name | string | `"backup"` |  |
| backup-cronjob.jobs[0].schedule | string | `"0 3 * * *"` |  |
| backup-cronjob.jobs[0].successfulJobsHistoryLimit | int | `1` |  |
| backup-cronjob.resources.limits.cpu | string | `"2000m"` |  |
| backup-cronjob.resources.limits.memory | string | `"4Gi"` |  |
| backup-cronjob.resources.requests.cpu | string | `"500m"` |  |
| backup-cronjob.resources.requests.memory | string | `"1Gi"` |  |
| backup-cronjob.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| backup-cronjob.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| backup-cronjob.securityContext.privileged | bool | `false` |  |
| backup-cronjob.securityContext.runAsGroup | int | `1001` |  |
| backup-cronjob.serviceAccount.create | bool | `false` |  |
| backup-cronjob.serviceAccount.name | string | `"moodle-backup-job"` |  |
| backup-cronjob.tolerations | list | `[]` |  |
| dbpMoodle.backup | object | `{"cluster_name":"","enabled":false,"endpoint":"","gpg_key_names":"","gpgkeys":{"existingSecret":"","gpgkey.dbpinfra.pub.asc":"","gpgkey.dbpinfra.sec.asc":""},"max_full_backup_age":"1W","retention_time":"6M","rules":[{"apiGroups":["apps"],"resources":["deployments"],"verbs":["get","patch","list","watch"]},{"apiGroups":["batch"],"resources":["cronjobs","jobs"],"verbs":["get","patch"]}],"s3_bucket_name":"","secrets":{"existingSecret":"","s3_access_key":"","s3_access_secret":"","s3_endpoint_url":""}}` | Backup configuration. Set enabled=true to enable the backup-cronjob. Also set s3 location credentials |
| dbpMoodle.backup.gpgkeys.existingSecret | string | `""` | Existing  secret for gpg keys |
| dbpMoodle.backup.max_full_backup_age | string | `"1W"` | Defines the maximum age of a full backup before a new full backup is created. The backups in between are incremental |
| dbpMoodle.backup.retention_time | string | `"6M"` | Defines the maximum age of a backup before it is deleted |
| dbpMoodle.backup.secrets | object | `{"existingSecret":"","s3_access_key":"","s3_access_secret":"","s3_endpoint_url":""}` | Either provide an existing secret, or set each secret value here. If both are set the existingSecret is used |
| dbpMoodle.backup.secrets.existingSecret | string | `""` | Existing secret for s3 endpoint |
| dbpMoodle.debug | bool | `false` | Moodle debugging is not safe for production |
| dbpMoodle.external_pvc.accessModes[0] | string | `"ReadWriteMany"` |  |
| dbpMoodle.external_pvc.annotations."helm.sh/resource-policy" | string | `"keep"` |  |
| dbpMoodle.external_pvc.enabled | bool | `true` |  |
| dbpMoodle.external_pvc.name | string | `"moodle-data"` |  |
| dbpMoodle.external_pvc.size | string | `"8Gi"` |  |
| dbpMoodle.external_pvc.storage_class | string | `"nfs-client"` |  |
| dbpMoodle.hpa | object | `{"average_cpu_utilization":50,"deployment_name_ref":"moodle","enabled":false,"max_replicas":4,"min_replicas":1,"scaledown_cooldown":60,"scaledown_value":25,"scaleup_cooldown":15,"scaleup_value":50}` | Horizontal pod autoscaling values |
| dbpMoodle.hpa.scaledown_cooldown | int | `60` | How many seconds to wait between downscaling adjustments |
| dbpMoodle.hpa.scaledown_value | int | `25` | The max amount in percent to scale down in one step per cooldown period |
| dbpMoodle.hpa.scaleup_cooldown | int | `15` | How many seconds to wait between upscaling adjustments |
| dbpMoodle.hpa.scaleup_value | int | `50` | The max amount in percent to scale up in one step per cooldown period |
| dbpMoodle.logging | bool | `false` | Extended php logging |
| dbpMoodle.moodleUpdatePreparationHook.rules[0].apiGroups[0] | string | `"apps"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[0].resources[0] | string | `"deployments"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[0].verbs[0] | string | `"get"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[0].verbs[1] | string | `"patch"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].apiGroups[0] | string | `"batch"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].resources[0] | string | `"cronjobs"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].resources[1] | string | `"jobs"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].verbs[0] | string | `"get"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].verbs[1] | string | `"list"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].verbs[2] | string | `"create"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].verbs[3] | string | `"patch"` |  |
| dbpMoodle.moodleUpdatePreparationHook.rules[1].verbs[4] | string | `"watch"` |  |
| dbpMoodle.moodleUpdatePreparationJob | object | `{"affinity":{},"kubectlImage":"bitnami/kubectl:1.30.4-debian-12-r3","resources":{},"tolerations":[]}` | A preperation job which disables the php-cronjob, scales down the deployment and creates a backup if dbpMoodle.backup.enabled=true |
| dbpMoodle.moodleUpdatePreparationJob.kubectlImage | string | `"bitnami/kubectl:1.30.4-debian-12-r3"` | Which kubectl image to use |
| dbpMoodle.moodlecronjob | object | `{"rules":[{"apiGroups":[""],"resources":["pods","pods/exec"],"verbs":["get","list","create","watch"]}],"wait_timeout":"15m"}` | Configuration for the moodle-cronjob which runs moodles cron.php. This is required since moodle does not run as root |
| dbpMoodle.name | string | `"infra"` |  |
| dbpMoodle.redis | object | `{"host":"moodle-redis-master","password":"","port":6379}` | Configurations for the optional redis |
| dbpMoodle.restore | object | `{"affinity":{},"enabled":false,"existingSecretDatabase":"moodle","existingSecretGPG":"","existingSecretKeyDatabase":"","existingSecretKeyS3Access":"","existingSecretKeyS3Secret":"","existingSecretS3":"","image":"ghcr.io/dbildungsplattform/moodle-tools:1.0.7","resources":{"limits":{"cpu":"2000m","memory":"16Gi"},"requests":{"cpu":"1000m","memory":"8Gi"}},"rules":[{"apiGroups":["apps"],"resources":["deployments/scale","deployments"],"verbs":["get","list","scale","patch"]}],"tolerations":[]}` | This restores moodle to the latest snapshot. Requires an existing s3 backup. ONLY USE FOR ROLLBACK |
| dbpMoodle.secrets | object | `{"etherpad_api_key":"","etherpad_postgresql_password":"","mariadb_password":"","mariadb_root_password":"","moodle_password":"","pgsql_admin_password":"","useChartSecret":true}` | Creates a secret with all relevant credentials for moodle -- Set useChartSecret: false to provide your own secret -- If you create your own secret, also set moodle.existingSecret (and moodle.externalDatabase.existingSecret if you bring your own DB) |
| dbpMoodle.stage | string | `"infra"` |  |
| dbpMoodle.update_migration | object | `{"enabled":false}` | The dbp update process to migrate moodle data when moodle versions are increased |
| etherpad-postgresql.auth.database | string | `"etherpad"` |  |
| etherpad-postgresql.auth.enablePostgresUser | bool | `false` |  |
| etherpad-postgresql.auth.existingSecret | string | `"moodle"` |  |
| etherpad-postgresql.auth.secretKeys.userPasswordKey | string | `"etherpad-postgresql-password"` |  |
| etherpad-postgresql.auth.username | string | `"etherpad"` |  |
| etherpad-postgresql.enabled | bool | `false` |  |
| etherpad-postgresql.persistence.existingClaim | string | `"moodle-etherpad-postgresql"` |  |
| etherpad-postgresql.primary.affinity | object | `{}` |  |
| etherpad-postgresql.primary.containerSecurityContext.privileged | bool | `false` |  |
| etherpad-postgresql.primary.resources.limits.cpu | string | `"1000m"` |  |
| etherpad-postgresql.primary.resources.limits.memory | string | `"1Gi"` |  |
| etherpad-postgresql.primary.resources.requests.cpu | string | `"50m"` |  |
| etherpad-postgresql.primary.resources.requests.memory | string | `"128Mi"` |  |
| etherpad-postgresql.primary.tolerations | list | `[]` |  |
| etherpadlite.affinity | object | `{}` |  |
| etherpadlite.enabled | bool | `false` |  |
| etherpadlite.env[0].name | string | `"DB_TYPE"` |  |
| etherpadlite.env[0].value | string | `"postgres"` |  |
| etherpadlite.env[1].name | string | `"DB_HOST"` |  |
| etherpadlite.env[1].value | string | `"moodle-etherpad-postgresql"` |  |
| etherpadlite.env[2].name | string | `"DB_PORT"` |  |
| etherpadlite.env[2].value | string | `"5432"` |  |
| etherpadlite.env[3].name | string | `"DB_NAME"` |  |
| etherpadlite.env[3].value | string | `"etherpad"` |  |
| etherpadlite.env[4].name | string | `"DB_USER"` |  |
| etherpadlite.env[4].value | string | `"etherpad"` |  |
| etherpadlite.env[5].name | string | `"DB_PASS"` |  |
| etherpadlite.env[5].valueFrom.secretKeyRef.key | string | `"etherpad-postgresql-password"` |  |
| etherpadlite.env[5].valueFrom.secretKeyRef.name | string | `"moodle"` |  |
| etherpadlite.env[6].name | string | `"REQUIRE_SESSION"` |  |
| etherpadlite.env[6].value | string | `"true"` |  |
| etherpadlite.image.repository | string | `"ghcr.io/dbildungsplattform/etherpad"` |  |
| etherpadlite.image.tag | string | `"1.8.18.0"` |  |
| etherpadlite.ingress.annotations."cert-manager.io/cluster-issuer" | string | `"sc-cert-manager-clusterissuer-letsencrypt"` |  |
| etherpadlite.ingress.enabled | bool | `true` |  |
| etherpadlite.ingress.hosts[0].host | string | `"etherpad.example.de"` |  |
| etherpadlite.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| etherpadlite.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| etherpadlite.ingress.tls[0].hosts[0] | string | `"etherpad.example.de"` |  |
| etherpadlite.ingress.tls[0].secretName | string | `"etherpad.example.de-tls"` |  |
| etherpadlite.resources.limits.cpu | string | `"1000m"` |  |
| etherpadlite.resources.limits.memory | string | `"1Gi"` |  |
| etherpadlite.resources.requests.cpu | string | `"100m"` |  |
| etherpadlite.resources.requests.memory | string | `"128Mi"` |  |
| etherpadlite.securityContext.privileged | bool | `false` |  |
| etherpadlite.tolerations | list | `[]` |  |
| etherpadlite.volumeMounts[0].mountPath | string | `"/opt/etherpad-lite/APIKEY.txt"` |  |
| etherpadlite.volumeMounts[0].name | string | `"api-key"` |  |
| etherpadlite.volumeMounts[0].subPath | string | `"APIKEY.txt"` |  |
| etherpadlite.volumes[0].name | string | `"api-key"` |  |
| etherpadlite.volumes[0].secret.items[0].key | string | `"etherpad-api-key"` |  |
| etherpadlite.volumes[0].secret.items[0].path | string | `"APIKEY.txt"` |  |
| etherpadlite.volumes[0].secret.secretName | string | `"moodle"` |  |
| global.kubectl_version | string | `"1.28.7"` |  |
| global.moodlePlugins | object | `{"adaptable":{"enabled":false},"booking":{"enabled":false},"boost_magnific":{"enabled":false},"boost_union":{"enabled":false},"certificate":{"enabled":false},"choicegroup":{"enabled":false},"coursecertificate":{"enabled":false},"dash":{"enabled":false},"etherpadlite":{"enabled":false},"geogebra":{"enabled":false},"groupselect":{"enabled":false},"heartbeat":{"enabled":false},"hvp":{"enabled":false},"jitsi":{"enabled":false},"kaltura":{"enabled":false},"oidc":{"enabled":false},"pdfannotator":{"enabled":false},"reengagement":{"enabled":false},"remuiformat":{"enabled":false},"saml2":{"enabled":false},"sharing_cart":{"enabled":false},"skype":{"enabled":false},"snap":{"enabled":false},"staticpage":{"enabled":false},"tiles":{"enabled":false},"topcoll":{"enabled":false},"unilabel":{"enabled":false},"xp":{"enabled":false},"zoom":{"enabled":false}}` | All plugins are disabled by default. if enabled, the plugin is installed on image startup |
| global.storageClass | string | `"nfs-client"` | Default storage class, should support ReadWriteMany |
| mariadb.auth.database | string | `"moodle"` |  |
| mariadb.auth.existingSecret | string | `"moodle"` |  |
| mariadb.auth.username | string | `"moodle"` |  |
| mariadb.enabled | bool | `true` |  |
| mariadb.global.storageClass | string | `"nfs-client"` |  |
| mariadb.image.tag | string | `"11.3.2-debian-12-r5"` |  |
| mariadb.metrics.enabled | bool | `true` |  |
| mariadb.metrics.serviceMonitor.enabled | bool | `true` |  |
| mariadb.primary.affinity | object | `{}` |  |
| mariadb.primary.containerSecurityContext.privileged | bool | `false` |  |
| mariadb.primary.resources.limits.cpu | int | `9` |  |
| mariadb.primary.resources.limits.memory | string | `"3Gi"` |  |
| mariadb.primary.resources.requests.cpu | string | `"250m"` |  |
| mariadb.primary.resources.requests.memory | string | `"256Mi"` |  |
| mariadb.primary.tolerations | list | `[]` |  |
| moodle.affinity | object | `{}` |  |
| moodle.allowEmptyPassword | bool | `false` |  |
| moodle.containerPorts.http | int | `8080` |  |
| moodle.containerPorts.https | int | `8443` |  |
| moodle.containerSecurityContext.enabled | bool | `true` |  |
| moodle.containerSecurityContext.privileged | bool | `false` |  |
| moodle.containerSecurityContext.runAsGroup | int | `1001` |  |
| moodle.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| moodle.existingSecret | string | `"moodle"` |  |
| moodle.externalDatabase.database | string | `"moodle"` | Name of the existing database |
| moodle.externalDatabase.existingSecret | string | `"moodle"` | Name of an existing secret resource containing the DB password |
| moodle.externalDatabase.host | string | `"moodle-mariadb"` | Host of the existing database |
| moodle.externalDatabase.password | string | `""` | Password for the above username |
| moodle.externalDatabase.port | int | `3306` | Port of the existing database |
| moodle.externalDatabase.type | string | `"mariadb"` | Type of DB to provision, possible values are "mariadb" and "pgsql" |
| moodle.externalDatabase.user | string | `"moodle"` | Existing username in the external db |
| moodle.extraEnvVarsSecret | string | `""` |  |
| moodle.extraEnvVars[0].name | string | `"PHP_POST_MAX_SIZE"` |  |
| moodle.extraEnvVars[0].value | string | `"200M"` |  |
| moodle.extraEnvVars[1].name | string | `"PHP_UPLOAD_MAX_FILESIZE"` |  |
| moodle.extraEnvVars[1].value | string | `"200M"` |  |
| moodle.extraEnvVars[2].name | string | `"PHP_MAX_INPUT_VARS"` |  |
| moodle.extraEnvVars[2].value | string | `"5000"` |  |
| moodle.extraEnvVars[3].name | string | `"MOODLE_PLUGINS"` |  |
| moodle.extraEnvVars[3].valueFrom.configMapKeyRef.key | string | `"moodle-plugin-list"` |  |
| moodle.extraEnvVars[3].valueFrom.configMapKeyRef.name | string | `"moodle-plugins"` |  |
| moodle.extraVolumeMounts[0].mountPath | string | `"/moodleconfig"` |  |
| moodle.extraVolumeMounts[0].name | string | `"moodle-config"` |  |
| moodle.extraVolumeMounts[0].readOnly | bool | `true` |  |
| moodle.extraVolumes[0].name | string | `"moodle-config"` |  |
| moodle.extraVolumes[0].secret.defaultMode | int | `420` |  |
| moodle.extraVolumes[0].secret.items[0] | object | `{"key":"config.php","path":"config.php"}` | The custom config.php file that is used to configure moodle to use the database and redis (if activated) |
| moodle.extraVolumes[0].secret.items[1] | object | `{"key":"php.ini","path":"php.ini"}` | The php.ini which installs the php-redis extension to enable the use for redis |
| moodle.extraVolumes[0].secret.secretName | string | `"moodle-config"` |  |
| moodle.image.debug | bool | `false` | Debug mode for more detailed moodle installation and log output |
| moodle.image.pullPolicy | string | `"Always"` |  |
| moodle.image.registry | string | `"ghcr.io"` |  |
| moodle.image.repository | string | `"dbildungsplattform/moodle"` |  |
| moodle.image.tag | string | `"4.1.13-debian-12-r2-dbp1"` | The dbp-moodle image which is build for this helm chart |
| moodle.ingress.annotations."cert-manager.io/cluster-issuer" | string | `"sc-cert-manager-clusterissuer-letsencrypt"` |  |
| moodle.ingress.annotations."nginx.ingress.kubernetes.io/proxy-body-size" | string | `"200M"` |  |
| moodle.ingress.annotations."nginx.ingress.kubernetes.io/proxy-connect-timeout" | string | `"30s"` |  |
| moodle.ingress.annotations."nginx.ingress.kubernetes.io/proxy-read-timeout" | string | `"20s"` |  |
| moodle.ingress.enabled | bool | `true` |  |
| moodle.ingress.hostname | string | `"example.de"` | The hostname of the moodle application |
| moodle.ingress.tls | bool | `true` |  |
| moodle.mariadb | object | `{"enabled":false}` | The mariadb included in bitnami/moodle chart. For this chart usage of mariadb.enabled with moodle.externalDatabase.type="mariadb" is recommended |
| moodle.metrics.enabled | bool | `true` |  |
| moodle.metrics.resources | object | `{"limits":{"cpu":"200m","memory":"256Mi"},"requests":{"cpu":"10m","memory":"16Mi"}}` | Resources have to be set so that the horizontal pod autoscaler for moodle can read the moodle cpu consumption correctly |
| moodle.metrics.service.type | string | `"ClusterIP"` |  |
| moodle.moodleEmail | string | `""` |  |
| moodle.moodleLang | string | `"de"` |  |
| moodle.moodleSiteName | string | `"Moodle"` |  |
| moodle.moodleSkipInstall | bool | `false` |  |
| moodle.moodleUsername | string | `"admin"` |  |
| moodle.networkPolicy.enabled | bool | `false` |  |
| moodle.persistence.existingClaim | string | `"moodle-data"` | If this value is unset, the bitnami/moodle chart generates its own PV & PVC |
| moodle.podAnnotations.moodle/image | string | `"{{- .Values.image.repository -}}:{{- .Values.image.tag -}}"` |  |
| moodle.podAnnotations.moodleplugins/checksum | string | `"{{- include \"dbpMoodle.pluginConfigMap.content\" . | sha256sum -}}"` |  |
| moodle.podSecurityContext.enabled | bool | `true` |  |
| moodle.resources.limits.cpu | int | `6` |  |
| moodle.resources.limits.memory | string | `"3Gi"` |  |
| moodle.resources.requests.cpu | string | `"300m"` |  |
| moodle.resources.requests.memory | string | `"512Mi"` |  |
| moodle.service.type | string | `"ClusterIP"` |  |
| moodle.tolerations | list | `[]` |  |
| moodle.updateStrategy.type | string | `"RollingUpdate"` |  |
| moodlecronjob.affinity | object | `{}` |  |
| moodlecronjob.clusterRole.create | bool | `false` |  |
| moodlecronjob.image.repository | string | `"ghcr.io/dbildungsplattform/moodle-tools"` |  |
| moodlecronjob.image.tag | string | `"1.0.7"` |  |
| moodlecronjob.jobs[0].args[0] | string | `"/scripts/cronjob-script"` |  |
| moodlecronjob.jobs[0].backoffLimit | int | `1` |  |
| moodlecronjob.jobs[0].command[0] | string | `"/bin/bash"` |  |
| moodlecronjob.jobs[0].command[1] | string | `"-c"` |  |
| moodlecronjob.jobs[0].concurrencyPolicy | string | `"Forbid"` |  |
| moodlecronjob.jobs[0].extraVolumeMounts[0].mountPath | string | `"/scripts/"` |  |
| moodlecronjob.jobs[0].extraVolumeMounts[0].name | string | `"moodle-php-script"` |  |
| moodlecronjob.jobs[0].extraVolumes[0].configMap.defaultMode | int | `457` |  |
| moodlecronjob.jobs[0].extraVolumes[0].configMap.name | string | `"moodle-php-script"` |  |
| moodlecronjob.jobs[0].extraVolumes[0].name | string | `"moodle-php-script"` |  |
| moodlecronjob.jobs[0].failedJobsHistoryLimit | int | `1` |  |
| moodlecronjob.jobs[0].livenessProbe.exec.command[0] | string | `"cat"` |  |
| moodlecronjob.jobs[0].livenessProbe.exec.command[1] | string | `"/tmp/healthy"` |  |
| moodlecronjob.jobs[0].livenessProbe.initialDelaySeconds | int | `2` |  |
| moodlecronjob.jobs[0].livenessProbe.periodSeconds | int | `2` |  |
| moodlecronjob.jobs[0].name | string | `"php-script"` |  |
| moodlecronjob.jobs[0].restartPolicy | string | `"Never"` |  |
| moodlecronjob.jobs[0].schedule | string | `"* * * * *"` |  |
| moodlecronjob.jobs[0].successfulJobsHistoryLimit | int | `1` |  |
| moodlecronjob.resources | object | `{}` |  |
| moodlecronjob.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| moodlecronjob.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| moodlecronjob.securityContext.privileged | bool | `false` |  |
| moodlecronjob.securityContext.runAsGroup | int | `1001` |  |
| moodlecronjob.serviceAccount.create | bool | `false` |  |
| moodlecronjob.serviceAccount.name | string | `"moodle-moodle-cronjob"` |  |
| moodlecronjob.tolerations | list | `[]` |  |
| postgresql.auth.database | string | `"moodle"` |  |
| postgresql.auth.existingSecret | string | `"moodle"` |  |
| postgresql.auth.secretKeys.adminPasswordKey | string | `"pgsql-admin-password"` |  |
| postgresql.auth.secretKeys.userPasswordKey | string | `"mariadb-password"` | Moodle expects its db password key to be mariadb-password |
| postgresql.auth.username | string | `"moodle"` |  |
| postgresql.enabled | bool | `false` |  |
| postgresql.image.tag | string | `"14.8.0-debian-11-r0"` |  |
| postgresql.metrics.enabled | bool | `true` |  |
| postgresql.metrics.serviceMonitor.enabled | bool | `true` |  |
| postgresql.primary.affinity | object | `{}` |  |
| postgresql.primary.containerSecurityContext.privileged | bool | `false` |  |
| postgresql.primary.extendedConfiguration | string | `"max_connections = 800\n"` |  |
| postgresql.primary.resources.limits.cpu | int | `9` |  |
| postgresql.primary.resources.limits.memory | string | `"3Gi"` |  |
| postgresql.primary.resources.requests.cpu | string | `"250m"` |  |
| postgresql.primary.resources.requests.memory | string | `"256Mi"` |  |
| postgresql.primary.tolerations | list | `[]` |  |
| redis.architecture | string | `"standalone"` |  |
| redis.auth.enabled | bool | `true` |  |
| redis.auth.existingSecret | string | `"moodle"` |  |
| redis.auth.existingSecretPasswordKey | string | `"redis-password"` |  |
| redis.auth.usePasswordFileFromSecret | bool | `true` |  |
| redis.enabled | bool | `true` |  |
| redis.master.affinity | object | `{}` |  |
| redis.master.resources | object | `{}` |  |
| redis.master.tolerations | list | `[]` |  |
| sql-exporter.affinity | object | `{}` |  |
| sql-exporter.config.collector_files[0] | string | `"collectors/sql_exporter_moodle.yaml"` |  |
| sql-exporter.config.target.collectors[0] | string | `"sql_exporter_moodle"` |  |
| sql-exporter.config.target.data_source_name | string | `""` |  |
| sql-exporter.enabled | bool | `false` |  |
| sql-exporter.extraVolumes[0].mount.mountPath | string | `"/etc/sql_exporter/collectors/"` |  |
| sql-exporter.extraVolumes[0].mount.readOnly | bool | `true` |  |
| sql-exporter.extraVolumes[0].name | string | `"moodle-collector-config"` |  |
| sql-exporter.extraVolumes[0].volume.configMap.items[0].key | string | `"moodle-collector-config"` |  |
| sql-exporter.extraVolumes[0].volume.configMap.items[0].path | string | `"sql_exporter_moodle.yaml"` |  |
| sql-exporter.extraVolumes[0].volume.configMap.name | string | `"moodle-sql-exporter-configmap"` |  |
| sql-exporter.image.pullPolicy | string | `"IfNotPresent"` |  |
| sql-exporter.resources | object | `{}` |  |
| sql-exporter.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| sql-exporter.securityContext.privileged | bool | `false` |  |
| sql-exporter.tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.2.0](https://github.com/norwoodj/helm-docs/releases/v1.2.0)
