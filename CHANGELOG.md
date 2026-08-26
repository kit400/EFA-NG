# Changelog

All notable changes to the EFA-NG (Email Filter Appliance - Next Generation) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [6.0.3] - 2026-08-26

### Added
- **Interactive Customizable Dashboard Engine (`dashboard.php`, `dashboard.inc.php`)**:
  - Full-featured, responsive 12-column widget dashboard grid with intuitive HTML5 drag-and-drop reordering.
  - Per-user dashboard layout customization saved directly to database (`user_dashboards`).
  - Dynamic widget sizing options (25%, 33%, 50%, 66%, 100% column widths).
  - Add Widget catalog modal supporting 11 dynamic widgets: KPI Overview, 24h Traffic Trends, Security Threat Donut, Top Relay Countries & AS/ASN, Top Senders & Recipients, Recent Intercepted Threats, Recent Processed Messages, Core System Services & Memory/Swap, Top SpamAssassin Rules, Quarantine Health, and Quick Admin Actions.
  - Dynamic auto-refresh with configurable intervals (Off, 30s, 60s, 120s, 300s, default 60s), live countdown indicator, smooth opacity fade transitions, and calm refresh animations.
  - Integrated default system dashboard with comprehensive monitoring.
- **`strato-do/ip-geo` Integration & Autonomous System (AS / ASN) Tracking**:
  - Replaced legacy MaxMind GeoIP with modern open-source `strato-do/ip-geo` database providing countries, cities, and Autonomous System details.
  - Added clickable ASN badges linking directly to `https://ipinfo.io/AS<number>` across message details, reports, and top relay widgets.
  - Zero-credential 1-click database updates in `geoip_update.php` and automated CLI cron `update_geoip.php`.
- **Intelligent Threat Signature Formatting & Hover Tooltips**:
  - Smart shortening of long virus strings (e.g. `Virus (ClamAV (Eicar-Test-Signature / Win32.Trojan.Gen-8912))` shortened to `Virus (Eicar-Test-Signature)`).
  - Modern CSS hover popups displaying the complete scanner signature and engine report upon cursor hover.
- **Enhanced System Services & Memory Monitoring**:
  - Added active Swap memory usage tracking and progress bars (`used / total (pct%)`) in System Health.
  - Clarified embedded MailScanner SpamAssassin engine status (`● ACTIVE`).

### Fixed
- **Message Detail Navigation (`detail.php`)**: Fixed session token validation so direct GET navigation from dashboards and reports does not trigger false timeout logouts.
- **Message ID Validation**: Expanded `validateInput(..., 'msgid')` in `functions.php` to accept modern MTA and Postfix long queue ID formats.
- **Relay Drilldown Filtering**: Fixed `rep_message_listing.php?relay=...` drilldowns to match both `clientip` and message header IP records.

---

## [6.0.2] - 2026-08-24

### Added
- **Interactive Monthly Quarantine Calendar (`quarantine.php`)**:
  - Replaced legacy text date list with a modern interactive 7-day monthly calendar grid with month navigation (`◀`, `Today`, `▶`).
  - Monthly KPI overview bar (Total Quarantined, Viruses, Spam, Policy/MCP).
  - Date cells featuring quarantine count badges (`🔒 count ›`) and categorized threat sub-tags (`🦠`, `⚡`, `🛡️`).
  - Seamless date drilldown displaying the full message operations table directly below the calendar.
- **Next-Gen Apache ECharts Integration**:
  - Migrated charting engine to high-performance Apache ECharts with modern design inspired by `ip.space.ua`.
  - Dual Y-Axis architecture in `js/lineConfig.js` enabling simultaneous display of message counts (0..500) and traffic volume (0..100MB) without scale distortion.
  - Interactive crosshairs, formatted tooltips with human-readable byte conversion, and responsive auto-resize listeners.
- **Kit4Mail-Inspired Accordion Dropdown Reports Sidebar**:
  - Multi-level dropdown navigation across all `rep_*.php` pages with category badges and animated chevron transitions.
  - Ultra-compact 36px Mini Rail with 100% distinct, unique icons for every category (`🗂️`, `📈`, `🌐`, `👥`, `🛡️`, `📜`, `🔍`, `🕒`).
  - Hover-to-expand overlay mode when sidebar is minimized.
- **Table Column Sorting & Pager Enhancements**:
  - Enabled click-to-sort column headers with directional arrows (`▲`, `▼`, `↕`), removing legacy `A`/`D` letters.
  - Resolved table DOM nesting issue in `generatePager()` and `dbtable()` to keep message tables cleanly inside the flex layout.

### Fixed
- **Localization**: Added missing English translation keys for reports categories, filter builders, and message operations.
- **Traffic Graph Container**: Fixed height and responsive resizing for `#trafficgraph` in top header bar.

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
