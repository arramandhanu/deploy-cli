#!/usr/bin/env bash
#==============================================================================
# SSH.SH - SSH deployment operations
#==============================================================================

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/colors.sh"

#------------------------------------------------------------------------------
# Execute command on remote server
#------------------------------------------------------------------------------
ssh_exec() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_user="${2:-${REMOTE_USER:-}}"
    local ssh_key="${3:-${SSH_KEY:-${HOME}/.ssh/id_rsa}}"
    local command="$4"
    
    # Expand ~ if present
    ssh_key="${ssh_key/#\~/$HOME}"
    
    ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
        "${remote_user}@${remote_host}" "$command"
}

#------------------------------------------------------------------------------
# Deploy service via docker-compose
#------------------------------------------------------------------------------
ssh_deploy() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_user="${2:-${REMOTE_USER:-}}"
    local remote_compose_dir="${3:-${REMOTE_COMPOSE_DIR:-}}"
    local ssh_key="${4:-${SSH_KEY:-${HOME}/.ssh/id_rsa}}"
    local image_name="$5"
    local tag="$6"
    local service_name="$7"
    local container_name="$8"
    
    # Expand ~ if present
    ssh_key="${ssh_key/#\~/$HOME}"
    
    log_info "Deploying to ${remote_host}..."
    
    local deploy_script="
set -euo pipefail

cd '${remote_compose_dir}'

# Update image tag in docker-compose.yaml
if [[ -f docker-compose.yaml ]]; then
    sed -i 's|image: ${image_name}:.*|image: ${image_name}:${tag}|' docker-compose.yaml
elif [[ -f docker-compose.yml ]]; then
    sed -i 's|image: ${image_name}:.*|image: ${image_name}:${tag}|' docker-compose.yml
fi

# Pull and recreate
docker compose pull ${service_name}
docker compose up -d --no-deps --force-recreate ${service_name}

# Show status
echo '=== Container Status ==='
docker ps --filter 'name=${container_name}' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo ''
echo '=== Recent Logs ==='
docker logs --tail=50 ${container_name} 2>&1 || true
"
    
    if ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
           "${remote_user}@${remote_host}" "$deploy_script"; then
        log_success "Deployment completed successfully"
        return 0
    else
        log_error "Deployment failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Rollback to previous version
#------------------------------------------------------------------------------
ssh_rollback() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_user="${2:-${REMOTE_USER:-}}"
    local remote_compose_dir="${3:-${REMOTE_COMPOSE_DIR:-}}"
    local ssh_key="${4:-${SSH_KEY:-${HOME}/.ssh/id_rsa}}"
    local image_name="$5"
    local rollback_tag="$6"
    local service_name="$7"
    local container_name="$8"
    
    # Expand ~ if present
    ssh_key="${ssh_key/#\~/$HOME}"
    
    log_info "Rolling back to ${image_name}:${rollback_tag}..."
    
    local rollback_script="
set -euo pipefail

cd '${remote_compose_dir}'

# Update image tag in docker-compose.yaml
if [[ -f docker-compose.yaml ]]; then
    sed -i 's|image: ${image_name}:.*|image: ${image_name}:${rollback_tag}|' docker-compose.yaml
elif [[ -f docker-compose.yml ]]; then
    sed -i 's|image: ${image_name}:.*|image: ${image_name}:${rollback_tag}|' docker-compose.yml
fi

# Pull and recreate
docker compose pull ${service_name}
docker compose up -d --no-deps --force-recreate ${service_name}

# Show status
docker ps --filter 'name=${container_name}'
"
    
    if ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
           "${remote_user}@${remote_host}" "$rollback_script"; then
        log_success "Rollback completed successfully"
        return 0
    else
        log_error "Rollback failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Health check via HTTP
#------------------------------------------------------------------------------
ssh_health_check_http() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_user="${2:-${REMOTE_USER:-}}"
    local ssh_key="${3:-${SSH_KEY:-${HOME}/.ssh/id_rsa}}"
    local health_port="$4"
    local health_path="${5:-/health}"
    local timeout="${6:-30}"
    local container_name="${7:-}"
    
    # Expand ~ if present
    ssh_key="${ssh_key/#\~/$HOME}"
    
    log_info "Waiting for service to be healthy..."
    
    local check_script="
