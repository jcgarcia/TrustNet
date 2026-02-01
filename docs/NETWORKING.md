# TrustNet Networking Configuration

## Problem: Port 443 Conflict with FactoryVM

Both FactoryVM and TrustNet need to serve HTTPS on port 443, but only one process can bind to a port at a time.

## Solution: IPv6 Separation + socat Proxy

###  Architecture

```
Browser Request                VM Internal               
━━━━━━━━━━━━━                 ━━━━━━━━━━━━              

https://factory.local          FactoryVM Guest          
  ↓                           ┌─────────────────┐        
127.0.0.1:443 ←────QEMU──────┤ Caddy → 443     │        
                              └─────────────────┘        

https://trustnet.local         TrustNet Guest           
  ↓                           ┌─────────────────┐        
::3:443 → socat → localhost:8443 ←QEMU─┤ Caddy → 443│        
                              └─────────────────┘        
```

### Components

1. **Virtual IPv6 Addresses** (`/etc/systemd/system/vm-virtual-ips.service`):
   ```
   ::2/128 → Reserved for FactoryVM (future use)
   ::3/128 → TrustNet
   ```

2. **FactoryVM QEMU** (`/home/jcgarcia/vms/factory/start-factory.sh`):
   ```bash
   -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::443-:443
   ```
   - Binds to `0.0.0.0:443` (all IPv4 addresses)
   - Accessible via `127.0.0.1:443` (factory.local)

3. **TrustNet QEMU** (`/home/jcgarcia/vms/trustnet/start-trustnet.sh`):
   ```bash
   -netdev user,id=net0,hostfwd=tcp::2223-:22,hostfwd=tcp::8443-:443
   ```
   - Forwards guest port 443 → host port 8443
   - **Does NOT bind to port 443** (avoids conflict)

4. **socat HTTPS Proxy** (`/etc/systemd/system/trustnet-https-proxy.service`):
   ```bash
   ExecStart=/usr/bin/socat TCP6-LISTEN:443,bind=[::3],fork,reuseaddr TCP4:localhost:8443
   ```
   - Listens on IPv6 `::3:443`
   - Forwards to `localhost:8443` (TrustNet VM)
   - Runs as systemd service, auto-starts

5. **/etc/hosts**:
   ```
   127.0.0.1  factory.local
   ::3        trustnet.local
   ```

## Critical Configuration Files

### `/etc/systemd/system/vm-virtual-ips.service`
Creates persistent IPv6 addresses that survive reboots.

```ini
[Unit]
Description=Virtual IPv6 addresses for QEMU VMs
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'ip addr add ::2/128 dev lo 2>/dev/null || true'
ExecStart=/bin/sh -c 'ip addr add ::3/128 dev lo 2>/dev/null || true'

[Install]
WantedBy=multi-user.target
```

**Commands**:
```bash
sudo systemctl enable vm-virtual-ips.service
sudo systemctl start vm-virtual-ips.service
```

### `/etc/systemd/system/trustnet-https-proxy.service`
Forwards ::3:443 → localhost:8443 for TrustNet access.

```ini
[Unit]
Description=TrustNet HTTPS Proxy (::3:443 → localhost:8443)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP6-LISTEN:443,bind=[::3],fork,reuseaddr TCP4:localhost:8443
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

**Commands**:
```bash
sudo systemctl enable trustnet-https-proxy.service
sudo systemctl start trustnet-https-proxy.service
```

## Verification

### Check Virtual IPs Exist
```bash
ip addr show lo | grep "inet6"
```
Expected:
```
inet6 ::3/128 scope global
inet6 ::2/128 scope global  
inet6 ::1/128 scope host noprefixroute
```

### Check Services Running
```bash
sudo systemctl status vm-virtual-ips.service
sudo systemctl status trustnet-https-proxy.service
```

### Check Ports
```bash
ss -tlnp | grep 443
```
Expected:
```
LISTEN  0.0.0.0:443   (FactoryVM QEMU)
LISTEN  [::3]:443     (socat proxy)
LISTEN  0.0.0.0:8443  (TrustNet QEMU)
```

### Test Access
```bash
curl -v https://factory.local   # Should connect to 127.0.0.1:443
curl -v https://trustnet.local  # Should connect to ::3:443 → 8443
```

## Troubleshooting

### socat proxy fails to start
**Symptom**: `sudo systemctl status trustnet-https-proxy` shows failed  
**Cause**: TrustNet VM not running (nothing listening on port 8443)  
**Fix**: Start TrustNet VM first, then restart proxy:
```bash
~/vms/trustnet/start-trustnet.sh
sudo systemctl restart trustnet-https-proxy
```

### "Port 443 already in use"
**Symptom**: QEMU fails with "Could not set up host forwarding rule"  
**Cause**: Both VMs trying to bind to same port  
**Fix**: Verify TrustNet uses port 8443:
```bash
grep hostfwd ~/vms/trustnet/start-trustnet.sh
# Should show: hostfwd=tcp::8443-:443
```

### TrustNet not accessible
**Symptom**: `curl https://trustnet.local` fails  
**Checks**:
1. VM running? `ps aux | grep trustnet`
2. Port 8443 open? `ss -tln | grep 8443`
3. socat running? `sudo systemctl status trustnet-https-proxy`
4. /etc/hosts correct? `grep trustnet /etc/hosts` → should show `::3 trustnet.local`

### Virtual IPs missing after reboot
**Symptom**: `ip addr show lo` doesn't show ::2 or ::3  
**Fix**: Enable systemd service:
```bash
sudo systemctl enable vm-virtual-ips.service
sudo systemctl start vm-virtual-ips.service
```

## Why This Configuration?

### Why not use different ports like :8443?
Users expect `https://trustnet.local` not `https://trustnet.local:8443`. The socat proxy allows standard HTTPS URLs while avoiding port conflicts.

### Why IPv6 ::3 instead of IPv4?
- IPv4 loopback is limited (127.0.0.0/8 range, but only 127.0.0.1 typically configured)
- IPv6 loopback can have unlimited addresses (::1, ::2, ::3, etc.)
- Easier to add more VMs in future (::4, ::5, etc.)

### Why not QEMU tap networking?
- Requires root privileges
- More complex setup
- User networking (SLIRP) is simpler and sufficient

### Why socat instead of iptables/nftables?
- Simpler configuration
- More portable
- Easier to debug (`ss -tlnp`)
- Works with systemd for auto-start/restart

## Certificate Configuration

**CRITICAL**: Use `CT,C,C` trust flags for self-signed certificates in browsers.

### Correct Installation
```bash
certutil -A -d sql:~/.mozilla/firefox/PROFILE -t "CT,C,C" -n "TrustNet SSL" -i /path/to/cert.crt
```

### Trust Flags Explained
- `C,C,C` = Valid certificate, but NOT trusted (browser shows warning)
- `CT,C,C` = **Trusted CA** (no warnings, accepted automatically)
- `TC,,` = Certificate Authority trust (for root CA certs, not server certs)

**For self-signed server certificates**, always use `CT,C,C`.

## Summary

- **FactoryVM**: Port 443 on IPv4 (127.0.0.1)
- **TrustNet**: Port 443 on IPv6 (::3) via socat → 8443
- **Both VMs run simultaneously** without conflicts
- **Standard HTTPS URLs work** for both VMs
- **Persistent across reboots** via systemd services
