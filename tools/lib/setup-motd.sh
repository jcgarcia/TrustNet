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
║              🏭  Factory VM - ARM64 Build Server          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Welcome to your automated ARM64 build environment!

📦 Installed Tools:
  • Docker        - Container runtime (docker command)
  • Kubernetes    - kubectl & Helm
  • Terraform     - Infrastructure as Code
  • AWS CLI       - Cloud management
  • Jenkins       - CI/CD automation server
  • Git, Node.js, Python, OpenJDK

🌐 Jenkins CI/CD Server:
  Web UI:    https://factory.local
  Username:  foreman
  Password:  (see ~/.factory-vm/credentials.txt on host)
  
  CLI:       jenkins-factory <command>
             Available on HOST and inside VM
             Examples:
               jenkins-factory who-am-i
               jenkins-factory list-jobs
               jenkins-factory build <job-name>

📁 Storage:
  System:    /         (50 GB)
  Data:      /data     (200 GB) - For build artifacts

🔒 Security:
  • SSH: Key-based authentication only
  • Jenkins: Secure random password
  • HTTPS: Certificate installed on host (trusted connection)

📖 Documentation:
  Factory README: cat /root/FACTORY-README.md
  Installation log: cat /root/factory-install.log

💡 Quick Start:
  1. Configure AWS:  awslogin (on host, then SSH forwards)
  2. Build image:    docker build -t myapp:arm64 .
  3. Access Jenkins: Open https://factory.local in browser

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
