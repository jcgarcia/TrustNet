# TrustNet API

REST API gateway for TrustNet services.

## Status
📋 Planned

## Description
The API layer provides a unified REST interface for all TrustNet modules and blockchain operations.

## Architecture

```
Client (Browser/App)
        ↓
    API Gateway (Port 1317)
        ↓
    ┌───┴───┬──────────┬─────────┐
    ↓       ↓          ↓         ↓
Identity  Trans  Keys    Blockchain
Module   Module  Module   (Cosmos SDK)
```

## Technology Stack

- **Language**: Go
- **Framework**: Gin (lightweight HTTP router)
- **Database**: SQLite (local) or PostgreSQL (production)
- **Blockchain**: Cosmos SDK integration
- **Authentication**: JWT tokens

## Planned Endpoints

### Node Information
- `GET /api/node/status` - Node status
- `GET /api/node/info` - System information
- `GET /api/node/peers` - Connected peers

### Identity
- `POST /api/identity/register` - Register new identity
- `GET /api/identity/:id` - Get identity details
- `PUT /api/identity/:id` - Update identity
- `GET /api/identity/:id/reputation` - Get reputation score

### Transactions
- `GET /api/transactions` - List transactions
- `GET /api/transactions/:hash` - Get transaction details
- `POST /api/transactions` - Submit transaction

### Keys
- `POST /api/keys/generate` - Generate key pair
- `GET /api/keys` - List keys
- `DELETE /api/keys/:id` - Delete key

### Blockchain
- `GET /api/blockchain/height` - Current block height
- `GET /api/blockchain/block/:height` - Get block
- `GET /api/blockchain/sync` - Sync status

## Module Integration

Each module can register its own routes:

```go
// modules/identity/api/service.go
package identity

func RegisterRoutes(r *gin.RouterGroup) {
    r.POST("/identity/register", handleRegister)
    r.GET("/identity/:id", handleGetIdentity)
}
```

## Development

```bash
# Install dependencies
cd api/
go mod download

# Run in development mode (auto-reload)
air

# Build
go build -o trustnet-api ./src

# Run
./trustnet-api
```

## Configuration

Configuration via environment variables or config file:

```env
# Server
PORT=1317
HOST=0.0.0.0

# Database
DB_TYPE=sqlite
DB_PATH=/var/lib/trustnet/trustnet.db

# Blockchain
COSMOS_RPC=http://localhost:26657
COSMOS_REST=http://localhost:1317

# Authentication
JWT_SECRET=<secret-key>
JWT_EXPIRY=24h
```

## Version
0.1.0-alpha
