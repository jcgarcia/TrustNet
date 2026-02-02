# Web UI Module

Main web interface for TrustNet nodes.

## Status
🚧 In Development

## Description
The Web UI module provides the main dashboard interface for TrustNet nodes, displaying:
- Node status (blockchain network, connection, identity, reputation)
- TRUST balance
- Navigation buttons to other modules
- System information

## Current Features
- ✅ Node status dashboard
- ✅ Placeholder buttons (Register Identity, View Transactions, Manage Keys)
- ✅ Responsive design
- ✅ Served via Caddy HTTPS

## Planned Features
- [ ] Dynamic module loading
- [ ] Real blockchain integration
- [ ] Live status updates
- [ ] Module navigation system
- [ ] User authentication

## File Structure
```
web-ui/
├── frontend/
│   ├── index.html      # Main dashboard
│   ├── styles.css      # Styling
│   └── main.js         # JavaScript logic
├── module.json         # Module metadata
└── README.md           # This file
```

## Development

Edit files in `frontend/` and sync to VM:

```bash
# Start auto-sync
cd ~/GitProjects/TrustNet/trustnet-wip
./tools/dev-sync.sh

# Edit UI
vim modules/web-ui/frontend/index.html

# View changes
# → https://trustnet.local (refresh browser)
```

## Integration Points

### API Endpoints (Planned)
- `GET /api/node/status` - Node status
- `GET /api/node/balance` - TRUST balance
- `GET /api/node/info` - System info

### Module Loading
The Web UI will load other modules dynamically:
```javascript
// Load identity module
ModuleLoader.load('identity').then(() => {
  // Module ready
});
```

## Version
1.0.0-dev
