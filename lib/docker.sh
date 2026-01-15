#!/usr/bin/env bash
#==============================================================================
# DOCKER.SH - Docker build and push operations
#==============================================================================

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/colors.sh"

#------------------------------------------------------------------------------
# Docker login
#------------------------------------------------------------------------------
docker_login() {
    local username="${DOCKERHUB_USERNAME:-}"
    local password="${DOCKERHUB_PASSWORD:-}"
    local registry="${DOCKER_REGISTRY:-docker.io}"
    
    if [[ -z "$username" || -z "$password" ]]; then
        log_error "DOCKERHUB_USERNAME or DOCKERHUB_PASSWORD not set"
        return 1
    fi
    
    log_info "Logging in to ${registry} as ${username}"
    
    if echo "$password" | docker login "$registry" -u "$username" --password-stdin; then
        log_success "Docker login successful"
        return 0
    else
        log_error "Docker login failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Build Docker image
#------------------------------------------------------------------------------
docker_build() {
    local image_name="$1"
    local tag="$2"
    local context_dir="${3:-.}"
    local dockerfile="${4:-Dockerfile}"
    shift 4 || true
    local build_args=()
    [[ $# -gt 0 ]] && build_args=("$@")
    
    local full_image="${image_name}:${tag}"
    
    log_info "Building image: $full_image"
    log_info "Context: $context_dir"
    
    # Build command array
    local cmd=(docker build)
    
    # Add build args
    if [[ ${#build_args[@]} -gt 0 ]]; then
        for arg in "${build_args[@]}"; do
            if [[ -n "$arg" ]]; then
                cmd+=(--build-arg "$arg")
            fi
        done
    fi
    
    # Add dockerfile if not default
    if [[ "$dockerfile" != "Dockerfile" ]]; then
        cmd+=(-f "$dockerfile")
    fi
    
    cmd+=(-t "$full_image" "$context_dir")
    
    # Execute
    local start_time
    start_time=$(date +%s)
    
    if "${cmd[@]}"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Image built successfully in ${duration}s"
        return 0
    else
        log_error "Docker build failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Push Docker image
#------------------------------------------------------------------------------
docker_push() {
    local image_name="$1"
    local tag="$2"
    
    local full_image="${image_name}:${tag}"
    
    log_info "Pushing image: $full_image"
    
    local start_time
    start_time=$(date +%s)
    
    if docker push "$full_image"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Image pushed successfully in ${duration}s"
        return 0
    else
        log_error "Docker push failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Tag Docker image
#------------------------------------------------------------------------------
docker_tag() {
    local source_image="$1"
    local target_image="$2"
    
    log_info "Tagging: $source_image -> $target_image"
    
    if docker tag "$source_image" "$target_image"; then
        log_success "Image tagged successfully"
        return 0
    else
        log_error "Docker tag failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Pull Docker image
#------------------------------------------------------------------------------
docker_pull() {
    local image_name="$1"
    local tag="$2"
    
    local full_image="${image_name}:${tag}"
    
    log_info "Pulling image: $full_image"
    
    if docker pull "$full_image"; then
        log_success "Image pulled successfully"
        return 0
    else
        log_error "Docker pull failed"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Get image digest
#------------------------------------------------------------------------------
docker_get_digest() {
    local image_name="$1"
    local tag="$2"
    
    local full_image="${image_name}:${tag}"
    
    docker inspect --format='{{index .RepoDigests 0}}' "$full_image" 2>/dev/null | cut -d@ -f2
}

#------------------------------------------------------------------------------
# Check if image exists locally
#------------------------------------------------------------------------------
docker_image_exists_locally() {
    local image_name="$1"
    local tag="$2"
    
    local full_image="${image_name}:${tag}"
    
    docker image inspect "$full_image" &>/dev/null
}

#------------------------------------------------------------------------------
# Check if image exists in registry
#------------------------------------------------------------------------------
docker_image_exists_remote() {
    local image_name="$1"
    local tag="$2"
    
    local full_image="${image_name}:${tag}"
    
    docker manifest inspect "$full_image" &>/dev/null
}

#------------------------------------------------------------------------------
# Get image size
#------------------------------------------------------------------------------
docker_get_image_size() {
    local image_name="$1"
    local tag="$2"
    
    local full_image="${image_name}:${tag}"
    
    docker image inspect "$full_image" --format='{{.Size}}' 2>/dev/null
}

#------------------------------------------------------------------------------
# Build and push in one step
#------------------------------------------------------------------------------
docker_build_and_push() {
    local image_name="$1"
    local tag="$2"
    local context_dir="${3:-.}"
    local dockerfile="${4:-Dockerfile}"
    shift 4 || true
    local build_args=()
    [[ $# -gt 0 ]] && build_args=("$@")
    
    # Build
    if ! docker_build "$image_name" "$tag" "$context_dir" "$dockerfile" "${build_args[@]:+${build_args[@]}}"; then
        return 1
    fi
    
    # Push
    if ! docker_push "$image_name" "$tag"; then
        return 1
    fi
    
    return 0
}

#------------------------------------------------------------------------------
# Dry-run: Show what would be executed
#------------------------------------------------------------------------------
docker_build_dry_run() {
    local image_name="$1"
    local tag="$2"
    local context_dir="${3:-.}"
    local dockerfile="${4:-Dockerfile}"
    shift 4 || true
    local build_args=()
    [[ $# -gt 0 ]] && build_args=("$@")
    
    local full_image="${image_name}:${tag}"
    
    echo ""
    log_dry "docker build \\"
    
    if [[ ${#build_args[@]} -gt 0 ]]; then
        for arg in "${build_args[@]}"; do
            if [[ -n "$arg" ]]; then
                echo "    --build-arg \"$arg\" \\"
            fi
        done
    fi
    
    if [[ "$dockerfile" != "Dockerfile" ]]; then
        echo "    -f \"$dockerfile\" \\"
    fi
    
    echo "    -t \"$full_image\" \\"
    echo "    \"$context_dir\""
    echo ""
    log_dry "docker push \"$full_image\""
}
