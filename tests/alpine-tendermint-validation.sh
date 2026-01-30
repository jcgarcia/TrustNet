#!/bin/sh

# Alpine Tendermint Validation Script
# Run this on Alpine VM to test Tendermint + crypto compatibility
# Usage: sh alpine-tendermint-validation.sh

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         TENDERMINT VALIDATION ON ALPINE                       ║"
echo "║         Testing: Tendermint + Crypto + HTTP Server            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
PASS=0
FAIL=0

test_result() {
    local test_name=$1
    local exit_code=$2
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        FAIL=$((FAIL + 1))
    fi
}

# ═══════════════════════════════════════════════════════════════════════
echo "STEP 1: Check System Info"
echo "─────────────────────────────────────────────────────────────────"

echo "Architecture:"
uname -m

echo "Alpine version:"
cat /etc/os-release | grep VERSION

echo ""

# ═══════════════════════════════════════════════════════════════════════
echo "STEP 2: Prepare Environment"
echo "─────────────────────────────────────────────────────────────────"

# Update packages
echo "Updating packages..."
doas -n apk update > /dev/null 2>&1

# Install dependencies (curl and tar required for Go download)
echo "Installing build tools..."
doas -n apk add --no-cache curl tar git make gcc musl-dev > /dev/null 2>&1

# Install Go from binary (not available in Alpine 3.22 apk)
echo "Installing Go 1.22.0 from upstream binary..."
curl -L https://go.dev/dl/go1.22.0.linux-arm64.tar.gz 2>/dev/null | doas -n tar -xz -C /usr/local > /dev/null 2>&1

# Add Go to PATH
export PATH=/usr/local/go/bin:$PATH

# Verify Go
echo "Go version:"
/usr/local/go/bin/go version

# Create test directory
TEST_DIR="/tmp/trustnet-tendermint-test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Test directory: $TEST_DIR"
echo ""

# ═══════════════════════════════════════════════════════════════════════
echo "STEP 3: Test Tendermint Build"
echo "─────────────────────────────────────────────────────────────────"

# Initialize Go module
/usr/local/go/bin/go mod init tendermint-test > /dev/null 2>&1

# Create Tendermint test FIRST (so tidy can see imports)
cat > main.go << 'EOF'
package main

import (
	"fmt"
	_ "github.com/tendermint/tendermint/types"
)

func main() {
	fmt.Println("✅ Tendermint compiled successfully on Alpine!")
}
EOF

# Add Tendermint and resolve dependencies
echo "Downloading Tendermint library and dependencies..."
/usr/local/go/bin/go get github.com/tendermint/tendermint@latest
/usr/local/go/bin/go mod tidy

# Build
echo "Building Tendermint test binary..."
if /usr/local/go/bin/go build -o tendermint-test main.go 2>&1; then
    test_result "Tendermint build" 0
    echo "Tendermint output:"
    ./tendermint-test
else
    test_result "Tendermint build" 1
    echo "⚠️  Error building Tendermint"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════
echo "STEP 4: Test Crypto Libraries"
echo "─────────────────────────────────────────────────────────────────"

cat > crypto-test.go << 'EOF'
package main

import (
	"crypto/sha256"
	"crypto/rand"
	"fmt"
)

func main() {
	// SHA256 hash
	data := []byte("trustnet")
	hash := sha256.Sum256(data)
	fmt.Printf("SHA256 hash: %x\n", hash)
	
	// Random number generation
	b := make([]byte, 32)
	rand.Read(b)
	fmt.Printf("Random bytes: %x\n", b)
	
	fmt.Println("✅ Crypto libraries work on Alpine!")
}
EOF

echo "Building crypto test..."
if go build -o crypto-test crypto-test.go 2>/dev/null; then
    echo "Running crypto test..."
    if ./crypto-test > /dev/null 2>&1; then
        test_result "Crypto libraries" 0
        ./crypto-test
    else
        test_result "Crypto libraries" 1
    fi
else
    test_result "Crypto libraries" 1
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════
echo "STEP 5: Test HTTP Server (Registry-like)"
echo "─────────────────────────────────────────────────────────────────"

cat > server-test.go << 'EOF'
package main

import (
	"fmt"
	"net/http"
	"log"
)

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(200)
		fmt.Fprintf(w, `{"status":"ok"}`)
	})

	log.Println("Server listening on :8000")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		log.Fatal(err)
	}
}
EOF

echo "Building HTTP server test..."
if go build -o server-test server-test.go 2>/dev/null; then
    echo "Starting server in background..."
    ./server-test > /dev/null 2>&1 &
    SERVER_PID=$!
    sleep 1
    
    echo "Testing /health endpoint..."
    if curl -s http://localhost:8000/health 2>/dev/null | grep -q '"status":"ok"'; then
        test_result "HTTP server" 0
        echo "Response: $(curl -s http://localhost:8000/health)"
    else
        test_result "HTTP server" 1
    fi
    
    # Kill server
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
else
    test_result "HTTP server" 1
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════
echo "STEP 6: Check Binary Compatibility"
echo "─────────────────────────────────────────────────────────────────"

echo "Binary info for tendermint-test:"
file tendermint-test

echo ""
echo "Library dependencies:"
ldd tendermint-test || echo "(ldd not available, but binary linked successfully)"

echo ""

# ═══════════════════════════════════════════════════════════════════════
echo "RESULTS SUMMARY"
echo "═════════════════════════════════════════════════════════════════"

TOTAL=$((PASS + FAIL))
echo ""
echo -e "Tests passed: ${GREEN}$PASS/$TOTAL${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo ""
    echo "DECISION: Keep Alpine as primary base image"
    echo "  - Tendermint works on Alpine ✅"
    echo "  - Crypto libraries compatible ✅"
    echo "  - HTTP server works ✅"
    echo "  - Musl libc compatible ✅"
    echo ""
    echo "ACTION: Update ARCHITECTURE_DECISIONS.md to lock Alpine"
    echo "        Proceed with Week 1 using FactoryVM patterns"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "DECISION: Alpine may have compatibility issues"
    echo "  - Try gcompat layer: apk add gcompat"
    echo "  - Re-run this test"
    echo "  - If still fails: Switch to Debian 11-slim"
    echo ""
    echo "ACTION: Update ARCHITECTURE_DECISIONS.md with fallback decision"
    exit 1
fi

# ═════════════════════════════════════════════════════════════════════════

echo ""
echo "Test complete. Check results above."
