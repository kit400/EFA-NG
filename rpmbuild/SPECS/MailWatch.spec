#-----------------------------------------------------------------------------#
# eFa SPEC file definition
#-----------------------------------------------------------------------------#
# Copyright (C) 2013~2023 https://efa-project.org
#
# This SPEC is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This SPEC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this SPEC. If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------#

%undefine _disable_source_fetch

#-----------------------------------------------------------------------------#
# Required packages for building this RPM
#-----------------------------------------------------------------------------#
# yum -y install 
#-----------------------------------------------------------------------------#
Summary:       MailWatch Web Front-End for MailScanner (EFA-NG Fork)
Name:          MailWatch
Version:       6.0.6
Epoch:         1
Release:       18.eFa%{?dist}
License:       GNU GPL v2
Group:         Applications/Utilities
URL:           https://github.com/kit400/MailWatch-NG
Source0:       MailWatch-%{version}.tar.gz
BuildRoot:     %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch:     noarch
AutoReqProv:   no

%description
MailWatch for MailScanner is a web-based front-end to MailScanner written in
PHP and MySQL. This is the EFA-NG modernized fork maintained for CentOS Stream 10 / EL10
with integrated eFa branding, relay services, and enhanced session handling.
Official Project Portal: https://efa-ng.space.ua
Official Telegram Support: https://t.me/EFA_NG

%prep
%setup -q -n %{name}-NG-%{version}

%build
# Nothing to do

%install
%{__rm} -rf %{buildroot}

# Remove any .gitignore files, if present
find . -name ".gitignore" | xargs rm -f

# Copy files to proper locations
mkdir -p %{buildroot}%{_datarootdir}/MailScanner/perl/custom
cp MailScanner_perl_scripts/MailWatch.pm %{buildroot}%{_datarootdir}/MailScanner/perl/custom
cp MailScanner_perl_scripts/SQLBlackWhiteList.pm %{buildroot}%{_datarootdir}/MailScanner/perl/custom
cp MailScanner_perl_scripts/SQLSpamSettings.pm %{buildroot}%{_datarootdir}/MailScanner/perl/custom
cp MailScanner_perl_scripts/MailWatchConf.pm %{buildroot}%{_datarootdir}/MailScanner/perl/custom

mkdir -p %{buildroot}/%{_bindir}/mailwatch
cp -a tools %{buildroot}%{_bindir}/mailwatch
cp upgrade.php %{buildroot}/%{_bindir}/mailwatch/tools
[ -f mailscanner/tools/update_geoip.php ] && cp mailscanner/tools/update_geoip.php %{buildroot}/%{_bindir}/mailwatch/tools/
chmod 0755 %{buildroot}%{_bindir}/mailwatch/tools/mailwatch_replay_failed_events.php 2>/dev/null || true
rm -f %{buildroot}%{_bindir}/mailwatch/tools/Cron_jobs/INSTALL

mkdir -p %{buildroot}%{_localstatedir}/spool/mailwatch/failed_events

mkdir -p %{buildroot}%{_sysconfdir}/cron.daily
install -m 0755 cron/mailwatch.cron.daily %{buildroot}%{_sysconfdir}/cron.daily/mailwatch

mkdir -p %{buildroot}%{_sysconfdir}/cron.monthly
install -m 0755 cron/mailwatch.cron.monthly %{buildroot}%{_sysconfdir}/cron.monthly/mailwatch

mkdir -p %{buildroot}%{_sysconfdir}/cron.d
install -m 0644 cron/msre_reload.cron %{buildroot}%{_sysconfdir}/cron.d/msre_reload

mkdir -p %{buildroot}%{_unitdir}
install -m 0644 systemd/postfix_relay.service %{buildroot}%{_unitdir}/postfix_relay.service
install -m 0644 systemd/milter_relay.service %{buildroot}%{_unitdir}/milter_relay.service

mkdir -p %{buildroot}%{_localstatedir}/www/html
cp -a mailscanner %{buildroot}%{_localstatedir}/www/html/mailscanner
mv %{buildroot}%{_localstatedir}/www/html/mailscanner/conf.php.example %{buildroot}%{_localstatedir}/www/html/mailscanner/conf.php
rm -rf %{buildroot}%{_localstatedir}/www/html/mailscanner/docs

