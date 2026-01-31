#!/bin/bash
# install-caddy.sh - Install Caddy reverse proxy on Factory VM
# Part of Phase 3.5 modular architecture

# Prevent direct execution
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

install_caddy_via_ssh() {
    log_info "Installing Caddy reverse proxy via SSH..."
    
    # Create Caddyfile content - uses explicit cert files (not tls internal which expires in 12h)
    cat > /tmp/Caddyfile << CADDY_EOF
${VM_HOSTNAME} {
    reverse_proxy localhost:8080
    tls /etc/caddy/certs/${VM_HOSTNAME}.crt /etc/caddy/certs/${VM_HOSTNAME}.key
}
CADDY_EOF
    
    # Install Caddy
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        ${VM_USERNAME}@localhost << EOF
echo "Enabling Alpine community repository..."
sudo sed -i 's/#.*community//' /etc/apk/repositories
sudo apk update

echo "Installing Caddy..."
sudo apk add caddy

echo "Creating Caddy configuration and certificate directories..."
sudo mkdir -p /etc/caddy
sudo mkdir -p /etc/caddy/certs

echo "Generating 365-day self-signed certificate for ${VM_HOSTNAME}..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\
    -keyout /etc/caddy/certs/${VM_HOSTNAME}.key \\
    -out /etc/caddy/certs/${VM_HOSTNAME}.crt \\
    -subj '/CN=${VM_HOSTNAME}' \\
    -addext 'subjectAltName=DNS:${VM_HOSTNAME}'

sudo chmod 644 /etc/caddy/certs/${VM_HOSTNAME}.crt
sudo chmod 600 /etc/caddy/certs/${VM_HOSTNAME}.key
EOF
    
    # Copy Caddyfile
    scp -i "$VM_SSH_PRIVATE_KEY" -P "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        /tmp/Caddyfile ${VM_USERNAME}@localhost:/tmp/
    
    # Configure and start Caddy
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        ${VM_USERNAME}@localhost << 'EOF'
sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile

echo "✓ Caddy installed and configured"
echo "Note: Caddy can be started manually with: caddy run --config /etc/caddy/Caddyfile"
EOF
    
    rm -f /tmp/Caddyfile
    
    if [ $? -eq 0 ]; then
        log_success "✓ Caddy installed and configured with 365-day certificate"
    else
        log_error "Caddy installation failed"
        return 1
    fi
}

# Export functions
export -f install_caddy_via_ssh
