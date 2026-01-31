#!/bin/bash
# cache-manager.sh - Download and cache tools for Factory VM
#
# Downloads and caches:
# - Tool binaries (Terraform, kubectl, Helm)
# - AWS CLI
# - Jenkins Docker image
# - Jenkins plugins
#
# All downloads are cached in tools/cache/ to speed up subsequent installations

################################################################################
# Configuration
################################################################################

# Get script directory (tools/lib/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use existing CACHE_DIR if set (from setup-factory-vm.sh), otherwise use local cache
# This allows ~/.factory-vm/cache when called from installer, or tools/cache when standalone
CACHE_DIR="${CACHE_DIR:-$(dirname "$SCRIPT_DIR")/cache}"

# Tool versions - will be detected at runtime
export TERRAFORM_VERSION="${TERRAFORM_VERSION:-}"
export KUBECTL_VERSION="${KUBECTL_VERSION:-}"
export HELM_VERSION="${HELM_VERSION:-}"
export JENKINS_VERSION="${JENKINS_VERSION:-lts-jdk21}"

################################################################################
# Version Detection
################################################################################

get_latest_alpine_version() {
    # Try to get latest stable version from Alpine's release page
    local latest_version=$(curl -s https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ALPINE_ARCH}/latest-releases.yaml 2>/dev/null | grep -m1 'version:' | awk '{print $2}' | cut -d. -f1,2)
    
    # Fallback to known stable version if auto-detection fails
    if [ -z "$latest_version" ]; then
        echo "3.22"
    else
        echo "$latest_version"
    fi
}

