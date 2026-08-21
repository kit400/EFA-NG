# Changelog

All notable changes to the EFA-NG (Email Filter Appliance - Next Generation) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [6.0.0] - 2026-08-21

### Added
- **CentOS Stream 10 & Enterprise Linux 10 Support**: Full native support for the Enterprise Linux 10 ecosystem (CentOS Stream 10, RHEL 10, AlmaLinux 10, Rocky Linux 10) leveraging GCC 14, modern RPM 4.20, and Linux kernel 6.12+.
- **MailScanner 5.5.3-2**: Upgraded multi-threaded scanning pipeline with high-throughput multi-engine processing and updated virus database autoupdaters (`f-prot-6-autoupdate`, `kse-autoupdate`, `freshclam`).
- **MailWatch-NG Fork (1.2.27-efa1)**: Deep integration of quarantine and management web console [`kit400/MailWatch-NG`](https://github.com/kit400/MailWatch-NG) with native support for PHP 8.3, relay services (`postfix_relay`, `milter_relay`), greylisting management, and Perl integration modules.
- **SELinux Hardening (`eFa10.te`)**: Modernized security policy profile tailored for EL10 with strict confinement and dedicated capabilities for `greylist_milter_t` and `httpd_sys_script_t`.
- **Unified Web Portal & Community Forum**: New community web portal running on PHP 8.3 with single sign-on (SSO), comprehensive documentation knowledge base, and integrated community support forum powered by Flarum.

### Changed
- **Postfix LMDB Migration**: Migrated all routing and lookup tables (`transport`, `virtual`, `helo_access`, `sender_access`, `recipient_access`, `sender_canonical`, `recipient_canonical`, `aliases`) and TLS session caches from deprecated Berkeley DB (`hash:`, `btree:`) to high-performance LMDB (`lmdb:`).
- **Session & Performance Tuning**: Modernized session lifetimes across web management tools, optimized queue spools permissions (`mtagroup`), and refreshed systemd services (`sqlgrey.service`, `msmilter.service`).

---

## [5.0.0-12] - 2026-08-19

### Added
- **CentOS Stream 10 / EL10 Support**: Full support for building and running on Enterprise Linux 10 with GCC 14, modern RPM 4.20, and Linux kernel 6.12+.
- **MailScanner 5.5.3-2**: Upgraded MailScanner to the latest upstream release (5.5.3-2) with updated antivirus definitions autoupdaters (`f-prot-6-autoupdate`, `kse-autoupdate`).
- **MailWatch-NG Fork (1.2.27-efa1)**: Created dedicated fork repository [`kit400/MailWatch-NG`](https://github.com/kit400/MailWatch-NG) natively incorporating all eFa branding, relay services (`postfix_relay`, `milter_relay`), Greylisting navigation, and Perl integration modules (`MailWatchConf.pm`), replacing brittle spec-level sed patches.
- **SELinux Module (`eFa10.te`)**: Created EL10 SELinux module tailored for modern distributions (removed obsolete `ntpd_t`, granted proper runtime directory permissions for `greylist_milter_t` and `httpd_sys_script_t`).

### Changed
- **Postfix LMDB Migration**: Switched all Postfix lookup tables (`transport`, `virtual`, `helo_access`, `sender_access`, `recipient_access`, `sender_canonical`, `recipient_canonical`, `aliases`) and TLS session caches from deprecated Berkeley DB (`hash:`, `btree:`) to high-performance `lmdb:`.
- **MailWatch & PHP Session Timeout**: Configured global `SESSION_TIMEOUT` in MailWatch and PHP session parameters (`session.gc_maxlifetime`, `session.cookie_lifetime`) to 3 days (259,200 seconds) and removed the legacy 99,999-second upper bound.
- **Group & Spool Permissions**: Added user `postfix` to `mtagroup` and set `0775` permissions on MailScanner queue spools (`milterin`, `milterout`, `quarantine`, `incoming`) to ensure reliable end-of-data milter transactions.
- **Systemd Unit Modernization**:
  - `sqlgrey.service`: Configured `User=sqlgrey`, `Group=sqlgrey`, and `RuntimeDirectory=sqlgrey` so runtime PID files are managed and cleaned up without permission issues.
  - `msmilter.service`: Updated startup dependencies and permissions.

### Fixed
- **eFaInit Web Wizard**:
  - Netmask Validator: Added support for dotted-decimal netmasks (e.g. `255.255.255.224`) alongside CIDR prefix lengths.
  - CLI Username Validator: Replaced brittle `sudo cat /etc/passwd` process spawning with native PHP user lookups and system account collision guards.
  - MariaDB Initialization (`configuredo1`): Made database creation, table migrations, and SQL user grants fully idempotent for MariaDB 10.11+.
  - Razor Registration (`configuredo7`): Added error handling and timeouts around `razor-admin` Cloudmark registration.
  - Cyrus SASL Configuration (`configuredo12`): Unified `/etc/sasldb2` and `/etc/sasl2/sasldb2` paths.
  - SSH Hostkey Generation: Removed obsolete DSA key generation for modern OpenSSH.

---

## [5.0.0-11] - 2024-07-27
### Fixed
- Quoting for `MailWatchConf.pm` configuration.

## [5.0.0-10] - 2024-07-26
### Added
- Cron task `checkqueues` for automated queue permissions recovery.

## [5.0.0-9] - 2024-07-20
### Fixed
- Migration scripts to facilitate upgrades from eFa v4 appliances.

## [5.0.0-8] - 2024-06-11
### Fixed
- `MailWatchConf.pm` configuration updates during system upgrades.

## [5.0.0-7] - 2024-06-09
### Changed
- Updated MailWatch and improved MariaDB recovery procedures.

## [5.0.0-6] - 2024-05-12
### Added
- Certbot dependency for automated SSL certificate management.
- Enabled FreshClam antivirus database updater by default.

## [5.0.0-5] - 2024-04-13
### Fixed
- OpenDKIM and OpenDMARC socket configurations.
- Upgraded SpamAssassin to 4.0.1.

## [5.0.0-4] - 2024-04-06
### Changed
- Updated MailScanner and MailWatch.
- Switched network management stack to NetworkManager.
