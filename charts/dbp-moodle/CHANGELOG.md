# Changelog

## [1.6.1] - 2026-06-29

### Changed
- **PB-149**: Bump Moodle Version from 4.5.10 to 4.5.12
  - Use new Moodle default Image in Helm CHart Version 1.6.1: 4.5.12-fpm-trixie-8.2.31-dbp1

## [1.6.0] - 2026-06-24

### Changed
- **PB-128**: Update to Debian 13 Trixie
  - Helm Chart GPG Key way of working adjusted
    - Affected Helm value: Values.dbpMoodle.backup.gpg_key_names
      - This value will now be handled in the helpers.tpl to create dbpMoodle.backup.gpg_key_names.cmd which is used during runtime to create the Keys to the key names.
    - Because of the adjustements, the way the GPG Keys are handled were adjusted. If multiple Keys are used, the input in the values.yaml should be a List of Strings like this: "Key1Name, Key2Name"
  - Image Update to increase the debian Version from 12(Bookworm) to 13(Trixie) to ensure continuous security update support.
    - Updated Moodle Image to '4.5.10-fpm-trixie-8.2.31-dbp1'
    - Updated Moodle-Tools Image to '1.1.15'

### Fix
- **DBP-2357**: Add startup probe
    - Larger Instances need more time during the startup, exceeding the delay of the liveness probe
    - This leads to pod terminations and restarts during version updates, which might lead to a corrupted state
    - To prevent this the usage of a startup probe is introduced by default which only terminates the pod after ~20 Minutes
    - If more time is needed this can be adjusted via `.Values.moodle.startupProbe.failureThreshold` and `.Values.moodle.startupProbe.failureThreshold.periodSeconds`

## [1.5.0]
### Feature
- **DM-272**: Support for both oidc and eledia_oidc plugins
    - Added the `.Values.global.noodlePlugins.eledia_oidc` field
    - Set this to enabled if the eledia implementation of oidc should be used (relevant for the ZIT instances)
    - If `.Values.global.noodlePlugins.oidc.enabled` was true prior to this change set it to false and set `eledia_oidc` to true instead.
    - Use `oidc` from now on to use the regular auth_oidc plugin and `eledia_oidc` to use the custom extension by eledia.
    - These plugins should be used mutually exclusive.
    - Updated Moodle Image to '4.5.10-fpm-bookworm-8.2.30-dbp10' containing the plugin

### Fix
- **DBP-2270**: ssl-proxy
    - Added '$CFG->sslproxy = true;' to the php-config
    - This way moodle expects the tls-termination prior to the apache webserver and can handle it properly
    - Solves problems where json responses were wrapped in htlm code due to errors

## [1.4.1]
### Fix
- **PB-70**: Mailserver Configuration
    - Added "smtpExistingSecret" to moodle chart, which allows to set the mail servers secret via an existing secret
    - With `.Values.moodle.smtpExistingSecret` the secret can now be adjusted and if used the `smtp-password` key is expected to hold the password.
    - Use this to setup the smtp server config via IaC in combination with 
      - smtpHost: ""
      - smtpPort: ""
      - smtpUser: ""
      - smtpProtocol: ""

## [1.4.0]

### Feature
- **DBP-2304**: Add Plugin tool_mediatime
  - Added `.Values.global.noodlePlugins.tool_mediatime.enabled`
  - Updated Moodle Image to '4.5.10-fpm-bookworm-8.2.30-dbp9' containing the plugin 

## [1.3.4] - 2026-05-08

### Fixed
- **DBP-2274**: Add default chart values for the etherpad database in the backup-cronjob config.
    - DATABASE_HOST_ETHERPAD, DATABASE_PORT_ETHERPAD, DATABASE_NAME_ETHERPAD, DATABASE_USER_ETHERPAD are all filled via the automatically created etherpad-db-secret and configured via etherpadlite.externalDatabase by default
    - DATABASE_PASSWORD_ETHERPAD references the moodle secret and expects by default an etherpad-postgresql-password key in that secret. If this is not supported in your setup it must be adjusted by overriding the env block with the according values.

### Changed
- Image Update
  - Updated Moodle Image to '4.5.10-fpm-bookworm-8.2.30-dbp8'

## [1.3.3] - 2026-04-14

### Fixed
- **DBP-2263**: Adjusted plugin-list config map to work with empty MOODLE_PLUGINS_SYS_UNINSTALL properly
  - moodle-plugins cm now always contains the key "moodle-plugin-sys-uninstall-list", which is empty if .Values.dbpMoodle.uninstallSystemPlugins is false

## [1.3.2] - 2026-04-14

### Removed

- **DBP-2080**: Removed Support for custom certificates and volume permission adjustments via initContainers
  - Removed `.Values.moodle.certificates` section in `values.yaml` as we dont need custom certificates in the container
  - Removed `.Values.moodle.volumePermissions` section in `values.yaml` as this was implemented by bitnami to Change the owner and group of the persistent volume mountpoint to runAsUser:fsGroup values from the securityContext section in kubernetes settings that had issues with this, which is not the case in our setup.
  - Both setups required an initContainer which used bitnamis os-shell container, to reduce bitnami dependencies and unused code this was removed entirely
- **DBP-2264**: Removed Support for secretFiles
  - Removed `.Values.moodle.usePasswordFiles` and all the according implementations.

### Changed
- 
  - Updated Moodle Image to '4.5.10-fpm-bookworm-8.2.30-dbp6'

## [1.3.1] - 2026-04-02

### Changed

- **DBP-2221**: 
  - Updated Moodle Image to '4.5.10-fpm-bookworm-8.2.30-dbp4'

## [1.3.0] - 2026-03-27

### Added

- **DBP-1988**: Added support for deploying [goemaxima](https://github.com/mathinstitut/goemaxima) - a Maxima CAS web interface
  - Added `dbpMoodle.goemaxima` section in `values.yaml` with image, replicaCount, service, resources, env, and security context configuration
  - Added deployment and service templates for goemaxima
  - Added Helm value `dbpMoodle.goemaxima.enabled` to control deployment

### Changed

- Updated README.md via helm-docs


## [1.2.2] - 2026-03-12

### Fixed

- **DBP-2081**: Corrected behavior path mappings for `dfexplicitvaildate` and `dfcbmexplicitvaildate` plugins in `_helpers.tpl`

### Changed

- Bumped chart version to 1.2.2