get_latest_terraform_version() {
    local latest=$(curl -sL https://api.github.com/repos/hashicorp/terraform/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    echo "${latest:-1.6.6}"
}

get_latest_kubectl_version() {
    local latest=$(curl -sL https://dl.k8s.io/release/stable.txt 2>/dev/null | sed 's/^v//')
    echo "${latest:-1.28.4}"
}

get_latest_helm_version() {
    local latest=$(curl -sL https://api.github.com/repos/helm/helm/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    echo "${latest:-3.13.3}"
}

################################################################################
# Download Functions
################################################################################

download_and_cache_terraform() {
    local version="$1"
    local cache_file="${CACHE_DIR}/terraform/terraform_${version}_linux_arm64.zip"
    
    if [ -f "$cache_file" ]; then
        log_info "Terraform ${version} already cached"
        return 0
    fi
    
    log_info "Downloading Terraform ${version}..."
    mkdir -p "${CACHE_DIR}/terraform"
    if curl -sL "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_arm64.zip" \
        -o "$cache_file"; then
        log_success "Terraform ${version} cached"
    else
        log_error "Failed to download Terraform"
        return 1
    fi
}

download_and_cache_kubectl() {
    local version="$1"
    local cache_file="${CACHE_DIR}/kubectl/kubectl_${version}"
    
    if [ -f "$cache_file" ]; then
        log_info "kubectl ${version} already cached"
        return 0
    fi
    
    log_info "Downloading kubectl ${version}..."
    mkdir -p "${CACHE_DIR}/kubectl"
    if curl -sL "https://dl.k8s.io/release/v${version}/bin/linux/arm64/kubectl" \
        -o "$cache_file"; then
        chmod +x "$cache_file"
        log_success "kubectl ${version} cached"
    else
        log_error "Failed to download kubectl"
        return 1
    fi
}

download_and_cache_helm() {
    local version="$1"
    local cache_file="${CACHE_DIR}/helm/helm-v${version}-linux-arm64.tar.gz"
    
    if [ -f "$cache_file" ]; then
        log_info "Helm ${version} already cached"
        return 0
    fi
    
    log_info "Downloading Helm ${version}..."
    mkdir -p "${CACHE_DIR}/helm"
    if curl -sL "https://get.helm.sh/helm-v${version}-linux-arm64.tar.gz" \
        -o "$cache_file"; then
        log_success "Helm ${version} cached"
    else
        log_error "Failed to download Helm"
        return 1
    fi
}

download_and_cache_awscli() {
    local cache_file="${CACHE_DIR}/awscli/awscli-latest-aarch64.zip"
    
    # Debug: Show what we're looking for
    [ "${DEBUG:-}" = "1" ] && echo "[DEBUG] Checking for AWS CLI cache at: $cache_file" >&2
    
    if [ -f "$cache_file" ]; then
        log_info "AWS CLI already cached"
        return 0
    fi
    
    log_info "Downloading AWS CLI v2..."
    mkdir -p "${CACHE_DIR}/awscli"
    
    # Use temporary file to avoid partial downloads
    local temp_file="${cache_file}.tmp"
    if curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" \
        -o "$temp_file" && [ -s "$temp_file" ]; then
        mv "$temp_file" "$cache_file"
        log_success "AWS CLI cached"
        return 0
    else
        rm -f "$temp_file"
        log_error "Failed to download AWS CLI"
        return 1
    fi
}

download_and_cache_ansible() {
    local cache_file="${CACHE_DIR}/ansible/ansible-requirements.txt"
    
    if [ -f "$cache_file" ]; then
        log_info "Ansible requirements already cached"
        return 0
    fi
    
    log_info "Creating Ansible requirements file..."
    mkdir -p "${CACHE_DIR}/ansible"
    
    # Create a requirements file for pip to cache
    cat > "$cache_file" << 'EOF'
ansible>=2.16
boto3>=1.34
botocore>=1.34
EOF
    
    log_success "Ansible requirements cached"
    return 0
}

download_and_cache_jenkins_image() {
    local cache_file="${CACHE_DIR}/jenkins/jenkins-lts-jdk21.tar"
    
    if [ -f "$cache_file" ]; then
        log_info "Jenkins Docker image already cached"
        return 0
    fi
    
    log_info "Downloading Jenkins Docker image (jenkins/jenkins:lts-jdk21)..."
    log_info "This is a ~1.5GB download, will take 8-10 minutes on first run"
    mkdir -p "${CACHE_DIR}/jenkins"
    
    # Use skopeo to download Docker image without requiring Docker daemon
    if command -v skopeo &>/dev/null; then
        # Download using skopeo with OCI format (preserves tags correctly)
        if skopeo copy docker://jenkins/jenkins:lts-jdk21 oci-archive:"$cache_file":lts-jdk21 2>/dev/null; then
            log_success "Jenkins image cached ($(du -h "$cache_file" | cut -f1))"
            return 0
        else
            rm -f "$cache_file"
            log_error "Failed to download Jenkins image with skopeo"
            return 1
        fi
    else
        log_warning "skopeo not found, Jenkins image will be downloaded in VM"
        return 1
    fi
}

################################################################################
# Batch Cache Functions
################################################################################

cache_all_tools() {
    log "Downloading and caching installation files..."
    log_info "First-time downloads will be cached for faster subsequent installations"
    echo ""
    
    # Detect versions
    TERRAFORM_VERSION=$(get_latest_terraform_version)
    KUBECTL_VERSION=$(get_latest_kubectl_version)
    HELM_VERSION=$(get_latest_helm_version)
    
    log_info "Tool versions detected:"
    log_info "  Terraform: ${TERRAFORM_VERSION}"
    log_info "  kubectl: ${KUBECTL_VERSION}"
    log_info "  Helm: ${HELM_VERSION}"
    echo ""
    
    # Download in parallel (background jobs)
    download_and_cache_terraform "$TERRAFORM_VERSION" &
    local terraform_pid=$!
    download_and_cache_kubectl "$KUBECTL_VERSION" &
    local kubectl_pid=$!
    download_and_cache_helm "$HELM_VERSION" &
    local helm_pid=$!
    download_and_cache_awscli &
    local awscli_pid=$!
    download_and_cache_ansible &
    local ansible_pid=$!
    download_and_cache_jenkins_image &
    local jenkins_pid=$!
    
    # Wait for parallel downloads
    wait $terraform_pid
    wait $kubectl_pid
    wait $helm_pid
    wait $awscli_pid
    wait $ansible_pid
    wait $jenkins_pid
    
    log_success "All tools cached and ready for installation"
    echo ""
}

################################################################################
# Jenkins Plugin Caching
################################################################################

download_and_cache_plugin() {
    local plugin_name="$1"
    local cache_file="${CACHE_DIR}/jenkins/plugins/${plugin_name}.hpi"
    
    if [ -f "$cache_file" ]; then
        return 0  # Already cached, silent success
    fi
    
    mkdir -p "${CACHE_DIR}/jenkins/plugins"
    
    # Download plugin using Jenkins update center
    local download_url="https://updates.jenkins.io/latest/${plugin_name}.hpi"
    
    if curl -sL "$download_url" -o "$cache_file" 2>/dev/null; then
        return 0
    else
        rm -f "$cache_file"  # Clean up partial download
        return 1
    fi
}

cache_all_plugins() {
    log "Downloading and caching Jenkins plugins..."
    log_info "First-time downloads will be cached for faster subsequent installations"
    echo ""
    
    # Ensure we don't exit on error during plugin downloads
    set +e
    
    # Plugin list (from plugins.txt in heredoc)
    local plugins=(
        "configuration-as-code"
        "git"
        "git-client"
        "github"
        "github-branch-source"
        "docker-plugin"
        "docker-workflow"
        "workflow-aggregator"
        "pipeline-stage-view"
        "pipeline-github-lib"
        "blueocean"
        "credentials"
        "credentials-binding"
        "plain-credentials"
        "ssh-credentials"
        "aws-credentials"
        "aws-java-sdk"
        "gradle"
        "nodejs"
        "kubernetes"
        "kubernetes-cli"
        "timestamper"
        "build-timeout"
        "ws-cleanup"
        "ansicolor"
    )
    
    local total=${#plugins[@]}
    local cached=0
    local downloaded=0
    local failed=0
    
    log_info "Checking cache for ${total} plugins..."
    echo ""
    
    # Download plugins in parallel (5 at a time to avoid overwhelming the server)
    local batch_size=5
    local i=0
    
    while [ $i -lt $total ]; do
        local pids=()
        local batch_plugins=()
        
        # Start batch of downloads
        for j in $(seq 0 $((batch_size - 1))); do
            local idx=$((i + j))
            if [ $idx -ge $total ]; then
                break
            fi
            
            local plugin="${plugins[$idx]}"
            batch_plugins+=("$plugin")
            
            # Check if already cached
            if [ -f "${CACHE_DIR}/jenkins/plugins/${plugin}.hpi" ]; then
                ((cached++))
                echo "  [${idx}/${total}] ${plugin} (cached)"
            else
                echo -n "  [${idx}/${total}] ${plugin} (downloading)..."
                download_and_cache_plugin "$plugin" &
                pids+=($!)
            fi
        done
        
        # Wait for batch to complete
        for pid in "${pids[@]}"; do
            wait $pid && local result=0 || local result=$?
            if [ $result -eq 0 ]; then
                ((downloaded++))
                echo " ✓"
            else
                ((failed++))
                echo " ✗"
            fi
        done
        
        i=$((i + batch_size))
    done
    
    echo ""
    log_info "Plugin cache summary:"
    log_info "  Already cached: ${cached}"
    log_info "  Downloaded: ${downloaded}"
    if [ $failed -gt 0 ]; then
        log_warning "  Failed: ${failed} (will download inside VM)"
    fi
    
    log_success "Plugins cached and ready for installation"
    echo ""
    
    # Re-enable exit on error
    set -e
}

################################################################################
# Module Initialization
################################################################################

# Verify this module is being sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: cache-manager.sh should be sourced, not executed directly"
    echo "Usage: source ${BASH_SOURCE[0]}"
    exit 1
fi

# Export all functions
export -f get_latest_alpine_version
export -f get_latest_terraform_version
export -f get_latest_kubectl_version
export -f get_latest_helm_version
export -f download_and_cache_terraform
export -f download_and_cache_kubectl
export -f download_and_cache_helm
export -f download_and_cache_awscli
export -f download_and_cache_ansible
export -f download_and_cache_jenkins_image
export -f cache_all_tools
export -f download_and_cache_plugin
export -f cache_all_plugins
