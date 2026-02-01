#!/bin/bash
# install-certificates.sh - Install TrustNet Caddy CA certificate on host system
# Adapted from FactoryVM install-certificates.sh
# Updated Feb 1, 2026: Use Caddy's automatic CA instead of self-signed certificates

# Prevent direct execution
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

install_certificates_on_host() {
    log "Installing TrustNet Caddy CA certificate on host system..."
    
    local cert_file="${VM_DIR}/trustnet-caddy-ca.crt"
    local cert_installed=false
    
    # Wait for Caddy to generate its internal CA (takes a few seconds)
    sleep 3
    
    # Retrieve Caddy's root CA certificate from VM
    log_info "  Retrieving Caddy root CA certificate from VM..."
    if ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        ${VM_USERNAME}@localhost \
        "doas cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt" > "$cert_file" 2>/dev/null; then
        
        log_success "  ✓ Caddy root CA certificate retrieved from VM"
        
        # Install to system trust store (REQUIRED for curl/wget to trust HTTPS)
        log_info "    Removing old TrustNet certificates from system trust store..."
        sudo rm -f /usr/local/share/ca-certificates/trustnet*.crt 2>/dev/null || true
        sudo update-ca-certificates --fresh >/dev/null 2>&1 || true
        
        if sudo cp "$cert_file" /usr/local/share/ca-certificates/trustnet-caddy-ca.crt 2>/dev/null; then
            log_info "    Installing Caddy CA to system trust store..."
            sudo update-ca-certificates >/dev/null 2>&1
            
            if [ -f /usr/local/share/ca-certificates/trustnet-caddy-ca.crt ]; then
                log_success "  ✓ Caddy CA certificate installed to system trust store"
                cert_installed=true
            fi
        else
            log_warning "  Could not install certificate to system trust store (sudo required)"
        fi
        
        # Install to Java truststore (optional for TrustNet - no Jenkins CLI)
        log_info "  Installing to Java truststore..."
        local java_cacerts="/etc/ssl/certs/java/cacerts"
        local java_alias="trustnet-local"
        
        if [ -f "$java_cacerts" ]; then
            # Remove old cert if exists
            sudo keytool -delete -alias "$java_alias" -keystore "$java_cacerts" -storepass changeit 2>/dev/null || true
            
            # Import new cert
            if sudo keytool -importcert -noprompt -alias "$java_alias" -file "$cert_file" -keystore "$java_cacerts" -storepass changeit 2>/dev/null; then
                log_success "  ✓ Certificate installed to Java truststore"
            else
                log_info "    Java truststore installation skipped (not critical for TrustNet)"
            fi
        fi
        
        # Install to browser certificate databases (Chrome/Chromium/Firefox)
        log_info "  Installing to browser certificate databases..."
        local browsers_updated=0
        
        # Install certutil if not present (needed for Chrome/Chromium/Firefox)
        if ! command -v certutil >/dev/null 2>&1; then
            log_info "  Installing libnss3-tools for browser certificate management..."
            sudo apt-get update -qq >/dev/null 2>&1 || true
            sudo apt-get install -y libnss3-tools >/dev/null 2>&1 || true
        fi
        
        if command -v certutil >/dev/null 2>&1; then
            # Helper function to remove old TrustNet certificates
            remove_old_trustnet_certs() {
                local db_path="$1"
                # Remove old server certs
                for i in {1..5}; do
                    certutil -D -d "$db_path" -n "TrustNet SSL" >/dev/null 2>&1 || break
                done
                # Remove old Caddy CA certs from previous installs
                for i in {1..5}; do
                    certutil -D -d "$db_path" -n "Caddy Local CA" >/dev/null 2>&1 || break
                done
            }
            
            # Find all Chromium-based browser profile directories
            local chromium_configs=(
                "$HOME/.config/google-chrome"
                "$HOME/.config/chromium"
                "$HOME/.config/BraveSoftware/Brave-Browser"
                "$HOME/.config/microsoft-edge"
            )
            
            for config_dir in "${chromium_configs[@]}"; do
                if [ -d "$config_dir" ]; then
                    for cert_dir in $(find "$config_dir" -type d \( -name "Default" -o -name "Profile *" \) 2>/dev/null); do
                        if [ -f "$cert_dir/Cookies" ] || [ -f "$cert_dir/History" ]; then
                            remove_old_trustnet_certs "sql:$cert_dir"
                            if certutil -A -d sql:$cert_dir -t "TC,," -n "Caddy Local CA" -i "$cert_file" >/dev/null 2>&1; then
                                browsers_updated=$((browsers_updated + 1))
                            fi
                        fi
                    done
                fi
            done
            
            # Install to system NSS database (used by Chromium browsers as fallback)
            if [ -d ~/.pki/nssdb ]; then
                remove_old_trustnet_certs "sql:$HOME/.pki/nssdb"
                if certutil -A -d sql:$HOME/.pki/nssdb -t "TC,," -n "Caddy Local CA" -i "$cert_file" >/dev/null 2>&1; then
                    browsers_updated=$((browsers_updated + 1))
                fi
            fi
            
            # Find Firefox profiles (regular and Snap installations)
            local firefox_dirs=(
                ~/.mozilla/firefox
                ~/snap/firefox/common/.mozilla/firefox
            )
            
            for firefox_base in "${firefox_dirs[@]}"; do
                if [ -d "$firefox_base" ]; then
                    for cert_dir in "$firefox_base"/*.default* "$firefox_base"/*[Pp]rofile*; do
                        if [ -f "$cert_dir/cert9.db" ] || [ -f "$cert_dir/cert8.db" ]; then
                            remove_old_trustnet_certs "sql:$cert_dir"
                            if certutil -A -d sql:$cert_dir -t "TC,," -n "Caddy Local CA" -i "$cert_file" >/dev/null 2>&1; then
                                browsers_updated=$((browsers_updated + 1))
                            fi
                        fi
                    done
                fi
            done
            
            if [ $browsers_updated -gt 0 ]; then
                log_success "  ✓ Certificate installed to $browsers_updated browser profile(s)"
                log_info "    Supported browsers: Chrome, Chromium, Brave, Edge, Firefox"
                log_info "    Restaddy CA installed to $browsers_updated browser profile(s)"
                log_info "    Supported browsers: Chrome, Chromium, Brave, Edge, Firefox"
                log_info "    Restart browsers to apply changes"
            else
                log_info "  No browser profiles found"
            fi
        else
            log_warning "  certutil not available - skipping browser certificate installation"
        fi
        
        if [ "$cert_installed" = "true" ]; then
            log_success "✓ Caddy CA certificates installed successfully"
            log_info "  https://${VM_HOSTNAME} is now trusted"
            log_info "  Caddy will auto-renew certificates"
        else
            log_warning "Certificate installation had issues"
        fi
    else
        log_warning "Could not retrieve Caddy CA certificate from VM"
        log_info "  Caddy may still be generating certificates - try again in a few seconds
}

# Export functions
export -f install_certificates_on_host