# Install Apache security configuration
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
install -m 0644 conf/mailwatch.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/mailwatch.conf

# Create runtime cache directories outside document root
mkdir -p %{buildroot}%{_localstatedir}/cache/mailwatch/dash_cache

# Copy favicon to document root
cp -f %{buildroot}%{_localstatedir}/www/html/mailscanner/favicon.ico %{buildroot}%{_localstatedir}/www/html/favicon.ico

%pre
# Nothing to do

%post
# Permissions
chgrp apache %{_localstatedir}/www/html/mailscanner/images 2>/dev/null || true
chgrp apache %{_localstatedir}/www/html/mailscanner/temp 2>/dev/null || true
chmod 0775 %{_localstatedir}/www/html/mailscanner/images 2>/dev/null || true
chmod 0775 %{_localstatedir}/www/html/mailscanner/temp 2>/dev/null || true

# Set permissions and SELinux context for cache directory outside document root (MW-05)
mkdir -p %{_localstatedir}/cache/mailwatch/dash_cache 2>/dev/null || true
chown -R apache:apache %{_localstatedir}/cache/mailwatch 2>/dev/null || true
chmod 0770 %{_localstatedir}/cache/mailwatch %{_localstatedir}/cache/mailwatch/dash_cache 2>/dev/null || true
semanage fcontext -a -t httpd_cache_t "%{_localstatedir}/cache/mailwatch(/.*)?" 2>/dev/null || true
restorecon -R %{_localstatedir}/cache/mailwatch 2>/dev/null || true

# Set permissions and SELinux context for failed events spool directory (MW-10)
mkdir -p %{_localstatedir}/spool/mailwatch/failed_events 2>/dev/null || true
chown -R postfix:mtagroup %{_localstatedir}/spool/mailwatch 2>/dev/null || true
chmod 0775 %{_localstatedir}/spool/mailwatch %{_localstatedir}/spool/mailwatch/failed_events 2>/dev/null || true
semanage fcontext -a -t mscan_spool_t "%{_localstatedir}/spool/mailwatch(/.*)?" 2>/dev/null || true
restorecon -R %{_localstatedir}/spool/mailwatch 2>/dev/null || true

# Clean up legacy cache files from document root
rm -rf %{_localstatedir}/www/html/mailscanner/temp/dash_cache 2>/dev/null || true
rm -f %{_localstatedir}/www/html/mailscanner/temp/dash_dns_cache.json 2>/dev/null || true
rm -f %{_localstatedir}/www/html/mailscanner/temp/version_check_cache.json 2>/dev/null || true

# Reload web server and php-fpm to apply configuration
systemctl reload httpd 2>/dev/null || true
systemctl reload php-fpm 2>/dev/null || true

# Check and initialize GeoIP database if missing or outdated (< 10MB)
if [ ! -f %{_localstatedir}/www/html/mailscanner/temp/ip-geo.mmdb ] || [ $(stat -c%s %{_localstatedir}/www/html/mailscanner/temp/ip-geo.mmdb 2>/dev/null || echo 0) -lt 10000000 ]; then
    /usr/bin/php %{_localstatedir}/www/html/mailscanner/tools/update_geoip.php >/dev/null 2>&1 || true
