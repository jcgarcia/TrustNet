#!/bin/bash
# setup-motd.sh - Create welcome banner for Factory VM
#
# Creates /etc/motd with information about installed tools,
# Jenkins access, and quick start guide.

################################################################################
# Setup Welcome Banner (MOTD)
################################################################################

setup_motd_via_ssh() {
    log "Creating welcome banner..."
    
    # Create MOTD via SSH (use bash to avoid ash syntax issues)
    if ssh -i "$VM_SSH_PRIVATE_KEY" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        -p "$VM_SSH_PORT" \
        root@localhost 'bash -s' << 'MOTD_SCRIPT'
cat > /etc/motd << 'MOTD_EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🔗  TrustNet Node - Blockchain Platform          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Welcome to your TrustNet blockchain node!

📦 Installed Tools:
  • Go 1.25.6       - Programming language
  • Ignite CLI      - Cosmos SDK scaffolding
  • Git, Make, GCC  - Build tools
  • Caddy           - HTTPS web server

🌐 TrustNet Services:
  Web UI:    https://trustnet.local
  Node RPC:  https://trustnet.local:26657
  API:       https://trustnet.local:1317
  
  SSH Access: ssh trustnet

📁 Storage:
  System:    /         (20 GB)
  Cache:     /var/cache/trustnet-build (5 GB)
  Data:      /var/lib/trustnet (30 GB) - Blockchain data

🔒 Security:
  • SSH: Key-based authentication only
  • HTTPS: Self-signed certificate (365 days)
  • User: warden (passwordless sudo/doas)

📖 Configuration:
  Node config:  ~/trustnet/config/config.toml
  Credentials:  ~/vms/trustnet/credentials.txt (on host)

💡 Quick Start:
  1. Access Web UI: https://trustnet.local
  2. Check Caddy:   doas rc-service caddy status
  3. Start Caddy:   doas rc-service caddy start
  4. View logs:     doas rc-service caddy log

═══════════════════════════════════════════════════════════════
MOTD_EOF
MOTD_SCRIPT
    then
        log_success "  ✓ Welcome banner created"
        return 0
    else
        log_warning "  Failed to create welcome banner (continuing anyway)"
        return 1
    fi
}

################################################################################
# Module Initialization
################################################################################

# Verify this module is being sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: setup-motd.sh should be sourced, not executed directly"
    echo "Usage: source ${BASH_SOURCE[0]}"
    exit 1
fi

# Export functions
export -f setup_motd_via_ssh
