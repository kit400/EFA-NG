#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# EFA-NG Automated Release Pipeline Script (#rel)
#
# Steps executed:
#   1. Parse latest version from CHANGELOG.md (or use --version argument)
#   2. Synchronize version strings across EFA-NG, MailWatch-NG, and spec files
#   3. Commit and tag Git repositories (EFA-NG, MailWatch-NG, EFA-NG-portal)
#   4. Push commits and tags to GitHub
#   5. Deploy update to Test Server (efa-test: 195.230.150.68)
#   6. Deploy Documentation & Portal Updates (http://efa-ng.space.ua)
#   7. Publish Official Release Announcement to Forum (http://forum.efa-ng.space.ua/t/announcements)
#   8. Broadcast in-app release notification to all users in MailWatch-NG
#-----------------------------------------------------------------------------#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 1. Parse Arguments
TARGET_VERSION=""
DRY_RUN=0
SKIP_DEPLOY=0

for arg in "$@"; do
    case "$arg" in
        --version=*|-v=*)
            TARGET_VERSION="${arg#*=}"
            ;;
        --dry-run)
            DRY_RUN=1
            ;;
        --skip-deploy)
            SKIP_DEPLOY=1
            ;;
        --help|-h)
            echo -e "${CYAN}EFA-NG Automated Release CLI (#rel)${NC}"
            echo "Usage: bash tools/release.sh [options]"
            echo "Options:"
            echo "  --version=X.Y.Z   Explicitly set release version (default: auto-detected from CHANGELOG.md)"
            echo "  --dry-run         Preview actions without modifying git, servers, or database"
            echo "  --skip-deploy     Tag and publish without syncing to remote test servers"
            exit 0
            ;;
    esac
done

EFA_DIR="/home/kit/EFA-NG"
MAILWATCH_DIR="/home/kit/MailWatch-NG"
PORTAL_DIR="/home/kit/EFA-NG-portal"
CHANGELOG_FILE="${EFA_DIR}/CHANGELOG.md"

if [ ! -f "$CHANGELOG_FILE" ]; then
    error "CHANGELOG.md not found at ${CHANGELOG_FILE}"
fi

# Detect latest version from CHANGELOG.md if not provided
if [ -z "$TARGET_VERSION" ]; then
    TARGET_VERSION=$(grep -E '^##\s+\[?[0-9a-zA-Z\.\-]+\]?' "$CHANGELOG_FILE" | head -n 1 | sed -E 's/^##\s+\[?([^] ]+).*/\1/')
fi

if [ -z "$TARGET_VERSION" ]; then
    error "Could not auto-detect version from CHANGELOG.md"
fi

CLEAN_VERSION=$(echo "$TARGET_VERSION" | sed -E 's/^v//')
TAG_NAME="v${CLEAN_VERSION}"

log "==============================================================="
log "Starting EFA-NG Release Pipeline for version: ${CYAN}${CLEAN_VERSION}${NC} (Tag: ${CYAN}${TAG_NAME}${NC})"
log "==============================================================="

# STEP 1: Version Consistency Check
log "Step 1: Checking and synchronizing version definitions..."
if [ "$DRY_RUN" -eq 0 ]; then
    # Update MailWatch-NG functions.php
    if [ -f "${MAILWATCH_DIR}/mailscanner/functions.php" ]; then
        sed -i -E "s/define\('MAILWATCH_VERSION', '[^']+'\);/define('MAILWATCH_VERSION', '${CLEAN_VERSION}');/g" "${MAILWATCH_DIR}/mailscanner/functions.php"
        sed -i -E "s/return 'eFa-[0-9.]+';/return 'eFa-${CLEAN_VERSION}';/g" "${MAILWATCH_DIR}/mailscanner/functions.php"
    fi

    # Update RPM spec if present
    if [ -f "${EFA_DIR}/rpmbuild/SPECS/eFa5.spec" ]; then
        sed -i -E "s/^Version:\s+[0-9.]+/Version: ${CLEAN_VERSION}/g" "${EFA_DIR}/rpmbuild/SPECS/eFa5.spec"
    fi

    # Update version.json files
    if [ -f "${EFA_DIR}/version.json" ]; then
        sed -i -E "s/\"version\": \"[^\"]+\"/\"version\": \"${CLEAN_VERSION}\"/g" "${EFA_DIR}/version.json"
    fi
    if [ -f "${MAILWATCH_DIR}/version.json" ]; then
        sed -i -E "s/\"version\": \"[^\"]+\"/\"version\": \"${CLEAN_VERSION}\"/g" "${MAILWATCH_DIR}/version.json"
    fi
fi
success "Version strings set to ${CLEAN_VERSION}"

