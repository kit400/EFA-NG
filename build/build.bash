#!/bin/bash
#-----------------------------------------------------------------------------#
# EFA-NG Build Script (CentOS 10 / 9 / 8)
# Repository: https://github.com/kit400/EFA-NG
#-----------------------------------------------------------------------------#
# Copyright (C) 2013~2024 https://efa-project.org
# Copyright (C) 2026 EFA-NG Project https://github.com/kit400/EFA-NG
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------#
action=$1
[[ -z $action ]] && action="production" # default to prod if no arg supplied

#-----------------------------------------------------------------------------#
# Install EFA-NG
#-----------------------------------------------------------------------------#
mirror="https://raw.githubusercontent.com/kit400/EFA-NG/main"
LOGFILE="/var/log/eFa/build.log"

#-----------------------------------------------------------------------------#
# Set up logging
#-----------------------------------------------------------------------------#
LOGGER='/usr/bin/logger'
HEADER='=============  EFA-NG (EL 10 / EL 9 / EL 8) BUILD SCRIPT STARTING  ============'

# CREATE LOG FOLDER IF NOT EXISTS
mkdir -p $(dirname "${LOGFILE}")

# TRY TO CREATE LOG FILE IF NOT EXISTS
( [ -e "$LOGFILE" ] || touch "$LOGFILE" ) && [ ! -w "$LOGFILE" ] && echo "Unable to create or write to $LOGFILE"

function logthis() {
    TAG='EFA-NG'
    MSG="$1"
    if [ -x "$LOGGER" ]; then
        $LOGGER -t "$TAG" "$MSG"
    fi
    echo "$(date +%Y.%m.%d-%H:%M:%S) - $MSG"
    echo "$(date +%Y.%m.%d-%H:%M:%S) - $MSG" >> "$LOGFILE" 2>/dev/null
}

logthis "$HEADER"
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# check if user is root
#-----------------------------------------------------------------------------#
if [ "$(id -u)" -eq 0 ]; then
  logthis "Good, you are root."
else
  logthis "ERROR: Please run as root (or with sudo)."
  logthis "^^^^^^^^^^ SCRIPT ABORTED ^^^^^^^^^^"
  exit 1
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# check OS distribution and version
#-----------------------------------------------------------------------------#
OSVERSION=""
if [ -f /etc/redhat-release ]; then
    OSVERSION=$(cat /etc/redhat-release)
elif [ -f /etc/os-release ]; then
    OSVERSION=$(cat /etc/os-release)
fi

