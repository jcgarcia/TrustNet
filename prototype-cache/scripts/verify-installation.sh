#!/bin/sh
# Phase 5: Verification & Testing Script
# Purpose: Health checks and validation
# Date: Jan 30, 2026
# Run on: VM (after Phase 4 complete)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

log_info() {
  echo "${GREEN}[✓]${NC} $1"
}

log_warn() {
  echo "${YELLOW}[!]${NC} $1"
}

log_error() {
  echo "${RED}[✗]${NC} $1"
}

# Test functions
test_user_exists() {
  local user=$1
  if getent passwd "$user" > /dev/null; then
    log_info "User '$user' exists"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "User '$user' not found"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

test_user_in_wheel() {
  local user=$1
  if getent group wheel | grep -q "$user"; then
    log_info "User '$user' is in wheel group"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "User '$user' not in wheel group"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

test_doas_access() {
  local user=$1
  if doas -u "$user" whoami > /dev/null 2>&1; then
    log_info "User '$user' has doas access"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "User '$user' cannot use doas"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

test_go_binary() {
  if [ -x "/usr/local/go/bin/go" ]; then
    local version=$(/usr/local/go/bin/go version | awk '{print $3}')
    log_info "Go installed: $version"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "Go binary not found or not executable"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

test_trustnet_node() {
  if [ -x "/usr/local/bin/trustnet-node" ]; then
    log_info "trustnet-node binary available"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "trustnet-node binary not found"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

test_trustnet_registry() {
  if [ -x "/usr/local/bin/trustnet-registry" ]; then
    log_info "trustnet-registry binary available"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "trustnet-registry binary not found"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

test_home_directory() {
  local user=$1
  local home=$2
  if [ -d "$home" ]; then
    log_info "Home directory exists: $home"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "Home directory not found: $home"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

test_ssh_directory() {
  local user=$1
  local home=$2
  if [ -d "$home/.ssh" ]; then
    log_info "SSH directory exists for $user"
    PASS=$((PASS + 1))
    return 0
  else
    log_error "SSH directory not found for $user"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

# Main verification
main() {
  echo "======================================"
  echo "TrustNet Installation Verification"
  echo "======================================"
  echo ""

  # Node VM verification (if running on node)
  echo "Checking node user setup..."
  test_user_exists "warden"
  test_user_in_wheel "warden"
  test_home_directory "warden" "/home/warden"
  test_ssh_directory "warden" "/home/warden"
  echo ""

  # Registry VM verification (if running on registry)
  echo "Checking registry user setup..."
  test_user_exists "keeper"
  test_user_in_wheel "keeper"
  test_home_directory "keeper" "/home/keeper"
  test_ssh_directory "keeper" "/home/keeper"
  echo ""

  # Privilege escalation
  echo "Checking privilege escalation..."
  test_doas_access "warden"
  test_doas_access "keeper"
  echo ""

  # Tools
  echo "Checking installed tools..."
  test_go_binary
  test_trustnet_node
  test_trustnet_registry
  echo ""

  # Summary
  echo "======================================"
  TOTAL=$((PASS + FAIL))
  echo "Results: $PASS/$TOTAL passed"
  echo "======================================"

  if [ $FAIL -eq 0 ]; then
    log_info "All checks passed! ✅"
    return 0
  else
    log_error "Some checks failed. Review above."
    return 1
  fi
}

main "$@"
