# EFA-NG: Email Filter Appliance (Next Generation)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform: CentOS Stream 10 / EL10](https://img.shields.io/badge/Platform-CentOS%20Stream%2010%20%7C%20EL10-red.svg)](https://centos.org)
[![Repository](https://img.shields.io/badge/GitHub-kit400%2FEFA--NG-green.svg)](https://github.com/kit400/EFA-NG)
[![Telegram Channel](https://img.shields.io/badge/Telegram-Official%20Channel-24A1DE.svg?logo=telegram&logoColor=white)](https://t.me/EFA_NG)

**EFA-NG** (Email Filter Appliance - Next Generation) is a modern, high-performance, open-source email security gateway designed to protect mail infrastructures against spam, phishing, malware, and viruses.

Forked and modernized from eFa5, **EFA-NG** is re-engineered with full support for **CentOS Stream 10** (and the Enterprise Linux 10 ecosystem: RHEL 10, AlmaLinux 10, Rocky Linux 10), leveraging native **PHP 8.3**, **Perl 5.38/5.40**, **ClamAV 1.4+**, **SpamAssassin 4.0+**, **MariaDB 10.11+**, and strict **SELinux** security policies.

---

## Quick Installation

On a fresh minimal installation of **CentOS Stream 10** (or compatible EL10 / EL9 system), run the following command as `root` (or via `sudo`):

```bash
curl -sSL https://raw.githubusercontent.com/kit400/EFA-NG/main/build/build.bash | bash
```

### Installation Options

You can pass an optional argument to the installation script:

| Mode | Command | Description |
| :--- | :--- | :--- |
| **Production** *(default)* | `curl -sSL https://raw.githubusercontent.com/kit400/EFA-NG/main/build/build.bash \| bash` | Standard production deployment with release repository |
| **Testing** | `curl -sSL https://raw.githubusercontent.com/kit400/EFA-NG/main/build/build.bash \| bash -s -- testing` | Deployment utilizing the testing repository |
| **Development** | `curl -sSL https://raw.githubusercontent.com/kit400/EFA-NG/main/build/build.bash \| bash -s -- dev` | Deployment utilizing dev builds and tooling |
| **Kickstart / Automated** | `... \| bash -s -- ksproduction` | Headless kickstart installation with automated root credential setup |

---

## Core Architecture & Components

EFA-NG unifies best-of-breed open-source security technologies into a cohesive, managed email filtering gateway:

- **MTA (Mail Transfer Agent)**: [Postfix](http://www.postfix.org/) with milter integration and SASL/TLS support.
- **Mail Filter Engine**: [MailScanner 5](https://www.mailscanner.info/) for high-throughput multi-engine scanning.
- **Antivirus**: [ClamAV](https://www.clamav.net/) 1.4+ with automated signature streaming and `clamav-unofficial-sigs` (SaneSecurity, Foxhole, etc.).
- **Antispam**: [Apache SpamAssassin](https://spamassassin.apache.org/) 4.0+ with Pyzor, Razor2, and DCC (Distributed Checksum Clearinghouse).
- **Web Management & Quarantine**: [MailWatch](https://github.com/mailwatch/MailWatch) adapted for PHP 8.3, featuring message quarantine, release/learn tokens, audit trails, and reporting.
- **Greylisting**: [SQLgrey](http://sqlgrey.sourceforge.net/) with SQLgrey Web Interface (SGWI).
- **DNS Caching & Resolver**: [Unbound](https://nlnetlabs.nl/projects/unbound/about/) caching recursive DNS resolver for high-speed RBL queries.
- **Authentication & Validation**: [OpenDKIM](http://www.opendkim.org/) and [OpenDMARC](http://www.trusteddomain.org/opendmarc/) for domain authentication and spoofing prevention.
- **Intrusion Prevention**: [Fail2ban](https://www.fail2ban.org/) with hardened jails for SSH, Postfix-SASL, and MailWatch UI.
- **Database Engine**: [MariaDB](https://mariadb.org/) 10.11+ LTS with optimized InnoDB buffers and UTF8MB4 charset.

---

## System Requirements

- **Operating System**: CentOS Stream 10 (recommended), RHEL 10, AlmaLinux 10, Rocky Linux 10, or CentOS Stream 9.
- **CPU**: Minimum 2 vCPUs (4+ vCPUs recommended for production environments).
- **Memory**: Minimum 4 GB RAM (8+ GB RAM recommended for multi-engine AV/AS processing).
- **Storage**: 20 GB+ free disk space (SSD recommended for mail queue and MariaDB).
- **Network**: Static IPv4 / IPv6 configuration with properly configured Reverse DNS (PTR).

---

## Post-Installation & Initial Configuration

1. **Reboot the system** after the installation script finishes:
   ```bash
   reboot
   ```
2. **First Login Setup Wizard**:
   - Log in to the console as `root`.
   - The initial configuration wizard (`eFa-Init`) will start automatically to guide you through hostname, network, TLS certificate, and administrator password configuration.
   - You can also invoke the configuration utility anytime via:
     ```bash
     eFa-Configure
     ```
3. **Web Administration Interface**:
   - Navigate to `https://<your-server-ip>/` in your browser.
   - Log in using your configured administrative credentials to manage quarantined messages, domain transport maps, whitelist/blacklist rules, and view real-time traffic statistics.

---

## Repository Configuration

To manually add the EFA-NG RPM repository to your CentOS Stream 10 system:

```bash
# Install EPEL & Enable CRB
dnf -y install epel-release
dnf config-manager --set-enabled crb

# Add EFA-NG repository
curl -sSL https://raw.githubusercontent.com/kit400/EFA-NG/main/repos/efa-ng-centos10.repo -o /etc/yum.repos.d/efa-ng.repo
```

---

## Developer Guide & Building RPMs

To set up an RPM build environment and compile all EFA-NG packages locally on CentOS 10:

```bash
# Clone the repository
git clone https://github.com/kit400/EFA-NG.git
cd EFA-NG

# Prepare the build toolchain
./build/devprebuild.sh

# Build all RPM packages
cd rpmbuild/SPECS
./build_all_rpms.sh
```

Built RPMs and repository metadata will be generated in `rpm/efa-ng/centos10/release/`.

---

## Community & Official Support

* **Official Support Channel (Telegram)**: [https://t.me/EFA_NG](https://t.me/EFA_NG)
* **Official Project Portal**: [https://efa-ng.space.ua](https://efa-ng.space.ua)
* **GitHub Issues & Discussions**: [https://github.com/kit400/EFA-NG/issues](https://github.com/kit400/EFA-NG/issues)

---

## Contributing

Contributions, bug reports, and pull requests are welcome!
Please ensure that all code comments, documentation, and commit messages follow standard English conventions.

1. Fork the repository (`https://github.com/kit400/EFA-NG`).
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## License & Acknowledgements

- Licensed under the [GNU General Public License v3.0 (GPLv3)](LICENSE).
- Based on the [eFa Project](https://efa-project.org) by the eFa Development Team.
- Maintained by [kit400](https://github.com/kit400) and the EFA-NG community.