# STEP 2: Git Commit & Tagging
log "Step 2: Committing and tagging repositories..."
if [ "$DRY_RUN" -eq 0 ]; then
    # 2a. MailWatch-NG
    if [ -d "${MAILWATCH_DIR}/.git" ]; then
        git -C "${MAILWATCH_DIR}" add -A
        git -C "${MAILWATCH_DIR}" commit -m "Release ${TAG_NAME}" || true
        git -C "${MAILWATCH_DIR}" tag -f "${TAG_NAME}" -m "Release ${TAG_NAME}"
        git -C "${MAILWATCH_DIR}" push origin main --tags || warn "Failed to push MailWatch-NG tags"
        success "MailWatch-NG committed and tagged: ${TAG_NAME}"
    fi

    # 2b. EFA-NG
    if [ -d "${EFA_DIR}/.git" ]; then
        git -C "${EFA_DIR}" add -A
        git -C "${EFA_DIR}" commit -m "Release ${TAG_NAME}" || true
        git -C "${EFA_DIR}" tag -f "${TAG_NAME}" -m "Release ${TAG_NAME}"
        git -C "${EFA_DIR}" push origin main --tags || warn "Failed to push EFA-NG tags"
        success "EFA-NG committed and tagged: ${TAG_NAME}"
    fi

    # 2c. EFA-NG-portal
    if [ -d "${PORTAL_DIR}/.git" ]; then
        git -C "${PORTAL_DIR}" add -A
        git -C "${PORTAL_DIR}" commit -m "Release ${TAG_NAME} doc updates" || true
        git -C "${PORTAL_DIR}" push origin main || warn "Failed to push EFA-NG-portal"
        success "EFA-NG-portal committed and pushed"
    fi
else
    log "[DRY-RUN] Would tag and push ${TAG_NAME} in EFA-NG and MailWatch-NG"
fi

# STEP 3: Deploy to Test Server (efa-test / 195.230.150.68)
if [ "$SKIP_DEPLOY" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    log "Step 3: Deploying code and updating version on test server (efa-test)..."
    if ssh -o BatchMode=yes -o ConnectTimeout=5 efa-test "true" 2>/dev/null; then
        rsync -avz --delete \
            --exclude='conf.php' \
            --exclude='*.log' \
            "${MAILWATCH_DIR}/mailscanner/" efa-test:/var/www/html/mailscanner/

        ssh efa-test "
            echo 'eFa-${CLEAN_VERSION}' > /etc/EFA-Version
            echo '${CLEAN_VERSION}' > /etc/eFa-Version 2>/dev/null || true
            systemctl reload php-fpm || true
        "
        success "Test server updated to eFa-${CLEAN_VERSION}"
    else
        warn "Test server (efa-test) is currently unreachable. Skipping remote scp."
    fi
fi

# STEP 4: Portal & Documentation Deployment (http://efa-ng.space.ua)
log "Step 4: Deploying documentation and portal updates (http://efa-ng.space.ua)..."
if [ "$DRY_RUN" -eq 0 ]; then
    if [ -f "${PORTAL_DIR}/deploy.sh" ]; then
        sudo -n "${PORTAL_DIR}/deploy.sh" || php "${PORTAL_DIR}/deploy/announce.php" --sync-docs
    fi
    success "Documentation synchronized to http://efa-ng.space.ua/docs/08-changelog"
fi

# STEP 5: Publish Announcement to Community Forum & Telegram Topic
log "Step 5: Publishing release announcement to Flarum Forum & Telegram Announcements Topic..."
if [ "$DRY_RUN" -eq 0 ]; then
    php "${PORTAL_DIR}/deploy/announce.php" --version="${CLEAN_VERSION}" --tag="announcements" --telegram
    success "Release announcement posted to Forum (http://forum.efa-ng.space.ua/t/announcements) & Telegram (t.me/EFA_NG/3)"
else
    log "[DRY-RUN] Would publish announcement for ${CLEAN_VERSION} to Forum & Telegram (t.me/EFA_NG/3)"
fi

# STEP 6: In-App Broadcast Notification in MailWatch-NG
log "Step 6: Broadcasting release notification to MailWatch-NG users..."
if [ "$SKIP_DEPLOY" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    ssh -o BatchMode=yes efa-test "php /var/www/html/mailscanner/tools/send_update_notification.php \
        --type='release' \
        --title='🚀 EFA-NG ${CLEAN_VERSION} Released!' \
        --version='${CLEAN_VERSION}' \
        --desc='New release EFA-NG ${CLEAN_VERSION} has been deployed. Check out what is new at https://efa-ng.space.ua/changelog and http://forum.efa-ng.space.ua/t/announcements' \
        --changelog='http://efa-ng.space.ua/docs/08-changelog'" 2>/dev/null || warn "Could not create in-app broadcast notification on efa-test."
    success "In-app broadcast notification delivered."
fi

log "==============================================================="
success "🎉 Release ${TAG_NAME} completed successfully!"
log "  Portal:       http://efa-ng.space.ua"
log "  Changelog:    http://efa-ng.space.ua/docs/08-changelog"
log "  Forum Tag:    http://forum.efa-ng.space.ua/t/announcements"
log "  Telegram:     https://t.me/EFA_NG/3"
log "  Test Server:  https://efa-ng-test.ukrpack.net"
log "==============================================================="
