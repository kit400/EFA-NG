#!/bin/bash
######################################################################
# EFA-NG Master RPM Build Script for CentOS Stream 10 / EL10
# Repository: https://github.com/kit400/EFA-NG
######################################################################
# Copyright (C) 2026 EFA-NG Project https://github.com/kit400/EFA-NG
# License: GNU GPL v3+
######################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RPMBUILD_DIR="$SCRIPT_DIR/rpmbuild"
SPECS_DIR="$RPMBUILD_DIR/SPECS"
SOURCES_DIR="$RPMBUILD_DIR/SOURCES"
OUTPUT_REPO_DIR="$SCRIPT_DIR/rpm/efa-ng/centos10/release"
GPG_KEY_NAME="EFA-NG Release Signing Key <security@efa-ng.space.ua>"
PUBLIC_KEY_PATH="$SCRIPT_DIR/rpm/efa-ng/RPM-GPG-KEY-EFA-NG"
MAILWATCH_REPO_DIR="${MAILWATCH_REPO_DIR:-/home/kit/MailWatch-NG}"

echo "=================================================================="
echo "Starting EFA-NG RPM Build Pipeline for CentOS 10 / EL10"
echo "Root directory: $SCRIPT_DIR"
echo "=================================================================="

# Ensure directories exist
mkdir -p "$RPMBUILD_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p "$OUTPUT_REPO_DIR"

# Setup RPM macro topdir
export RPM_TOPDIR="$RPMBUILD_DIR"
cat > ~/.rpmmacros <<EOF
%_topdir $RPMBUILD_DIR
%_gpg_name $GPG_KEY_NAME
EOF

EFA_VERSION=$(awk '/^Version:/ {print $2; exit}' "$SPECS_DIR/eFa5.spec")
EFA_BASE_VERSION=$(awk '/^Version:/ {print $2; exit}' "$SPECS_DIR/eFa5-base.spec")
MW_VERSION=$(awk '/^Version:/ {print $2; exit}' "$SPECS_DIR/MailWatch.spec")

# 1. Package source tarballs for eFa, eFa-base, and MailWatch
echo "--> Creating source tarballs (eFa=${EFA_VERSION}, eFa-base=${EFA_BASE_VERSION}, MailWatch=${MW_VERSION})..."
cd "$SOURCES_DIR"
if [ -d "eFa-5.0.0" ]; then
    rm -f "eFa-${EFA_VERSION}.tar.gz"
    tar czf "eFa-${EFA_VERSION}.tar.gz" --transform "s|^eFa-5.0.0|eFa-${EFA_VERSION}|" eFa-5.0.0
    echo "  [OK] eFa-${EFA_VERSION}.tar.gz created"
fi

if [ -d "eFa-base-5.0.0" ]; then
    rm -f "eFa-base-${EFA_BASE_VERSION}.tar.gz"
    tar czf "eFa-base-${EFA_BASE_VERSION}.tar.gz" --transform "s|^eFa-base-5.0.0|eFa-base-${EFA_BASE_VERSION}|" eFa-base-5.0.0
    echo "  [OK] eFa-base-${EFA_BASE_VERSION}.tar.gz created"
fi

if [ -d "$MAILWATCH_REPO_DIR" ]; then
    rm -f "$SOURCES_DIR/MailWatch-${MW_VERSION}.tar.gz"
    tar czf "$SOURCES_DIR/MailWatch-${MW_VERSION}.tar.gz" \
        --exclude='.git' \
        --transform "s|^\\.|MailWatch-NG-${MW_VERSION}|" \
        -C "$MAILWATCH_REPO_DIR" .
    echo "  [OK] MailWatch-${MW_VERSION}.tar.gz created from $MAILWATCH_REPO_DIR"
fi

cd "$SPECS_DIR"

# If arguments are passed, build only those specs; otherwise build full list
if [ "$#" -gt 0 ]; then
    SPECS_TO_BUILD=("$@")
else
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
fi

# 2. Build RPM packages (fail fast on any error)
for spec in "${SPECS_TO_BUILD[@]}"; do
    if [ -f "$spec" ]; then
        echo "--> Building RPM from $spec..."
        rpmbuild -bb --define "_topdir $RPMBUILD_DIR" "$spec"
    else
        echo "  [ERROR] $spec not found" >&2
        exit 1
    fi
done

# 3. Copy built RPMs to repository output directory
echo "--> Collecting built RPMs..."
find "$RPMBUILD_DIR/RPMS" -type f -name "*.rpm" -exec cp -v {} "$OUTPUT_REPO_DIR/" \;

# 4. Sign RPMs if GPG key and rpmsign are available
if command -v rpmsign >/dev/null 2>&1 && gpg --list-secret-keys "$GPG_KEY_NAME" >/dev/null 2>&1; then
    echo "--> Signing RPM packages with GPG key: $GPG_KEY_NAME..."
    rpmsign --addsign --define "_gpg_name $GPG_KEY_NAME" "$OUTPUT_REPO_DIR"/*.rpm
    gpg --armor --export "$GPG_KEY_NAME" > "$PUBLIC_KEY_PATH"
    echo "  [OK] RPMs signed and public key exported to $PUBLIC_KEY_PATH"
fi

# 5. Generate repository metadata and sign repomd.xml
if command -v createrepo_c >/dev/null 2>&1; then
    echo "--> Generating repository metadata with createrepo_c..."
    createrepo_c "$OUTPUT_REPO_DIR"
    echo "  [OK] Repository metadata generated at $OUTPUT_REPO_DIR/repodata"
elif command -v createrepo >/dev/null 2>&1; then
    echo "--> Generating repository metadata with createrepo..."
    createrepo "$OUTPUT_REPO_DIR"
    echo "  [OK] Repository metadata generated at $OUTPUT_REPO_DIR/repodata"
else
    echo "  [ERROR] createrepo_c not installed." >&2
    exit 1
fi

if gpg --list-secret-keys "$GPG_KEY_NAME" >/dev/null 2>&1; then
    echo "--> Signing repomd.xml..."
    rm -f "$OUTPUT_REPO_DIR/repodata/repomd.xml.asc"
    gpg --batch --yes --detach-sign --armor -u "$GPG_KEY_NAME" \
        -o "$OUTPUT_REPO_DIR/repodata/repomd.xml.asc" \
        "$OUTPUT_REPO_DIR/repodata/repomd.xml"
    cp -f "$PUBLIC_KEY_PATH" "$OUTPUT_REPO_DIR/repodata/repomd.xml.key"
    echo "  [OK] Signed repodata/repomd.xml.asc"
fi

echo "=================================================================="
echo "EFA-NG RPM Build Pipeline Completed!"
echo "Output Directory: $OUTPUT_REPO_DIR"
echo "=================================================================="
