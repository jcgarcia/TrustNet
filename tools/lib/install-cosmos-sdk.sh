#!/bin/bash
#
# TrustNet: Cosmos SDK and Blockchain Client Installer
# Installs Go, Ignite CLI, and TrustNet blockchain client inside Alpine VM
#

install_cosmos_sdk() {
    log "Installing Cosmos SDK and Blockchain Tools..."
    
    # Install dependencies
    log_info "Installing build dependencies..."
    ssh_exec "sudo apk add --no-cache git make gcc musl-dev linux-headers curl jq"
    
    # Install Go (required for Cosmos SDK)
    log_info "Installing Go..."
    
    # Detect latest Go version
    log_info "Detecting latest Go version..."
    local GO_VERSION=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1 | sed 's/go//')
    log_info "Latest Go version: ${GO_VERSION}"
    
    local GO_ARCH="arm64"
    
    # Check if we're on x86_64 (Intel)
    if ssh_exec "uname -m | grep -q x86_64"; then
        GO_ARCH="amd64"
    fi
    
    ssh_exec "cd /tmp && curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz -o go.tar.gz"
    ssh_exec "sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz"
    ssh_exec "rm /tmp/go.tar.gz"
    
    # Configure Go environment for ${VM_USERNAME} user
    ssh_exec "cat >> /home/${VM_USERNAME}/.profile << 'EOF'
export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin
export GOPATH=\$HOME/go
EOF"
    
    # Apply Go environment immediately
    ssh_exec "source /home/${VM_USERNAME}/.profile"
    
    log_success "Go ${GO_VERSION} installed"
    
    # Install Ignite CLI (Cosmos SDK scaffolding tool)
    log_info "Installing Ignite CLI..."
    ssh_exec "source /home/${VM_USERNAME}/.profile && curl -fsSL https://get.ignite.com/cli | bash"
    
    log_success "Ignite CLI installed"
    
    # Verify installations
    log_info "Verifying installations..."
    local GO_VER=$(ssh_exec "source /home/${VM_USERNAME}/.profile && go version" | grep -oP 'go\d+\.\d+\.\d+')
    local IGNITE_VER=$(ssh_exec "source /home/${VM_USERNAME}/.profile && ignite version" | head -n1)
    
    log_success "Go version: ${GO_VER}"
    log_success "Ignite CLI version: ${IGNITE_VER}"
    
    # Create TrustNet directories
    log_info "Creating TrustNet directories..."
    ssh_exec "mkdir -p /home/${VM_USERNAME}/trustnet/{config,data,keys}"
    ssh_exec "chown -R ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/trustnet"
    
    log_success "Cosmos SDK installation complete"
}

configure_trustnet_client() {
    log "Configuring TrustNet Blockchain Client..."
    
    # Create TrustNet configuration using SSH heredoc (same pattern as install-caddy.sh)
    log_info "Creating TrustNet configuration..."
    
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        ${VM_USERNAME}@localhost << EOF
mkdir -p /home/${VM_USERNAME}/trustnet/config /home/${VM_USERNAME}/trustnet/data /home/${VM_USERNAME}/trustnet/keys
chown -R ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/trustnet

cat > /home/${VM_USERNAME}/trustnet/config/config.toml << 'CONFIG_EOF'
# TrustNet Node Configuration

[node]
# Node name (user-friendly identifier)
name = \"trustnet-node\"

# Network to connect to (hub or specific network)
network = \"trustnet-hub\"

[blockchain]
# RPC endpoint (connect to TrustNet Hub validators)
rpc_endpoint = \"https://rpc.trustnet.network:26657\"

# REST API endpoint
api_endpoint = \"https://api.trustnet.network:1317\"

# gRPC endpoint
grpc_endpoint = \"grpc.trustnet.network:9090\"

[p2p]
# Enable P2P networking
enabled = true

# P2P port
port = 26656

# Persistent peers (seed nodes)
persistent_peers = \"\"

[identity]
# Path to keypair (generated on first run)
keyring_backend = \"file\"
keyring_dir = "/home/${VM_USERNAME}/trustnet/keys"

[web]
# Web UI port (served via Caddy HTTPS)
port = 8080
CONFIG_EOF

chown ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/trustnet/config/config.toml
EOF
    
    log_success "TrustNet configuration created"
    
    # Create TrustNet systemd service
    log_info "Creating TrustNet systemd service..."
    
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        ${VM_USERNAME}@localhost << 'EOF'
cat > /tmp/trustnet-service << 'SERVICE_EOF'
#!/sbin/openrc-run

name=\"TrustNet Node\"
description=\"TrustNet Blockchain Client\"

command="/home/${VM_USERNAME}/trustnet/bin/trustnetd"
command_args="start --home /home/${VM_USERNAME}/trustnet"
command_user="${VM_USERNAME}:${VM_USERNAME}"
command_background=\"yes\"
pidfile=\"/run/trustnet.pid\"

depend() {
    need net
    after caddy
}

start_pre() {
    checkpath --directory --owner ${VM_USERNAME}:${VM_USERNAME} --mode 0755 /home/${VM_USERNAME}/trustnet/data
}
SERVICE_EOF

sudo mv /tmp/trustnet-service /etc/init.d/trustnet
sudo chmod +x /etc/init.d/trustnet
sudo rc-update add trustnet default
EOF
    
    log_success "TrustNet service configured (will start after blockchain client is built)"
}

