# Troubleshooting Guide

## Common Issues & Solutions

### VM Creation Issues

#### Error: "No space left on device"
**Cause**: Insufficient disk space for QCOW2 images (50GB + 30GB + cache)

**Solution**:
```bash
# Check available space
df -h ~

# Verify minimum requirements: 100GB free
# Clean up unused files if needed
rm -rf ~/vms/old-backups/
rm -rf ~/trustnet-setup/
```

**Expected output**:
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1      200G  45G  155G  23%  /
```

---

#### Error: "qemu-system-aarch64: could not load kernel"
**Cause**: Alpine ISO not found or incorrect path

**Solution**:
```bash
# Verify ISO downloaded
ls -lh ~/vms/isos/alpine-virt-3.22.2-aarch64.iso

# Check file size (should be ~200MB)
# If missing, re-run install.sh which downloads ISOs
```

---

#### Error: QEMU process fails to start
**Cause**: Insufficient memory, port conflicts, or QEMU not installed

**Solution**:
```bash
# Check QEMU installation
which qemu-system-aarch64
qemu-system-aarch64 --version

# Check available memory
free -h
# Node needs 8GB, Registry needs 4GB minimum

# Check for port conflicts
lsof -i :26657  # Tendermint RPC
lsof -i :26656  # Tendermint P2P
lsof -i :8000   # Registry
lsof -i :2222   # SSH node
lsof -i :2223   # SSH registry

# Kill conflicting process if needed
kill -9 <PID>
```

---

### Network Issues

#### Error: "Cannot reach tendermint-node at fd10:1234::1"
**Cause**: IPv6 ULA bridge not configured or VM not running

**Solution**:
```bash
# Verify VM is running
ps aux | grep qemu | grep trustnet-node

# Check bridge status
ip -6 addr show
# Should show fd10:1234::1 or similar ULA address

# Test ping from host (if supported)
ping6 fd10:1234::1

# Check VM's network configuration
ssh -p 2222 root@127.0.0.1 'ip -6 addr show'
```

---

#### Error: "Connection refused on port 26657"
**Cause**: Tendermint service not running or port not bound

**Solution**:
```bash
# SSH into node
ssh -p 2222 root@127.0.0.1

# Inside node VM:
# Check if Tendermint is running
ps aux | grep tendermint

# Check if port is bound
ss -tlnp | grep 26657

# Check Tendermint logs
tail -f /opt/trustnet/node/logs/tendermint.log

# Restart Tendermint
systemctl restart tendermint-node
```

---

### SSH Access Issues

#### Error: "Connection refused" on port 2222
**Cause**: VM not running or SSH not configured

**Solution**:
```bash
# Verify VM running
~/vms/trustnet-node/start-trustnet-node.sh

# Wait 30 seconds for VM to boot
sleep 30

# Try SSH again
ssh -p 2222 -o StrictHostKeyChecking=no root@127.0.0.1

# If still failing, check VM console
# (QEMU window should show boot messages)
```

---

#### Error: "Permission denied (publickey)"
**Cause**: SSH key not configured in VM, or wrong key permissions

**Solution**:
```bash
# Check local SSH key permissions (host)
ls -la ~/.ssh/
# Should be 700 for ~/.ssh directory
chmod 700 ~/.ssh

# Try with verbose output to see key being used
ssh -vvv -p 2222 root@127.0.0.1

# If no key works, use installer to regenerate
bash ~/trustnet-setup/install.sh --setup-ssh
```

---

### Registry Issues

#### Error: "Registry health check failed"
**Cause**: Registry service not running or not responding

**Solution**:
```bash
# SSH into registry VM
ssh -p 2223 -o StrictHostKeyChecking=no root@127.0.0.1

# Inside registry VM:
# Check service status
systemctl status trustnet-registry

# Check if process is running
ps aux | grep registry

# Check port binding
ss -tlnp | grep 8000

# View logs
tail -f /var/lib/trustnet-registry/logs/registry.log