for i in \$(seq 1 ${timeout}); do
    if curl -sf 'http://localhost:${health_port}${health_path}' > /dev/null 2>&1; then
        echo 'OK'
        exit 0
    fi
    sleep 1
done
echo 'TIMEOUT'
exit 1
"
    
    local result
    result=$(ssh -i "$ssh_key" -o BatchMode=yes "${remote_user}@${remote_host}" "$check_script" 2>/dev/null)
    
    if [[ "$result" == "OK" ]]; then
        log_success "Service is healthy (HTTP ${health_port}${health_path})"
        return 0
    else
        log_error "Health check failed after ${timeout}s"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Health check via TCP port
#------------------------------------------------------------------------------
ssh_health_check_tcp() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_user="${2:-${REMOTE_USER:-}}"
    local ssh_key="${3:-${SSH_KEY:-${HOME}/.ssh/id_rsa}}"
    local health_port="$4"
    local timeout="${5:-30}"
    
    # Expand ~ if present
    ssh_key="${ssh_key/#\~/$HOME}"
    
    log_info "Checking if port ${health_port} is listening..."
    
    local check_script="
for i in \$(seq 1 ${timeout}); do
    if nc -z localhost ${health_port} 2>/dev/null || ss -ln | grep -q ':${health_port} '; then
        echo 'OK'
        exit 0
    fi
    sleep 1
done
echo 'TIMEOUT'
exit 1
"
    
    local result
    result=$(ssh -i "$ssh_key" -o BatchMode=yes "${remote_user}@${remote_host}" "$check_script" 2>/dev/null)
    
    if [[ "$result" == "OK" ]]; then
        log_success "Service is listening on port ${health_port}"
        return 0
    else
        log_error "Health check failed: port ${health_port} not listening"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Get container logs
#------------------------------------------------------------------------------
ssh_get_logs() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_user="${2:-${REMOTE_USER:-}}"
    local ssh_key="${3:-${SSH_KEY:-${HOME}/.ssh/id_rsa}}"
    local container_name="$4"
    local lines="${5:-100}"
    
    # Expand ~ if present
    ssh_key="${ssh_key/#\~/$HOME}"
    
    ssh -i "$ssh_key" -o BatchMode=yes "${remote_user}@${remote_host}" \
        "docker logs --tail=${lines} ${container_name} 2>&1"
}

#------------------------------------------------------------------------------
# Get current running image tag
#------------------------------------------------------------------------------
ssh_get_current_tag() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_user="${2:-${REMOTE_USER:-}}"
    local ssh_key="${3:-${SSH_KEY:-${HOME}/.ssh/id_rsa}}"
    local container_name="$4"
    
    # Expand ~ if present
    ssh_key="${ssh_key/#\~/$HOME}"
    
    ssh -i "$ssh_key" -o BatchMode=yes "${remote_user}@${remote_host}" \
        "docker inspect --format='{{.Config.Image}}' ${container_name} 2>/dev/null | cut -d: -f2" 2>/dev/null
}

#------------------------------------------------------------------------------
# Dry-run: Show what would be executed
#------------------------------------------------------------------------------
ssh_deploy_dry_run() {
    local remote_host="${1:-${REMOTE_HOST:-}}"
    local remote_compose_dir="${2:-${REMOTE_COMPOSE_DIR:-}}"
    local image_name="$3"
    local tag="$4"
    local service_name="$5"
    
    echo ""
    log_dry "ssh ${remote_host}"
    log_dry "  cd ${remote_compose_dir}"
    log_dry "  sed -i 's|image: ${image_name}:.*|image: ${image_name}:${tag}|' docker-compose.yaml"
    log_dry "  docker compose pull ${service_name}"
    log_dry "  docker compose up -d --no-deps --force-recreate ${service_name}"
}
