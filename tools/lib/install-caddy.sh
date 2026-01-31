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
    cat > /tmp/Caddyfile << 'CADDY_EOF'
factory.local {
    reverse_proxy localhost:8080
    tls /etc/caddy/certs/factory.crt /etc/caddy/certs/factory.key
}
CADDY_EOF
    
    # Install Caddy
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        foreman@localhost << 'EOF'
echo "Installing Caddy..."
sudo apk add caddy

echo "Creating Caddy configuration and certificate directories..."
sudo mkdir -p /etc/caddy
sudo mkdir -p /etc/caddy/certs

echo "Generating 365-day self-signed certificate for factory.local..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/caddy/certs/factory.key \
    -out /etc/caddy/certs/factory.crt \
    -subj '/CN=factory.local' \
    -addext 'subjectAltName=DNS:factory.local'

sudo chown caddy:caddy /etc/caddy/certs/*
sudo chmod 600 /etc/caddy/certs/*
EOF
    
    # Copy Caddyfile
    scp -i "$VM_SSH_PRIVATE_KEY" -P "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        /tmp/Caddyfile foreman@localhost:/tmp/
    
    # Configure and start Caddy
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        foreman@localhost << 'EOF'
sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile

echo "Starting Caddy service..."
sudo rc-update add caddy boot
sudo service caddy start

sleep 2

if sudo service caddy status | grep -q "started"; then
    echo "✓ Caddy is running with 365-day certificate"
else
    echo "⚠ Caddy may not be running properly"
fi
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
