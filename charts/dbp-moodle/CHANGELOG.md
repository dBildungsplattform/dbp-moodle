# Changelog

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