fi

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root)
%doc CHANGELOG.md CONTRIBUTING.md LICENSE.md README.md
%attr(0755, root, root) %{_bindir}/mailwatch/tools/Cron_jobs/*
%attr(0644, root, root) %{_sysconfdir}/cron.d/msre_reload
%attr(0755, root, root) %{_sysconfdir}/cron.daily/mailwatch
%attr(0755, root, root) %{_sysconfdir}/cron.monthly/mailwatch
%attr(0644, root, root) %{_unitdir}/postfix_relay.service
%attr(0644, root, root) %{_unitdir}/milter_relay.service
%{_datarootdir}/MailScanner/perl/custom/MailWatchConf.pm
%{_datarootdir}/MailScanner/perl/custom/MailWatch.pm
%{_datarootdir}/MailScanner/perl/custom/SQLBlackWhiteList.pm
%{_datarootdir}/MailScanner/perl/custom/SQLSpamSettings.pm
%{_bindir}/mailwatch/tools/MailScanner_rule_editor/msre_reload.crontab
%{_bindir}/mailwatch/tools/MailScanner_rule_editor/INSTALL
%attr(0755, root, root) %{_bindir}/mailwatch/tools/MailScanner_rule_editor/msre_reload.sh
%{_bindir}/mailwatch/tools/Postfix_relay/*
%{_bindir}/mailwatch/tools/Sendmail-Exim_queue/*
%{_bindir}/mailwatch/tools/Sendmail_relay/*
%{_bindir}/mailwatch/tools/LDAP/*
%{_bindir}/mailwatch/tools/sudo/*
%{_bindir}/mailwatch/tools/MailScanner_config/*
%attr(0755, root, root) %{_bindir}/mailwatch/tools/upgrade.php
%attr(0755, root, root) %{_bindir}/mailwatch/tools/update_geoip.php
%attr(0755, root, root) %{_bindir}/mailwatch/tools/mailwatch_replay_failed_events.php
%config(noreplace) %{_sysconfdir}/httpd/conf.d/mailwatch.conf
%dir %attr(0770, apache, apache) %{_localstatedir}/cache/mailwatch
%dir %attr(0770, apache, apache) %{_localstatedir}/cache/mailwatch/dash_cache
%dir %attr(0775, postfix, mtagroup) %{_localstatedir}/spool/mailwatch
%dir %attr(0775, postfix, mtagroup) %{_localstatedir}/spool/mailwatch/failed_events
%config(noreplace) %{_localstatedir}/www/html/mailscanner/conf.php
%{_localstatedir}/www/html/favicon.ico
%{_localstatedir}/www/html/mailscanner

%changelog
* Fri Sep 11 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-18
- Fix MW-10: Support message envelope format and dual reports key in failed events replay utility

* Fri Sep 11 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-17
- Fix MW-10 (P2): Permanent database error on a single event can block SQL logger child indefinitely
- Classify database errors into transient vs permanent with bounded retries and exponential backoff
- Sanitize 4-byte UTF-8 sequences and divert unrecoverable errors to dead-letter queue (/var/spool/mailwatch/failed_events)
- Add failed events replay CLI tool (tools/mailwatch_replay_failed_events.php)
- Migrate create.sql and user_dashboards schema definitions to native utf8mb4 and utf8mb4_unicode_ci

* Fri Sep 11 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-16
- Fix MW-09 (P2): mtalog cleanup infinite loop on NULL msg_id and unintended deletion of fresh records
- Introduce cleanMtalogWithIds selecting and deleting by primary key mtalog_id with strict timestamp boundary
- Safely handle NULL msg_id values without infinite looping; preserve active mtalog_ids mappings when msg_id is still referenced
- Add iteration progress check breaking on zero progress, and add comprehensive MW-09 regression tests

* Fri Sep 11 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-15
- Fix MW-08 (P2): Batch database cleanup stops after first DELETE due to invalid affected_rows inspection on boolean result
- Separate database query (dbquery) and execution (dbexecute) interfaces returning affected_rows
- Immediately read affected_rows from dbconn connection after DELETE statements
- Handle database errors gracefully without infinite loops or uncaught exceptions
- Add execution budget controls (DB_CLEAN_MAX_EXECUTION_TIME, DB_CLEAN_MAX_BATCHES, DB_CLEAN_SLEEP_MS)
- Add automated regression test suite for MW-08

* Fri Sep 11 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-14
- Fix MW-05 (P1): Isolate private HTML cache outside document root and enforce web server denial
- Relocate dashboard widget cache and DNS cache from temp/ to /var/cache/mailwatch
- Install Apache mailwatch.conf denying direct HTTP access to temp/, lib/, and tools/ directories
- Add temp/.htaccess and index.php fallback returning 403 Forbidden
- Add active TTL purge and immediate user-specific cache invalidation on logout
- Add daily cron cache purge retention policy for files older than 1 day
- Add automated regression test suite for MW-05

* Thu Sep 10 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-13
- Fix MW-04 (P1): Decouple session timeout and privilege change checks from HTML rendering
- Introduce centralized SessionGuard for unified session authentication, expiry, revocation, and role enforcement
- Enforce session checks in login.function.php across all entry points before any output or side effects occur
- Return HTTP 401 Unauthorized for unauthenticated or expired AJAX, JSON, and non-HTML requests
- Add automated regression test suite for MW-04 verifying session lifecycle, privilege consistency, and endpoint responses

* Thu Sep 10 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-12
- Fix MW-03 (P1): Escape SQL LIKE pattern wildcards in address access filters
- Escape '_' and '%' characters in user and domain addresses with ESCAPE '='
- Prevent unauthorized wildcard access expansion to similarly named recipient addresses
- Ensure fail-closed default for empty address filters and uninitialized global_filter sessions
- Add comprehensive regression test suite covering wildcard, quote, and multi-recipient positions

* Thu Sep 10 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-11
- Fix MW-02 (P1): Enforce server-side MessagePolicy for quarantine operations
- Restrict dangerous content viewing and releasing based on user role and configuration
- Strictly prohibit regular users from redirecting quarantined messages to alternate recipients
- Enforce MessagePolicy in quarantine_release, quarantine_learn, quarantine_delete, and viewmail/viewpart
- Log security violation audit events when policy checks fail

* Thu Sep 10 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-10
- Fix MW-01 (P1): Sanitize HTML email rendering using HTMLPurifier allowlist engine
- Isolate email viewer iframe with sandbox="allow-same-origin allow-popups"
- Add strict Content-Security-Policy and X-Content-Type-Options headers to viewpart.php
- Sanitize attachment filenames against CRLF injection and path traversal
- Neutralize active content and force attachment disposition for downloaded parts

* Wed Sep 09 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-9
- Add CSV export functionality to all report tables under charts (TLD, Countries, Total Mail, etc.)
- Add tableExport.js utility with UTF-8 BOM support and auto-alignment

* Wed Sep 09 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.6-8
- Fix missing translation keys and allow fallback values in __()


* Thu Aug 27 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 6.0.4-1
- Release MailWatch-NG 6.0.4 for EL10 / CentOS Stream 10
- Dynamic widget dashboard, memory/swap metrics, SVG country flags, isolated toolbar buttons
- Add interactive customizable dashboard engine with 11 dynamic widgets, drag-and-drop, and auto-refresh
- Migrate GeoIP to strato-do/ip-geo with AS/ASN tracking and ipinfo.io integration
- Smart threat signature shortening and hover popups
- Add active Swap memory metrics and fix detail.php token timeouts and msgid validation

* Fri Aug 21 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-15
- Display software versions in structured 2-column table with linked component names

* Fri Aug 21 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-14
- Compact colorcodes legend, increase ul/ol/li font to 13px, show full version with link in footer and sf_version

* Fri Aug 21 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-13
- Restore mw-icon and mw-info-circle styles for detail link in message tables

* Fri Aug 21 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-12
- Add modern list styles for ul/ol/li with 11px font size matching widget headers

* Fri Aug 21 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-11
- Modernize all tables, forms, and pages across the web interface in clean card UI

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-10
- Make user block 10% wider, totals block 10% narrower, remove icon from Logout button

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-9
- Change header to Disk Space & Queues, shorten In/Out labels, reduce storage block width by 20%

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-8
- Shorten High Score Spam to High Spam and reduce Today's Totals card width by 20%

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-7
- Split Status widget into Services and Storage cards, compact logo & user cabinet, and align all header widgets in a single equal-height row

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-6
- Add DISKS_TO_SHOW configuration setting to filter Free Disk Space widget (default: root partition '/')

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-5
- Modernize all header widgets (Status, Traffic Graph, Today Totals, Jump box) in unified card style

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-4
- Refine translation keys and styling for User Cabinet widget

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-3
- Switch main navigation bar to Modern Light theme
- Move user language selection and logout to the User Cabinet widget

* Thu Aug 20 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-2
- Modernize main navigation menu (Variant 1: modern compact dark flexbox bar with icons)
- Remove horizontal scroll issues and eliminate fixed 1375px min-width

* Wed Aug 19 2026 kit <kit@EFA-NG-Dev.ukrpack.net> - 1.2.27-1
- Update MailWatch to upstream version 1.2.27
- Preserve all eFa branding, relay services, and database integration

* Sat Jul 27 2024 Shawn Iverson <shawniverson@efa-project.org> - 1.2.23-4
- Bump release

* Fri Jul 26 2024 Shawn Iverson <shawniverson@efa-project.org> - 1.2.23-3
- Don't suppress errors from mailwatch_db_clean.php

* Sun Jun 09 2024 Shawn Iverson <shawniverson@efa-project.org> - 1.2.23-2
- Additional cleanup for mtalog_ids

* Tue Mar 07 2023 Shawn Iverson <shawniverson@efa-project.org> - 1.2.20-1
- version 1.2.20

* Sun Nov 21 2021 Shawn Iverson <shawniverson@efa-project.org> - 1.2.18-5
- More relay fixes

* Sun Nov 21 2021 Shawn Iverson <shawniverson@efa-project.org> - 1.2.18-4
- Relay fixes

* Tue Nov 16 2021 Shawn Iverson <shawniverson@efa-project.org> - 1.2.18-3
- Reapply Unfold message-id field for MailWatch Logger

* Sun Nov 14 2021 Shawn Iverson <shawniverson@efa-project.org> - 1.2.18-2
- Unfold message-id field for MailWatch Logger

* Sun Nov 14 2021 Shawn Iverson <shawniverson@efa-project.org> - 1.2.18-1
- Update to v1.2.18 with cherry picked pending fixes

* Tue Jan 05 2021 Tobias Perschon <tobias@perschon.at> - 1.2.17-1
- Update to v1.2.17

* Tue Jan 05 2021 Shawn Iverson <shawniverson@efa-project.org> - 1.2.16-1
- Update to v1.2.16

* Sat May 03 2020 Shawn Iverson <shawniverson@efa-project.org> - 1.2.15-3
- Additional minor fixes for HTML Purifier and report handling

* Tue Mar 24 2020 Shawn Iverson <shawniverson@efa-project.org> - 1.2.15-2
- Fix single quote handling in mailwatch_milter_relay

* Sat Feb 08 2020 Shawn Iverson <shawniverson@efa-project.org> - 1.2.15-1
- Include spanish translation updates

* Fri Dec 27 2019 Shawn Iverson <shawniverson@efa-project.org> - 1.2.14-1
- Update MailWatch for MaxMind License Key Support

* Tue Jan 29 2019 Shawn Iverson <shawniverson@efa-project.org> - 1.2.12-8
- Minor spacing fix

* Tue Jan 29 2019 Shawn Iverson <shawniverson@efa-project.org> - 1.2.12-7
- Switch group for temp and images to php-fpm

* Sun Jan 27 2019 Shawn Iverson <shawniverson@efa-project.org> - 1.2.12-6
- Modify sf_version.php to show postfix version

* Wed Jan 23 2019 Shawn Iverson <shawniverson@efa-project.org> - 1.2.12-5
- Refactor package to handle its own files and leave config to eFa

* Mon Jan 21 2019 Shawn Iverson <shawniverson@efa-project.org> - 1.2.12-4
- Fix mailwatch_relay.sh returning true to cron

* Mon Dec 24 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.12-2
- Remove msre_reload.sh and update

* Mon Dec 24 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.12-1
- Update to MailWatch 1.2.12

* Sat Oct 20 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.10-1
- Update to MailWatch 1.2.10

* Sun Jul 8 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.9-1
- Update to MailWatch 1.2.9 and fix case

* Sat May 26 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.7-7
- Updated to use IUS repository for dependencies

* Sat Jan 27 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.7-6
- Repackage to include mailwatch_update_sarules.php and forked ps fix

* Mon Jan 15 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.7-5
- Add php-xml as a requirement

* Mon Jan 15 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.7-4
- Update version requirements

* Sun Jan 14 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.7-3
- Fix paths for postfix relay scripts

* Sun Jan 14 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.7-2
- Fix msre_reload.sh and include msre_reload crontab

* Sat Jan 13 2018 Shawn Iverson <shawniverson@efa-project.org> - 1.2.7-1
- MailWatch Update

* Sun Mar 19 2017 Shawn Iverson <shawniverson@gmail.com> - 1.2.0-4
- Mailwatch Update

* Sun Feb 12 2017 Shawn Iverson <shawniverson@gmail.com> - 1.2.0-3
- Correct permissions on images

* Sun Feb 12 2017 Shawn Iverson <shawniverson@gmail.com> - 1.2.0-2
- Correct permissions on temp

* Sat Jan 21 2017 Shawn Iverson <shawniverson@gmail.com> - 1.2.0-1
- Initial Build for eFa https://efa-project.org