install_trustnet_web_ui() {
    log "Installing TrustNet Web UI..."
    
    # Create simple web UI directory and HTML file via SSH heredoc
    log_info "Creating web UI..."
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "${VM_USERNAME}@localhost" << 'EOF'
# Create directory with sudo
sudo mkdir -p /var/www/trustnet
sudo chown warden:warden /var/www/trustnet

# Create HTML file in /tmp first, then move
cat > /tmp/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>TrustNet Node</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            max-width: 800px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 { font-size: 2.5em; margin-bottom: 10px; }
        .subtitle { opacity: 0.9; margin-bottom: 30px; }
        .status {
            background: rgba(255,255,255,0.2);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        .status-item:last-child { border-bottom: none; }
        .status-value {
            font-weight: bold;
            color: #4ade80;
        }
        .button {
            background: #4ade80;
            color: #1a1a1a;
            padding: 12px 30px;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            margin: 10px 5px;
        }
        .button:hover { background: #22c55e; }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>🔗 TrustNet Node</h1>
        <p class=\"subtitle\">Decentralized Trust Network - Web3 Identity & Reputation</p>
        
        <div class=\"status\">
            <h2>Node Status</h2>
            <div class=\"status-item\">
                <span>Blockchain Network:</span>
                <span class=\"status-value\" id=\"network\">TrustNet Hub</span>
            </div>
            <div class=\"status-item\">
                <span>Connection Status:</span>
                <span class=\"status-value\" id=\"connection\">Connecting...</span>
            </div>
            <div class=\"status-item\">
                <span>Identity:</span>
                <span class=\"status-value\" id=\"identity\">Not registered</span>
            </div>
            <div class=\"status-item\">
                <span>Reputation:</span>
                <span class=\"status-value\" id=\"reputation\">-</span>
            </div>
            <div class=\"status-item\">
                <span>TRUST Balance:</span>
                <span class=\"status-value\" id=\"balance\">0 TRUST</span>
            </div>
        </div>
        
        <div style=\"text-align: center; margin-top: 30px;\">
            <button class=\"button\" onclick=\"registerIdentity()\">Register Identity</button>
            <button class=\"button\" onclick=\"viewTransactions()\">View Transactions</button>
            <button class=\"button\" onclick=\"manageKeys()\">Manage Keys</button>
        </div>
        
        <div style=\"margin-top: 30px; text-align: center; opacity: 0.7; font-size: 0.9em;\">
            <p>TrustNet Node v1.0.0 | Cosmos SDK | Tendermint BFT</p>
            <p style=\"margin-top: 5px;\">Served via Caddy HTTPS with Let's Encrypt</p>
        </div>
    </div>
    
    <script>
        // Placeholder functions (will connect to blockchain RPC)
        function registerIdentity() {
            alert('Identity registration coming soon!\\nThis will create a cryptographic keypair and register on TrustNet Hub.');
        }
        
        function viewTransactions() {
            alert('Transaction history coming soon!\\nThis will query the blockchain for your transaction history.');
        }
        
        function manageKeys() {
            alert('Key management coming soon!\\nThis will allow you to backup/restore your identity keys.');
        }
        
        // Simulate connection status update
        setTimeout(() => {
            document.getElementById('connection').textContent = 'Connected';
            document.getElementById('connection').style.color = '#4ade80';
        }, 2000);
    </script>
</body>
</html>
HTML_EOF
# Move to final location and set readable permissions
mv /tmp/index.html /var/www/trustnet/index.html
chmod 644 /var/www/trustnet/index.html
EOF
    
    log_success "Web UI installed at /var/www/trustnet"
}

# Main installation function
install_blockchain_stack() {
    install_cosmos_sdk
    configure_trustnet_client
    install_trustnet_web_ui
}
