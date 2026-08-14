#!/bin/bash
######################################################################
# EFA-NG Master RPM Build Script for CentOS Stream 10 / EL10
# Repository: https://github.com/kit400/EFA-NG
######################################################################
# Copyright (C) 2026 EFA-NG Project https://github.com/kit400/EFA-NG
# License: GNU GPL v3+
######################################################################
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RPMBUILD_DIR="$SCRIPT_DIR/rpmbuild"
SPECS_DIR="$RPMBUILD_DIR/SPECS"
SOURCES_DIR="$RPMBUILD_DIR/SOURCES"
OUTPUT_REPO_DIR="$SCRIPT_DIR/rpm/efa-ng/centos10/release"

echo "=================================================================="
echo "Starting EFA-NG RPM Build Pipeline for CentOS 10 / EL10"
echo "Root directory: $SCRIPT_DIR"
echo "=================================================================="

# Ensure directories exist
mkdir -p "$RPMBUILD_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "$OUTPUT_REPO_DIR"/{x86_64,noarch}

# Setup RPM macro topdir
export RPM_TOPDIR="$RPMBUILD_DIR"
echo "%_topdir $RPMBUILD_DIR" > ~/.rpmmacros

# 1. Package source tarballs for eFa and eFa-base
echo "--> Creating source tarballs..."
cd "$SOURCES_DIR"
if [ -d "eFa-5.0.0" ]; then
    rm -f eFa-5.0.0.tar.gz
    tar czf eFa-5.0.0.tar.gz eFa-5.0.0
    echo "  [OK] eFa-5.0.0.tar.gz created"
fi

if [ -d "eFa-base-5.0.0" ]; then
    rm -f eFa-base-5.0.0.tar.gz
    tar czf eFa-base-5.0.0.tar.gz eFa-base-5.0.0
    echo "  [OK] eFa-base-5.0.0.tar.gz created"
fi

cd "$SPECS_DIR"

# List of spec files to build in dependency order
SPECS_TO_BUILD=(
    "perl-Sys-SigAction.spec"
    "perl-Sys-Hostname-Long.spec"
    "perl-Sendmail-PMilter.spec"
    "perl-Net-LibIDN.spec"
    "perl-Net-DNS-Resolver-Programmable.spec"
    "perl-IP-Country.spec"
    "perl-IP-Country-DB_File.spec"
    "perl-Geo-IP.spec"
    "perl-Encoding-FixLatin.spec"
    "perl-Mail-DMARC.spec"
    "perl-Net-IDN-Encode.spec"
    "perl-Test-File-ShareDir.spec"
    "tnef.spec"
    "unrar.spec"
    "dcc.spec"
    "sqlgrey.spec"
    "sqlgreywebinterface.spec"
    "clamav-unofficial-sigs.spec"
    "mailscanner.spec"
    "MailWatch.spec"
    "eFa5-base.spec"
    "eFa5.spec"
)

# 2. Build RPM packages
for spec in "${SPECS_TO_BUILD[@]}"; do
    if [ -f "$spec" ]; then
        echo "--> Building RPM from $spec..."
        rpmbuild -ba --define "_topdir $RPMBUILD_DIR" "$spec" || {
            echo "  [WARNING] Build failed for $spec (continuing with remaining packages)"
        }
    else
        echo "  [SKIP] $spec not found"
    fi
done

# 3. Copy built RPMs to repository output directory
echo "--> Collecting built RPMs..."
find "$RPMBUILD_DIR/RPMS" -type f -name "*.rpm" -exec cp -v {} "$OUTPUT_REPO_DIR/" \;

# 4. Generate repository metadata if createrepo_c is available
if command -v createrepo_c >/dev/null 2>&1; then
    echo "--> Generating repository metadata with createrepo_c..."
    createrepo_c "$OUTPUT_REPO_DIR"
    echo "  [OK] Repository metadata generated at $OUTPUT_REPO_DIR/repodata"
elif command -v createrepo >/dev/null 2>&1; then
    echo "--> Generating repository metadata with createrepo..."
    createrepo "$OUTPUT_REPO_DIR"
    echo "  [OK] Repository metadata generated at $OUTPUT_REPO_DIR/repodata"
else
    echo "  [NOTICE] createrepo_c not installed. Run 'sudo dnf install createrepo_c' and execute 'createrepo_c $OUTPUT_REPO_DIR'."
fi

echo "=================================================================="
echo "EFA-NG RPM Build Pipeline Completed!"
echo "Output Directory: $OUTPUT_REPO_DIR"
echo "=================================================================="
