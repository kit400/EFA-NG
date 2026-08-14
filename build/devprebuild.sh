#!/bin/bash
######################################################################
# EFA-NG Development Prebuild Environment
# Target OS: CentOS Stream 10 / RHEL 10 / CentOS Stream 9
######################################################################
# Copyright (C) 2024  https://efa-project.org
# Copyright (C) 2026  EFA-NG Project https://github.com/kit400/EFA-NG
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
#######################################################################

# Determine git repository path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITPATH="${GITPATH:-$SCRIPT_DIR}"

# Check OS version
OSVERSION=""
if [ -f /etc/redhat-release ]; then
    OSVERSION=$(cat /etc/redhat-release)
elif [ -f /etc/os-release ]; then
    OSVERSION=$(cat /etc/os-release)
fi

if [[ $OSVERSION =~ .*'release 10'.* || $OSVERSION =~ VERSION_ID=\"10\" || $OSVERSION =~ VERSION_ID=10 ]]; then
  echo "Good, you are running CentOS Stream 10, RHEL 10, or compatible EL10 distribution"
  RELEASE=10
elif [[ $OSVERSION =~ .*'release 9'.* || $OSVERSION =~ VERSION_ID=\"9\" || $OSVERSION =~ VERSION_ID=9 ]]; then
  echo "Good, you are running CentOS Stream 9, RHEL 9, or compatible EL9 distribution"
  RELEASE=9
else
  echo "- ERROR: You are not running CentOS 10, CentOS 9 or compatible distribution"
  echo "- ERROR: Unsupported system, stopping now"
  exit 1
fi

if [[ -z $(grep -i 'lxc\|docker\|container' /proc/1/cgroup 2>/dev/null) && ! -f /.dockerenv ]]; then
  if [[ -f /etc/selinux/config && -n $(grep -i '^SELINUX=disabled' /etc/selinux/config) ]]; then
    echo "- ERROR: SELinux is disabled and this is not a container"
    echo "- ERROR: Please set SELinux to permissive or enforcing and try again."
    exit 1
  fi
fi

if [[ ! -d "$GITPATH/rpmbuild" ]]; then
  echo "- ERROR: rpmbuild directory not found in GITPATH ($GITPATH)"
  echo "- ERROR: Please run this script from the EFA-NG repository root."
  exit 1
fi

echo "Installing EPEL repository..."
sudo dnf -y install epel-release || exit 1

echo "Enabling CRB repository..."
if [[ $RELEASE -eq 10 ]]; then
  if rpm -q redhat-release >/dev/null 2>&1 && [[ ! -f /etc/centos-release && ! -f /etc/almalinux-release && ! -f /etc/rocky-release ]]; then
    sudo subscription-manager repos --enable codeready-builder-for-rhel-10-x86_64-rpms 2>/dev/null || true
  else
    sudo dnf config-manager --set-enabled crb 2>/dev/null || sudo dnf config-manager --enable crb 2>/dev/null || true
  fi
elif [[ $RELEASE -eq 9 ]]; then
  if rpm -q redhat-release >/dev/null 2>&1 && [[ ! -f /etc/centos-release && ! -f /etc/almalinux-release && ! -f /etc/rocky-release ]]; then
    sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms 2>/dev/null || true
  else
    sudo dnf config-manager --set-enabled crb 2>/dev/null || sudo dnf config-manager --enable crb 2>/dev/null || true
  fi
  sudo dnf module -y reset php || exit 1
  sudo dnf module -y enable php:8.1 || exit 1
fi

echo "Updating system..."
sudo dnf -y update || exit 1

echo "Installing RPM build toolchain..."
sudo dnf -y install rpm-build rpmdevtools gcc gcc-c++ make tar createrepo_c git || exit 1

echo "Setting up rpmbuild directories and macros..."
mkdir -p "$GITPATH/rpmbuild"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
echo "%_topdir $GITPATH/rpmbuild" > ~/.rpmmacros

echo "=================================================================="
echo "EFA-NG Development Environment Ready!"
echo "Repository Path: $GITPATH"
echo "RPM Build Path:  $GITPATH/rpmbuild"
echo "=================================================================="
