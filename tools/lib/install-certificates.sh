#!/bin/bash
# install-certificates.sh - Install Factory SSL certificate on host system
# Part of Phase 3.5 modular architecture
# Updated Dec 6, 2025: Use 365-day self-signed cert instead of Caddy's tls internal

# Prevent direct execution
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

install_certificates_on_host() {
    log "Installing Factory SSL certificate on host system..."
    
    local cert_file="${VM_DIR}/factory-ssl.crt"
    local cert_installed=false
    
    # Wait a moment for Caddy to be ready
    sleep 2
    
    # Retrieve SSL certificate from VM (365-day self-signed cert)
    log_info "  Retrieving SSL certificate from VM..."
    if ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        foreman@localhost \
        "sudo cat /etc/caddy/certs/factory.crt" > "$cert_file" 2>/dev/null; then
        
        log_success "  ✓ SSL certificate retrieved from VM (365-day validity)"
        
        # Install to system trust store (REQUIRED for curl/wget to trust HTTPS)
        log_info "    Removing old Factory certificates from system trust store..."
        sudo rm -f /usr/local/share/ca-certificates/caddy*.crt 2>/dev/null || true
        sudo rm -f /usr/local/share/ca-certificates/factory*.crt 2>/dev/null || true
        sudo update-ca-certificates --fresh >/dev/null 2>&1 || true
        
        if sudo cp "$cert_file" /usr/local/share/ca-certificates/factory-ssl.crt 2>/dev/null; then
            log_info "    Installing to system trust store..."
            sudo update-ca-certificates >/dev/null 2>&1
            
            if [ -f /usr/local/share/ca-certificates/factory-ssl.crt ]; then
                log_success "  ✓ Certificate installed to system trust store"
                cert_installed=true
            fi
        else
            log_warning "  Could not install certificate to system trust store (sudo required)"
        fi
        
        # Install to Java truststore (REQUIRED for jenkins-factory CLI)
        log_info "  Installing to Java truststore for jenkins-factory CLI..."
        local java_cacerts="/etc/ssl/certs/java/cacerts"
        local java_alias="factory-local"
        
        if [ -f "$java_cacerts" ]; then
            # Remove old cert if exists
            sudo keytool -delete -alias "$java_alias" -keystore "$java_cacerts" -storepass changeit 2>/dev/null || true
            
            # Import new cert
            if sudo keytool -importcert -noprompt -alias "$java_alias" -file "$cert_file" -keystore "$java_cacerts" -storepass changeit 2>/dev/null; then
                log_success "  ✓ Certificate installed to Java truststore"
                log_info "    jenkins-factory CLI will work without certificate errors"
            else
                log_warning "  Could not install certificate to Java truststore"
            fi
        else
            log_warning "  Java truststore not found at $java_cacerts"
            log_info "    Run ~/.scripts/refresh-factory-cert.sh manually if jenkins-factory fails"
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
            # Helper function to remove old Factory certificates
            remove_old_factory_certs() {
                local db_path="$1"
                for i in {1..5}; do
                    certutil -D -d "$db_path" -n "Factory SSL" >/dev/null 2>&1 || break
                done
                # Also remove old Caddy certs from previous installs
                for i in {1..5}; do
                    certutil -D -d "$db_path" -n "Caddy Local CA - Factory" >/dev/null 2>&1 || break
                done
                for i in {1..5}; do
                    certutil -D -d "$db_path" -n "Caddy Intermediate CA - Factory" >/dev/null 2>&1 || break
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
                            remove_old_factory_certs "sql:$cert_dir"
                            if certutil -A -d sql:$cert_dir -t "CT,C,C" -n "Factory SSL" -i "$cert_file" >/dev/null 2>&1; then
                                browsers_updated=$((browsers_updated + 1))
                            fi
                        fi
                    done
                fi
            done
            
            # Install to system NSS database (used by Chromium browsers as fallback)
            if [ -d ~/.pki/nssdb ]; then
                remove_old_factory_certs "sql:$HOME/.pki/nssdb"
                if certutil -A -d sql:$HOME/.pki/nssdb -t "CT,C,C" -n "Factory SSL" -i "$cert_file" >/dev/null 2>&1; then
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
                            remove_old_factory_certs "sql:$cert_dir"
                            if certutil -A -d sql:$cert_dir -t "CT,C,C" -n "Factory SSL" -i "$cert_file" >/dev/null 2>&1; then
                                browsers_updated=$((browsers_updated + 1))
                            fi
                        fi
                    done
                fi
            done
            
            if [ $browsers_updated -gt 0 ]; then
                log_success "  ✓ Certificate installed to $browsers_updated browser profile(s)"
                log_info "    Supported browsers: Chrome, Chromium, Brave, Edge, Firefox"
                log_info "    Restart browsers to apply changes"
            else
                log_info "  No browser profiles found"
            fi
        else
            log_warning "  certutil not available - skipping browser certificate installation"
        fi
        
        if [ "$cert_installed" = "true" ]; then
            log_success "✓ Certificates installed successfully"
            log_info "  https://factory.local is now trusted"
            log_info "  Certificate valid for 365 days"
        else
            log_warning "Certificate installation had issues"
        fi
    else
        log_warning "Could not retrieve SSL certificate from VM"
        log_info "  You may see security warnings until certificates are installed"
    fi
}

# Export functions
export -f install_certificates_on_host
