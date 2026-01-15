#!/usr/bin/env bash
#==============================================================================
# UTILS.SH - Common utility functions
#==============================================================================

# Get script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Get project root (parent of lib/)
get_project_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# Get current git commit SHA (short)
get_git_sha() {
    local length="${1:-7}"
    git rev-parse --short="${length}" HEAD 2>/dev/null || echo "unknown"
}

# Get current git branch
get_git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

# Check if string is empty
is_empty() {
    [[ -z "${1:-}" ]]
}

# Check if string is not empty
is_not_empty() {
    [[ -n "${1:-}" ]]
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Source a file if it exists
source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# Load environment variables from file
load_env_file() {
    local env_file="$1"
    
    if [[ ! -f "$env_file" ]]; then
        log_error "Environment file not found: $env_file"
        return 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Export the variable
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            export "$line"
        fi
    done < "$env_file"
}

# Get environment value with fallback
get_env() {
    local var_name="$1"
    local default="${2:-}"
    
    local value="${!var_name:-$default}"
    echo "$value"
}

# Require environment variable to be set
require_env() {
    local var_name="$1"
    local value="${!var_name:-}"
    
    if [[ -z "$value" ]]; then
        log_error "Required environment variable not set: $var_name"
        return 1
    fi
}

# Get relative time (e.g., "2 minutes ago")
relative_time() {
    local seconds="$1"
    
    if ((seconds < 60)); then
        echo "${seconds}s"
    elif ((seconds < 3600)); then
        echo "$((seconds / 60))m $((seconds % 60))s"
    else
        echo "$((seconds / 3600))h $((seconds % 3600 / 60))m"
    fi
}

# Create lock file for deployment
create_lock() {
    local lock_file="${1:-/tmp/deploy.lock}"
    local service="${2:-unknown}"
    
    if [[ -f "$lock_file" ]]; then
        local lock_info
        lock_info=$(cat "$lock_file")
        log_error "Deployment already in progress: $lock_info"
        return 1
    fi
    
    echo "service=${service},pid=$$,started=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$lock_file"
    trap "rm -f '$lock_file'" EXIT
}

# Remove lock file
remove_lock() {
    local lock_file="${1:-/tmp/deploy.lock}"
    rm -f "$lock_file"
}

# Generate deployment ID
generate_deploy_id() {
    echo "deploy-$(date +%Y%m%d-%H%M%S)-$(get_git_sha 4)"
}

# Format bytes to human readable
format_bytes() {
    local bytes="$1"
    
    if ((bytes < 1024)); then
        echo "${bytes}B"
    elif ((bytes < 1048576)); then
        echo "$((bytes / 1024))KB"
    elif ((bytes < 1073741824)); then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Parse service config from services.env
get_service_config() {
    local service_name="$1"
    local config_key="$2"
    local config_file="${DEPLOY_ROOT:-$(get_project_root)}/config/services.env"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    local full_key="${service_name^^}_${config_key^^}"
    full_key="${full_key//-/_}"
    
    grep -E "^${full_key}=" "$config_file" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'"
}

# List all configured services
list_services() {
    local config_file="${DEPLOY_ROOT:-$(get_project_root)}/config/services.env"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    grep -E "^SERVICES=" "$config_file" | cut -d= -f2- | tr ',' '\n' | tr -d '"' | tr -d "'"
}

# Check if service exists in config
service_exists() {
    local service_name="$1"
    list_services | grep -qx "$service_name"
}

# Backup current state
backup_current_state() {
    local service_name="$1"
    local backup_dir="${DEPLOY_ROOT:-$(get_project_root)}/.deploy-backups"
    local backup_file="${backup_dir}/${service_name}.last"
    
    mkdir -p "$backup_dir"
    
    local current_tag
    current_tag=$(get_service_config "$service_name" "last_deployed_tag" 2>/dev/null || echo "")
    
    if [[ -n "$current_tag" ]]; then
        echo "$current_tag" > "$backup_file"
    fi
}

# Get last deployed tag for rollback
get_rollback_tag() {
    local service_name="$1"
    local backup_dir="${DEPLOY_ROOT:-$(get_project_root)}/.deploy-backups"
    local backup_file="${backup_dir}/${service_name}.last"
    
    if [[ -f "$backup_file" ]]; then
        cat "$backup_file"
    fi
}