if [[ $OSVERSION =~ .*'release 10'.* || $OSVERSION =~ VERSION_ID=\"10\" || $OSVERSION =~ VERSION_ID=10 ]]; then
  logthis "Good, you are running CentOS Stream 10, RHEL 10, or compatible EL10 distribution"
  RELEASE=10
elif [[ $OSVERSION =~ .*'release 9'.* || $OSVERSION =~ VERSION_ID=\"9\" || $OSVERSION =~ VERSION_ID=9 ]]; then
  logthis "Good, you are running CentOS Stream 9, RHEL 9, or compatible EL9 distribution"
  RELEASE=9
elif [[ $OSVERSION =~ .*'release 8'.* || $OSVERSION =~ VERSION_ID=\"8\" || $OSVERSION =~ VERSION_ID=8 ]]; then
  logthis "Good, you are running CentOS 8, RHEL 8, or compatible EL8 distribution"
  RELEASE=8
else
  logthis "ERROR: You are not running CentOS 10, 9, 8 or equivalent Enterprise Linux distribution"
  logthis "ERROR: Unsupported system, stopping now"
  logthis "^^^^^^^^^^ SCRIPT ABORTED ^^^^^^^^^^"
  exit 1
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Check that SELinux is not disabled (unless it is lxc/container)
#-----------------------------------------------------------------------------#
if [[ -z $(grep -i 'lxc\|docker\|container' /proc/1/cgroup 2>/dev/null) && ! -f /.dockerenv ]]; then
    if [[ -f /etc/selinux/config && -n $(grep -i '^SELINUX=disabled' /etc/selinux/config) ]]; then
        logthis "ERROR: SELinux is disabled and this is not a container"
        logthis "ERROR: Please set SELinux to permissive or enforcing in /etc/selinux/config and try again."
        logthis "^^^^^^^^^^ SCRIPT ABORTED ^^^^^^^^^^"
        exit 1
    fi
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Check network connectivity
#-----------------------------------------------------------------------------#
logthis "Checking network connectivity"
curl -s --connect-timeout 5 --max-time 15 --retry 3 --retry-delay 1 "https://github.com" > /dev/null
if [[ $? -eq 0 ]]; then
  logthis "OK - Internet connectivity is available"
else
  logthis "ERROR: No network connectivity or GitHub unreachable"
  logthis "^^^^^^^^^^ SCRIPT ABORTED ^^^^^^^^^^"
  exit 1
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Install essential tools: wget, curl, tar, dnf-plugins-core
#-----------------------------------------------------------------------------#
for pkg in curl wget tar dnf-plugins-core perl; do
    if ! rpm -q "$pkg" >/dev/null 2>&1; then
        logthis "Installing $pkg"
        dnf -y install "$pkg" | tee -a "$LOGFILE"
        if [ $? -ne 0 ]; then
            logthis "WARNING: Failed to install $pkg (will retry during update)"
        fi
    fi
done
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Install EPEL repository
#-----------------------------------------------------------------------------#
if ! rpm -q epel-release >/dev/null 2>&1; then
    logthis "Installing EPEL repository"
    dnf -y install epel-release | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        logthis "ERROR: EPEL installation failed"
        logthis "^^^^^^^^^^ SCRIPT ABORTED ^^^^^^^^^^"
        exit 1
    fi
    logthis "EPEL repository installed successfully"
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Enable CRB / CodeReady Builder & PHP Configuration
#-----------------------------------------------------------------------------#
if [[ $RELEASE -eq 10 ]]; then
    logthis "Configuring CentOS 10 / EL10 repositories"
    if rpm -q redhat-release >/dev/null 2>&1 && [[ ! -f /etc/centos-release && ! -f /etc/almalinux-release && ! -f /etc/rocky-release ]]; then
        subscription-manager repos --enable codeready-builder-for-rhel-10-x86_64-rpms 2>/dev/null || true
    else
        dnf config-manager --set-enabled crb 2>/dev/null || dnf config-manager --enable crb 2>/dev/null || true
    fi
    logthis "CRB repository enabled"
    # Note: EL10 uses standard PHP 8.3 streams without DNF modularity commands.

elif [[ $RELEASE -eq 9 ]]; then
    logthis "Configuring CentOS 9 / EL9 repositories"
    if rpm -q redhat-release >/dev/null 2>&1 && [[ ! -f /etc/centos-release && ! -f /etc/almalinux-release && ! -f /etc/rocky-release ]]; then
        subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms 2>/dev/null || true
    else
        dnf config-manager --set-enabled crb 2>/dev/null || dnf config-manager --enable crb 2>/dev/null || true
    fi
    logthis "CRB repository enabled"

    # Reset and enable PHP 8.1 on EL9
    dnf module -y reset php | tee -a "$LOGFILE"
    dnf module -y enable php:8.1 | tee -a "$LOGFILE"

elif [[ $RELEASE -eq 8 ]]; then
    logthis "Enabling CentOS 8 PowerTools repository"
    dnf -y install 'dnf-command(config-manager)'
    dnf config-manager --set-enabled powertools || dnf config-manager --enable powertools || true
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Add EFA-NG Repository
#-----------------------------------------------------------------------------#
logthis "Setting up EFA-NG repository"
mkdir -p /usr/src/eFa
mkdir -p /etc/yum.repos.d/

# Install repository definition
cat > /etc/yum.repos.d/efa-ng.repo << EOF
[efa-ng]
name=EFA-NG Repository - EL${RELEASE}
baseurl=https://raw.githubusercontent.com/kit400/EFA-NG/main/rpm/efa-ng/centos${RELEASE}/release
gpgcheck=0
enabled=1

[efa-ng-testing]
name=EFA-NG Testing Repository - EL${RELEASE}
baseurl=https://raw.githubusercontent.com/kit400/EFA-NG/main/rpm/efa-ng/centos${RELEASE}/testing
gpgcheck=0
enabled=0

[efa-ng-dev]
name=EFA-NG Dev Repository - EL${RELEASE}
baseurl=https://raw.githubusercontent.com/kit400/EFA-NG/main/rpm/efa-ng/centos${RELEASE}/dev
gpgcheck=0
enabled=0
EOF

case "$action" in
    ("testing"|"kstesting"|"testingnoefa")
        dnf config-manager --set-enabled efa-ng-testing 2>/dev/null || true
        logthis "Enabled EFA-NG testing repository"
        ;;
    ("dev"|"ksdev"|"devnoefa")
        dnf config-manager --set-enabled efa-ng-dev 2>/dev/null || true
        logthis "Enabled EFA-NG dev repository"
        ;;
    (*)
        logthis "Enabled EFA-NG release repository"
        ;;
esac
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Update OS
#-----------------------------------------------------------------------------#
logthis "Updating system packages..."
dnf -y update | tee -a "$LOGFILE"
if [ $? -eq 0 ]; then
    logthis "System updated successfully"
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Remove conflicting default packages
#-----------------------------------------------------------------------------#
logthis "Checking and removing conflicting packages"
# Remove default minimal postfix if replacing with full EFA-NG build
# dnf -y remove postfix >/dev/null 2>&1 || true
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Install EFA-NG
#-----------------------------------------------------------------------------#
logthis "Installing EFA-NG packages (this may take several minutes)..."
if ! rpm -q eFa >/dev/null 2>&1 && ! rpm -q efa-ng >/dev/null 2>&1; then
    if [[ "$action" != "testingnoefa" && "$action" != "devnoefa" ]]; then
        dnf -y install eFa 2>&1 | tee -a "$LOGFILE"
        INSTALL_STATUS=${PIPESTATUS[0]}
        if [ $INSTALL_STATUS -ne 0 ]; then
            dnf -y install efa-ng 2>&1 | tee -a "$LOGFILE"
            INSTALL_STATUS=${PIPESTATUS[0]}
        fi
        if [ $INSTALL_STATUS -eq 0 ]; then
            logthis "EFA-NG installed successfully"
        else
            logthis "ERROR: EFA-NG package installation encountered errors"
            logthis "Please check $LOGFILE for detailed logs."
            logthis "^^^^^^^^^^ SCRIPT ABORTED ^^^^^^^^^^"
            exit 1
        fi
    fi
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Kickstart automated provisioning hooks
#-----------------------------------------------------------------------------#
if [[ "$action" == "kstesting" || "$action" == "ksproduction" || "$action" == "ksdev" ]]; then
  logthis "Configuring Kickstart default credentials"
  echo 'echo "First time login: root/eFaPr0j3ct" >> /etc/issue' >> /etc/rc.d/rc.local
  echo "root:eFaPr0j3ct" | chpasswd --md5 root 2>/dev/null || echo "root:eFaPr0j3ct" | chpasswd
  systemctl disable sshd 2>/dev/null || true
fi

if [[ "$action" == "ksproduction" ]]; then
  logthis "Zeroing free space for template export"
  dd if=/dev/zero of=/filler bs=4096 >/dev/null 2>&1 || true
  rm -f /filler
  dd if=/dev/zero of=/tmp/filler bs=4096 >/dev/null 2>&1 || true
  rm -f /tmp/filler
  dd if=/dev/zero of=/var/filler bs=4096 >/dev/null 2>&1 || true
  rm -f /var/filler
  logthis "Zeroed free space complete"
fi
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Finalize & Reboot Prompt
#-----------------------------------------------------------------------------#
logthis "============  EFA-NG BUILD SCRIPT FINISHED  ============"
logthis "============  PLEASE REBOOT YOUR SYSTEM   ============"

if [[ "$action" == "testing" || "$action" == "production" || "$action" == "dev" ]]; then
  if [ -t 0 ]; then
    read -r -p "Do you wish to reboot the system now? (Y/N): " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
      shutdown -r +1 "EFA-NG installation requires reboot. Restarting in 1 minute."
      exit 0
    else
      logthis "Reboot postponed by user. Please reboot manually before starting services."
      exit 0
    fi
  fi
fi
exit 0
