# Blockchain Module

**Status**: 📋 Planned

## Description
Blockchain node integration and monitoring for TrustNet.

## Planned Features
- Node status (synced/syncing/offline)
- Current block height
- Peer information
- Sync progress
- Network statistics
- Validator information
- Consensus status

## Module Structure
```
blockchain/
├── frontend/
│   ├── status.html       # Node status dashboard
│   ├── peers.html        # Peer list
│   ├── styles.css        # Module styling
│   └── main.js           # Module logic
├── api/
│   ├── service.go        # Backend service
│   └── handlers.go       # HTTP handlers
├── module.json           # Module metadata
└── README.md             # This file
```

## API Endpoints (Planned)
- `GET /api/blockchain/status` - Node status
- `GET /api/blockchain/height` - Current block height
- `GET /api/blockchain/block/:height` - Get block by height
- `GET /api/blockchain/peers` - List connected peers
- `GET /api/blockchain/sync` - Sync progress
- `GET /api/blockchain/validators` - Validator set

## Integration
- Cosmos SDK RPC (port 26657)
- Cosmos SDK REST (port 1317)
- Tendermint BFT consensus
- WebSocket for real-time updates

## Development Status
🚧 Not yet implemented

To build this module, see [MODULE_DEVELOPMENT_GUIDE.md](../../docs/MODULE_DEVELOPMENT_GUIDE.md)
