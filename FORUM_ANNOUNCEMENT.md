# Introducing EFA-NG: Modernizing eFa for Enterprise Linux 10 & Beyond

Hello eFa Community,

For years, **eFa** (Email Filter Appliance) has served as a reliable, powerful open-source email security gateway for thousands of administrators and organizations worldwide. As Linux distributions, PHP engines, and security standards have evolved rapidly, we saw the need to modernize the underlying platform to ensure eFa remains robust, secure, and ready for future production workloads.

Today, we are excited to introduce **EFA-NG** (Email Filter Appliance - Next Generation) — a community-driven continuation and modernization of eFa5, built from the ground up with native support for **CentOS Stream 10 / Enterprise Linux 10** (RHEL 10, AlmaLinux 10, Rocky Linux 10) as well as continued EL9 compatibility.

---

### What is EFA-NG?

**EFA-NG** preserves the proven architectural philosophy and battle-tested components of eFa while thoroughly modernizing the stack: modern compilers (GCC 14), latest scripting runtimes, refreshed WebUI, hardened SELinux policies, and active security maintenance.

Whether you run a standalone gateway or high-volume mail infrastructure, EFA-NG provides a turnkey solution combining Postfix, MailScanner 5, SpamAssassin, ClamAV, MailWatch-NG, and Unbound into a cohesive appliance.

---

### Key Improvements & Highlights

1. **Enterprise Linux 10 (EL10) Native Support**
   - Engineered and packaged specifically for **CentOS Stream 10**, **AlmaLinux 10**, **Rocky Linux 10**, and **RHEL 10**.
   - Built with modern toolchains: GCC 14, Perl 5.38 / 5.40, and strict C99/C23 compiler standards.
   - Clean native **systemd** service units and enforced **SELinux** policies (`Enforcing` mode supported out of the box).

2. **Modern PHP Runtime & Active Security Hardening**
   - Upgraded to modern **PHP 8.4** (and native PHP 8.3 streams) — no deprecated PHP 7.x/8.0 dependencies.
   - Immediate turnaround for critical zero-day vulnerabilities (including PHP2Shell CVE-2026-109618 / CVE-2026-109619).
   - Hardened database queries strictly compliant with modern SQL standards (`ONLY_FULL_GROUP_BY`).
   - Secure LDAP authentication handling with proper filter and DN escaping.

3. **MailWatch-NG: Modernized Web Administration**
   - **Modern Dashboard UI**: Redesigned widget and card-based layout with responsive message statistics and clean queues display.
   - **Advanced Traffic Analytics**: Built-in GeoIP Top Countries and Top TLDs reporting for actionable inbound/outbound threat insights.
   - **Polished Multilingual Support**: Comprehensive translation dictionaries and fail-safe fallback rendering.
   - Fully verified with automated CI test suites (PHPUnit 9.6 and PHPStan level checks).

4. **Updated Security & Filtering Stack**
   - **MTA**: Postfix 3.8+ with modern TLS ciphers and milter relay integration.
   - **Filter Engine**: MailScanner 5 with automated daily/maintenance cron processing and verified phishing rulesets.
   - **Spam Defense**: Apache SpamAssassin 4.0+ integrated with Pyzor, Razor2, and DCC.
   - **Antivirus**: ClamAV 1.4+ with automated daily streaming signatures and `clamav-unofficial-sigs`.
   - **Greylisting & DNS**: SQLgrey policy daemon and Unbound local caching recursive DNS resolver for lightning-fast RBL lookups.
   - **Database**: MariaDB 10.11+ LTS with optimized InnoDB buffers and full `utf8mb4` character set.

5. **Automated One-Liner Installer & Pre-built RPMs**
   - Complete installation automated via a single command:
     ```bash
     curl -sSL https://raw.githubusercontent.com/kit400/EFA-NG/main/build/build.bash | bash
     ```
   - Automated RPM repository with transparent build specs and clean packaging pipeline.

---

### Quick Start: Trying EFA-NG

On a fresh minimal installation of **CentOS Stream 10** (or compatible EL10 / EL9 system), simply run as root:

```bash
curl -sSL https://raw.githubusercontent.com/kit400/EFA-NG/main/build/build.bash | bash
```

Once installed, reboot the server, walk through the first-time setup wizard (`eFa-Init`), and access the modernized MailWatch-NG dashboard at `https://<your-server-ip>/`.

---

### Project Links & Community

We welcome feedback, testing, bug reports, and contributions from all members of the eFa community!

* **Official Website**: [https://efa-ng.space.ua](https://efa-ng.space.ua)
* **Community Forum**: [https://forum.efa-project.org](https://forum.efa-project.org)
* **Telegram Channel**: [https://t.me/EFA_NG](https://t.me/EFA_NG)
* **GitHub (EFA-NG Gateway)**: [https://github.com/kit400/EFA-NG](https://github.com/kit400/EFA-NG)
* **GitHub (MailWatch-NG WebUI)**: [https://github.com/kit400/MailWatch-NG](https://github.com/kit400/MailWatch-NG)

---

*Thank you to the original eFa creators and the community for laying such a solid foundation. We look forward to hearing your thoughts and feedback!*
