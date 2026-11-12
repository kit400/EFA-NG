#!/usr/bin/env bash
#-----------------------------------------------------------------------------#
# EFA-NG Web & RPM Repository Deployment Script
# Deploys Portal and RPM Repository from DEV to Production Web Node (efa-web)
# Uses dedicated least-privilege user 'efa-deploy'
#-----------------------------------------------------------------------------#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_HOST="efa-web"
PORTAL_SRC="/var/www/efa-portal"
REPO_SRC="/home/kit/EFA-NG/rpm"
PORTAL_DST="/var/www/efa-portal"
REPO_DST="/var/www/repo"

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

# 1. Connectivity Check
log "Testing SSH connectivity to ${TARGET_HOST} as efa-deploy..."
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${TARGET_HOST}" "whoami" | grep -q "efa-deploy"; then
    error "Cannot connect to ${TARGET_HOST} as efa-deploy via SSH. Check ~/.ssh/config and keys."
fi
success "SSH connectivity confirmed."

# 2. Deploy RPM Repository
if [ -d "${REPO_SRC}" ]; then
    log "Synchronizing RPM Repository (${REPO_SRC} -> ${TARGET_HOST}:${REPO_DST})..."
    rsync -avz --delete \
        --chmod=D755,F644 \
        "${REPO_SRC}/" "${TARGET_HOST}:${REPO_DST}/"
    success "RPM Repository synchronized successfully."
else
    warn "RPM source directory ${REPO_SRC} not found. Skipping RPM sync."
fi

# 3. Deploy Web Portal
if [ -d "${PORTAL_SRC}" ]; then
    log "Synchronizing Web Portal (${PORTAL_SRC} -> ${TARGET_HOST}:${PORTAL_DST})..."
    rsync -avz \
        --exclude='.git' \
        --exclude='storage/logs/*.log' \
        --exclude='storage/framework/cache/*' \
        --exclude='storage/framework/sessions/*' \
        --exclude='storage/framework/views/*' \
        --chmod=D755,F644 \
        "${PORTAL_SRC}/" "${TARGET_HOST}:${PORTAL_DST}/"

    # Ensure storage permissions for PHP-FPM
    ssh "${TARGET_HOST}" "mkdir -p ${PORTAL_DST}/storage/framework/{cache,sessions,views} ${PORTAL_DST}/storage/logs && chmod -R 775 ${PORTAL_DST}/storage ${PORTAL_DST}/bootstrap 2>/dev/null || true"
    success "Web Portal synchronized successfully."
else
    warn "Portal source directory ${PORTAL_SRC} not found. Skipping Portal sync."
fi

# 4. Reload Nginx on Target
log "Testing and reloading Nginx on ${TARGET_HOST}..."
ssh "${TARGET_HOST}" "sudo /usr/sbin/nginx -t && sudo /usr/bin/systemctl reload nginx"
success "Nginx reloaded successfully on ${TARGET_HOST}."

echo ""
success "=================================================================="
success "Deployment to ${TARGET_HOST} completed successfully!"
success "Portal URL:   http://212.1.66.160/"
success "Repo URL:     http://212.1.66.160/repo/"
success "=================================================================="