# Restart service
systemctl restart trustnet-registry
```

---

#### Error: "Unable to push image to registry"
**Cause**: Registry not running, authentication issue, or storage full

**Solution**:
```bash
# Test registry connectivity
curl -v http://127.0.0.1:8000/health

# Check registry storage usage
ssh -p 2223 root@127.0.0.1 'df -h /var/lib/trustnet-registry/'

# Check authentication (if configured)
# Registry should accept any user without auth (default)

# Try manual push with verbose output
docker push 127.0.0.1:8000/test-image:latest -v
```

---

### Performance Issues

#### Issue: High CPU usage during startup
**Expected**: Normal for first 5 minutes during Alpine package installation

**Monitor**:
```bash
# Check CPU usage
top -b -n 1 | head -15

# For specific VM
ps aux | grep qemu | head -1
```

---

#### Issue: Slow disk I/O
**Cause**: QCOW2 on mechanical disk, or host system overloaded

**Solution**:
```bash
# Check disk I/O
iostat -xz 1 3

# Test disk performance inside VM
ssh -p 2222 root@127.0.0.1 'dd if=/dev/zero of=/tmp/test bs=1M count=100'

# Check disk type (SSD vs mechanical)
lsblk -d -o name,rota
# rota=0 is SSD, rota=1 is mechanical
```

---

### Verification Commands

#### Full System Check
```bash
#!/bin/bash

echo "=== System Status ==="

# Check VMs running
echo "Active VMs:"
ps aux | grep qemu | grep -v grep | awk '{print $2, $14}' || echo "None running"

# Check disk images
echo -e "\nDisk images:"
ls -lh ~/vms/trustnet-*/trustnet-*.qcow2 2>/dev/null || echo "Not found"

# Check ISO cache
echo -e "\nISO files:"
ls -lh ~/vms/isos/ 2>/dev/null || echo "Not found"

# Check SSH connectivity
echo -e "\nSSH Access:"
ssh -p 2222 -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@127.0.0.1 'echo "Node: OK"' 2>/dev/null || echo "Node: UNREACHABLE"
ssh -p 2223 -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@127.0.0.1 'echo "Registry: OK"' 2>/dev/null || echo "Registry: UNREACHABLE"

# Check service ports
echo -e "\nService Ports:"
for port in 26657 26656 8000 2222 2223; do
  (echo > /dev/tcp/127.0.0.1/$port) 2>/dev/null && echo "Port $port: OPEN" || echo "Port $port: CLOSED"
done

# Check IPv6 network
echo -e "\nIPv6 Network:"
ip -6 addr | grep fd10 || echo "IPv6 ULA not configured"
```

---

## Recovery Procedures

### Reset to Clean State
```bash
# Stop all VMs
pkill -f qemu-system-aarch64

# Delete VM images (CAUTION: loses all data)
rm -f ~/vms/trustnet-*/trustnet-*.qcow2

# Delete cache and re-download
rm -rf ~/vms/cache/
rm -rf ~/vms/isos/

# Re-run installer
bash ~/trustnet-setup/install.sh --auto

# Wait for VMs to start
sleep 60

# Verify
curl -s http://127.0.0.1:8000/health
```

---

### Restore from Snapshot (if available)
```bash
# This requires QEMU snapshots to have been created
# For now, use full reset procedure above

# Future implementation:
# qemu-img snapshot -l ~/vms/trustnet-node/trustnet-node.qcow2
# qemu-img snapshot -a snapshot-name ~/vms/trustnet-node/trustnet-node.qcow2
```

---

## Getting Help

1. **Check logs** in respective VM:
   - Node: `/opt/trustnet/node/logs/tendermint.log`
   - Registry: `/var/lib/trustnet-registry/logs/registry.log`

2. **Verify network**: Run full system check above

3. **Test connectivity**:
   ```bash
   # Test Tendermint RPC
   curl -s http://127.0.0.1:26657/status | jq .

   # Test Registry
   curl -s http://127.0.0.1:8000/health | jq .
   ```

4. **Check documentation**:
   - [Installation Guide](./INSTALLATION.md)
   - [Architecture](./ARCHITECTURE.md)
   - README.md for overview
