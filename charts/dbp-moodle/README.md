# dbp Moodle Helm Chart

A [Helm Library Chart](https://helm.sh/docs/topics/library_charts/#helm) for grouping common logic between bitnami charts.

## TL;DR

```console
$ helm repo add moodle https://dbildungsplattform.github.io/dbp-moodle/
$ helm install moodle moodle/dbp-moodle
```
Notice: It is advised to use "moodle" as helm chart name due to naming of database configurations which are set in the default values. This can be circumvented by setting the values:
  - moodle.externalDatabase.host
  - etherpad-postgresql.persistence.existingClaim
  - etherpadlite.env.DB_HOST.value
  - moodle_hpa.deployment_name_ref


The dbp-moodle Helm Chart dependencies
```yaml
dependencies:
  - name: moodle
    version: "22.2.7"
    repository: https://charts.bitnami.com/bitnami

  - name: redis
    version: "19.5.3"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled

  - name: mariadb
    version: "18.2.2"
    repository: https://charts.bitnami.com/bitnami
    condition: mariadb.enabled

  - name: postgresql
    version: "15.5.7"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled

  - name: cronjob
    alias: backup-cronjob
    version: 0.1.0
    repository: "file://charts/backup-cronjob"
    condition: backup.enabled

  - name: postgresql
    version: "15.5.7"
    repository: https://charts.bitnami.com/bitnami
    alias: etherpad-postgresql
    condition: etherpadlite.enabled

  - name: etherpad
    version: 0.1.0
    repository: "file://charts/etherpad"
    alias: etherpadlite
    condition: etherpadlite.enabled
```

## Introduction

This is a Helm Chart bundling some of the bitnami resources to deploy Moodle for DBildungsplattform. Extending them with features such as 

MariaDB and PostgreSQL support, Horizontal Autoscaling capabilities, Redis Session Store, Etherpad-Lite.
The Chart can be deployed without any modification but it is advised to set own secrets acccording to this readme.

## Parameters

The following table lists the helpers available in the library which are scoped in different sections.

### Globals
| Name                 | Description  | Value       |
| -----                | ------------ | --------    |
| `name`                 |              | `"infra"`        |
| `stage`                |              | `"infra"`        |
| `kubectl_version`      |              | `"1.28.7"`     |
| `infratools_image_tag` |              | `"4.0.3"`      |
| `storageClass`         |              | `"nfs-client"` |

### Backup
| Name                | Description  | Value        |
| -----               | ------------ | --------     |
| `enabled`             |              | `false`        |
| `gpg_key_names`       |              | `"dbpinfra"`     |
| `s3_bucket_name`      |              | `"default"`      |
| `cluster_name`        |              | `"default"`      |
| `endpoint.url`        |              | `"moodle.example.de"` |

### dbpMoodle
| Name                                   | Description  | Value        |
| -----                                  | ------------ | --------     |
| `logging`                              |              | `false` |
| `debug`                                | Moodle Debugging is not safe for production | `false` |
| `restore`                              |              | `false` |
| `update_migration.enabled`             | The dbp update process to migrate moodle date when Moodle versions are increased | `false` |
| `redis.host`                           | | `"moodle-redis-master`"|
| `redis.port`                           | | `6379` |
| `redis.password`                       | | `"moodle"` |
| `secrets.useChartSecret`               | If set to true the secret will be created with given values. | `true` |
| `updateHelper.rules`                   | [WIP] Set permissions for the updateHelper that is created when `update_migration.enabled=true`| `[...]` |
| `secrets.moodle_password`              | | `randAlphaNum 16` |
| `secrets.postgres_admin_password`      | | `randAlphaNum 16` |
| `secrets.mariadb_password`             | | `randAlphaNum 16` |
| `secrets.mariadb_root_password`        | | `randAlphaNum 16` |
| `secrets.etherpad_postgresql_password` | | `randAlphaNum 16` |
| `secrets.etherpad_api_key`             | | `"moodle"` |

### infratools
| Name                     | Description  | Value        |
| -----                    | ------------ | --------     |
|`repository`||`schulcloud`|
|`image_tag`||`4.0.3`|

### external_pvc
| Name                     | Description  | Value               |
| -----                    | ------------ | --------            |
| `enabled`                | Currently not operational. WIP     | `false`             |
| `name`                   | The Name of the external PVC to use. | `"moodle-data"`     |
| `size`                   |              | `"8Gi"`             |
| `storage_class`          |              | `"nfs-client"`      |
| `accessModes`            | Because of Autoscaling and [WIP] Update Process it needs to be accessed by multiple Pods. | `["ReadWriteMany"]` |
| `annotations."helm.sh/resource-policy"`|   | `"keep"` |

### moodle_hpa
Horizontal Pod Autoscaling Values
| Name                        | Description  | Value        |
| -----                       | ------------ | --------     |
| `deployment_name_ref`       | |`"moodle"`|
| `enabled`                   | |`false` |
| `min_replicas`              | |`1`|
| `max_replicas`              | |`4`|
| `average_cpu_utilization`   | |`50`|
| `scaledown_value`           | The max amount in percent to scale in one step per cooldown period | `25` |
| `scaledown_cooldown`        ||`60`|
| `scaleup_value`             ||`50`|
| `scaleup_cooldown`          ||`15`|

## Parameters for Dependencies

### moodle
| Name                                | Description  | Value        |
|---                                         |---|---|
| `image.registry`                            ||`ghcr.io`|
| `image.repository`                          ||`dbildungsplattform/moodle`|
| `image.tag`                                 | The dbp Image which is build for this Helm Chart. |`"4.1.11-debian-12-r0"`|
| `image.pullPolicy`                          ||`Always`|
| `image.debug`                               | Debug mode for more detailed Moodle installation and log output. |`false`|
| `moodleSkipInstall`                         ||`false`|
| `moodleSiteName`                            ||`"Moodle"`|
| `moodleLang`                                ||`"de"`|
| `moodleUsername`                            ||`admin`|
| `moodleEmail`                               ||`devops@dbildungscloud.de`|
| `allowEmptyPassword`                        ||`false`|
| `extraEnvVars`                              |   | `[...] `|
| `extraEnvVars.PHP_POST_MAX_SIZE`            ||`200M`|
| `extraEnvVars.PHP_UPLOAD_MAX_FILESIZE`      ||`200M`|
| `extraEnvVars.PHP_MAX_INPUT_VARS`           ||`"5000"`|
| `extraEnvVars.MOODLE_PLUGINS`               | WIP | |
| `extraEnvVars.ENABLE_KALTURA`               ||`"false"`|
| `extraEnvVarsSecret`                        ||`"moodle"`|
| `existingSecret`                            | If this value is not set, moodle will create its own secret "moodle" which could cause problems. |`"moodle"`|
| `persistence.enabled`                       ||`true`|
| `persistence.storageClass`                  ||`"nfs-client"`|
| `persistence.annotations`                   ||`"helm.sh/resource-policy":"keep"`|
| `resources.requests.cpu`                    ||`300m`|
| `resources.requests.memory`                 ||`512Mi`|
| `resources.limits.cpu`                      ||`6`|
| `resources.limits.memory`                   ||`3Gi`|
| `mariadb.enabled`                           ||`false`|
| `externalDatabase.type`                     ||`"mariadb"`|
| `externalDatabase.host`                     ||`"moodle-mariadb"`|
| `externalDatabase.port`                     ||`3306`|
| `externalDatabase.user`                     ||`"moodle"`|
| `externalDatabase.database`                 ||`"moodle"`|
| `externalDatabase.password`                 ||`"moodle"`|
| `externalDatabase.existingSecret`           ||`"moodle"`|
| `service.type`                              ||`ClusterIP`|
| `ingress.enabled`                           ||`true`|
| `ingress.hostname`                          | The corresponding hostname of the moodle application. |`"example.hostname.de"`|
| `ingress.tls`                               ||`true`|
| `ingress.annotations`                       ||`[...] `|
| `metrics.enabled`                           ||`true`|
| `metrics.service.type`                      ||`ClusterIP`|
| `metrics.resources.requests.cpu`            ||`10m`|
| `metrics.resources.requests.memory`         ||`16Mi`|
| `metrics.resources.limits.cpu`              ||`200m`|
| `metrics.resources.limits.memory`           ||`256Mi`|
| `metrics.extraVolumeMounts`                 | The required configuration files for Moodle to work. |  `[...] `|
| `metrics.extraVolumeMounts.name`            ||`moodle-config`|
| `metrics.extraVolumeMounts.readOnly`        ||`true`|
| `metrics.extraVolumeMounts.mountPath`       ||`/moodleconfig`|
| `metrics.extraVolumes`                      | A List of Files to mount |  `[...] `|
| `metrics.extraVolumes.name`                 ||`moodle-config`|
| `metrics.extraVolumes.secret.secretName`    ||`moodle-config`|
| `metrics.extraVolumes.secret.items[0].key`  | The custom config.php File that is used to configure Moodle to use the Database and Redis (If activated) |`config.php`|
| `metrics.extraVolumes.secret.items[0].path` ||`config.php`|
| `metrics.extraVolumes.secret.items[1].key`  | The php.ini which installs the php-redis extension to enable the use for redis. |`php.ini`|
| `metrics.extraVolumes.secret.items[1].path` ||`php.ini`|
| `metrics.extraVolumes.secret.defaultMode`   ||`644`|

### mariadb
| Name                                    | Description  | Value        |
| -----                                   | ------------ | --------     |
| `enabled`                                 || `true` |
| `global.storageClass`                     || `"nfs-client"` |
| `image.tag`                               || `"11.3.2-debian-12-r5"` |
| `auth.username`                           || `"moodle"` |
| `auth.database`                           || `"moodle"` |
| `auth.rootPassword`                       || `"moodle"` |
| `auth.password`                           || `"moodle"` |
| `auth.existingSecret`                     || `"moodle"` |
| `metrics.enabled`                         || `true` |
| `metrics.serviceMonitor.enabled`          || `true` |
| `primary.resources.requests.cpu`          || `"250m" ` |
| `primary.resources.requests.memory`       || `"256Mi" ` |
| `primary.resources.limits.cpu`            || `9 ` |
| `primary.resources.limits.memory`         || `"3Gi" ` |

### postgresql
| Name                                   | Description  | Value        |
| -----                                  | ------------ | --------     |
| `enabled`                                 || `false` |
| `image.tag`                               || `"14.8.0-debian-11-r0"` |
| `auth.username`                           || `"moodle"` |
| `auth.database`                           || `"moodle"` |
| `auth.existingSecret`                     || `"moodle"` |
| `auth.secretKeys.adminPasswordKey`        || `"PGSQL_POSTGRES_PASSWORD"` |
| `auth.secretKeys.userPasswordKey`         || `"postgresql-password"` |
| `metrics.enabled`                         || `true` |
| `metrics.serviceMonitor.enabled`          || `true` |
| `primary.extendedConfiguration`           || `"max_connections = 800"` |
| `primary.resources.requests.cpu`          || `"250m"` |
| `primary.resources.requests.memory`       || `"256Mi"` |
| `primary.resources.limits.cpu`            || `9` |
| `primary.resources.limits.memory`         || `"3Gi"` |

### redis
| Name                                    | Description  | Value        |
| -----                                   | ------------ | --------     |
| `enabled`                                 || `false` |
| `architecture`                            || `"standalone"` |
| `auth.enabled`                            || `true` |
| `auth.password`                           || `"moodle"` |
| `auth.existingSecret`                     || `"moodle"` |
| `auth.existingSecretPasswordKey`          || `"redis-password"` |
| `auth.usePasswordFileFromSecret`          || `true` |

### etherpad-postgresql
| Name                                   | Description  | Value        |
| -----                                  | ------------ | --------     |
| `auth.enablePostgresUser`               |              | `false`      |
| `auth.username`                         |              | `"etherpad"` |
| `auth.existingSecret`                   |              | `"moodle"` |
| `auth.secretKeys.userPasswordKey`       |              | `"etherpad-postgresql-password"` |
| `auth.database`                         |              | `"etherpad"` |
| `persistence.existingClaim`             |              | `"moodle-etherpad-postgresql"` |
| `primary.resources.requests.cpu`        |              | `"50m"` | 
| `primary.resources.requests.memory`     |              | `"128Mi"` |                      
| `primary.resources.limits.cpu`          |              | `"1000m"` |
| `primary.resources.limits.memory`       |              | `"1Gi"` |

### etherpadlite
Etherpad requires configuration to work.
| Name                                      | Description  | Value        |
| -----                                     | ------------ | --------     |
| `enabled`                                 | | `true `|
| `image.repository`                        | | `"ghcr.io/dbildungsplattform/etherpad"` |
| `image.tag`                               | | `"1.8.18.0"` |
| `env.DB_TYPE`                             | | `"postgres"` |
| `env.DB_HOST`                             | | `"moodle-etherpad-postgresql"` |
| `env.DB_PORT`                             | | `5432 `|
| `env.DB_NAME`                             | | `"etherpad"` |
| `env.DB_USER`                             | | `"etherpad"` |
| `env.DB_PASS.valueFrom.secretKeyRef.name` | | `"moodle"` |
| `env.DB_PASS.valueFrom.secretKeyRef.key`  | | `"etherpad-postgresql-password"` |
| `env.REQUIRE_SESSION`                     | | `"true"` |
| `volumes.name`                            | | `"api-key"` |
| `volumes.name`                            | | `"api-key"` |
| `volumes.secret.secretName`               | | `"moodle"` |
| `volumes.secret.items.key`                | | `"etherpad-api-key"` |
| `volumes.secret.items.path`               | | `"APIKEY.txt"` |
| `volumeMounts.name`                       | | `"api-key"` |
| `volumeMounts.mountPath`                  | | `"api-key"` |
| `volumeMounts.subPath`                    | | `"APIKEY.txt"` |
| `ingress.enabled`                         | | `true `|
| `ingress.annotations`                     | | ` [...] `  |
| `ingress.hosts.host`                      | | `["etherpad.example.de"] `|
| `ingress.paths.path`                      | | `"/"` |
| `ingress.paths.pathType`                  | | `Prefix`|
| `ingress.tls.secretName`                  | | ` ["etherpad.example.de-tls"]`|
| `ingress.tls.hosts`                       | | ` ["etherpad.example.de"]` |
| `resources.requests.cpu`                  | | `"100m"`  |
| `resources.requests.memory`               | | `"128Mi"` |
| `resources.limits.cpu`                    | | `"1000m"` |
| `resources.limits.memory`                 | | `"1Gi"`  |

## Secrets
There is a default secret that will be created with the chart deployment, it covers all necessary secrets that cover all featurs:
values.yaml

```yaml
secrets:
  useChartSecret: true
  moodle_password: "moodle"
  postgres_admin_password: "moodle"
  mariadb_password: "moodle"
  mariadb_root_password: "moodle"
  etherpad_postgresql_password: "moodle"
  etherpad_api_key: "moodle"
```

In case an own secret will be provided and should be used the value "useChartSecret" can be set to "false" and all existingSecret Values need to be set accordingly.
