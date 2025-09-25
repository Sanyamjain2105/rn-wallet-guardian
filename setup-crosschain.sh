#!/bin/bash

# 🚀 Cross-Chain Testing Setup Script
# ==================================

echo "🛡️ Setting up Cross-Chain Testing Environment"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
RPC_URL="http://localhost:8545"

print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Check if Anvil is running
print_step "Checking if Anvil is running..."
if ! nc -z localhost 8545; then
    print_error "Anvil is not running on port 8545"
    echo "Please start Anvil first:"
    echo "anvil --port 8545 --accounts 10 --balance 1000 --chain-id 31337"
    exit 1
fi
print_success "Anvil is running"

# Step 2: Deploy Advanced Contracts
print_step "Deploying Advanced Wallet Guardian contracts..."

DEPLOY_OUTPUT=$(forge script scripts/deployAdvanced.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast 2>&1)

if [ $? -eq 0 ]; then
    print_success "Advanced contracts deployed successfully"
    
    # Extract contract addresses from deployment output
    ADVANCED_GUARDIAN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -o "AdvancedWalletGuardian deployed at: 0x[a-fA-F0-9]*" | grep -o "0x[a-fA-F0-9]*" | head -1)
    CALLBACK_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -o "WalletGuardianCallback deployed at: 0x[a-fA-F0-9]*" | grep -o "0x[a-fA-F0-9]*" | head -1)
    MOCK_ATTACK_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -o "MockAttackContract deployed at: 0x[a-fA-F0-9]*" | grep -o "0x[a-fA-F0-9]*" | head -1)
    
    # If extraction failed, use default addresses
    if [ -z "$ADVANCED_GUARDIAN_ADDRESS" ]; then
        ADVANCED_GUARDIAN_ADDRESS="0x5FbDB2315678afecb367f032d93F642f64180aa3"
        print_warning "Using default AdvancedWalletGuardian address: $ADVANCED_GUARDIAN_ADDRESS"
    fi
    
    if [ -z "$CALLBACK_ADDRESS" ]; then
        CALLBACK_ADDRESS="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
        print_warning "Using default Callback address: $CALLBACK_ADDRESS"
    fi
    
    if [ -z "$MOCK_ATTACK_ADDRESS" ]; then
        MOCK_ATTACK_ADDRESS="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
        print_warning "Using default MockAttack address: $MOCK_ATTACK_ADDRESS"
    fi
    
else
    print_error "Contract deployment failed"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

# Step 3: Update Advanced Dashboard with contract addresses
print_step "Updating advanced dashboard with contract addresses..."

# Create backup
cp advanced-dashboard.html advanced-dashboard.html.bak

# Update contract address in advanced dashboard
sed -i "s/let contractAddress = '0x[a-fA-F0-9]*'/let contractAddress = '$ADVANCED_GUARDIAN_ADDRESS'/" advanced-dashboard.html

if [ $? -eq 0 ]; then
    print_success "Advanced dashboard updated with new contract addresses"
else
    print_error "Failed to update advanced dashboard"
    # Restore backup
    mv advanced-dashboard.html.bak advanced-dashboard.html
    exit 1
fi

# Step 4: Verify contract deployment
print_step "Verifying contract deployment..."

# Test AdvancedWalletGuardian
OWNER_CHECK=$(cast call $ADVANCED_GUARDIAN_ADDRESS "owner()" --rpc-url $RPC_URL 2>/dev/null)
if [ $? -eq 0 ]; then
    print_success "AdvancedWalletGuardian is responding"
else
    print_error "AdvancedWalletGuardian verification failed"
fi

# Step 5: Check balances
print_step "Checking account balances..."
BALANCE=$(cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)
BALANCE_ETH=$(echo "scale=4; $BALANCE / 1000000000000000000" | bc -l 2>/dev/null || echo "~10000")
print_success "Account balance: $BALANCE_ETH ETH"

# Step 6: Start HTTP server if not running
print_step "Checking HTTP server..."
if ! nc -z localhost 8080; then
    print_step "Starting HTTP server..."
    python3 -m http.server 8080 &
    HTTP_PID=$!
    echo $HTTP_PID > http_server.pid
    sleep 2
    if nc -z localhost 8080; then
        print_success "HTTP server started (PID: $HTTP_PID)"
    else
        print_error "Failed to start HTTP server"
    fi
else
    print_success "HTTP server is already running"
fi

# Step 7: Display summary
echo ""
echo "🎉 CROSS-CHAIN TESTING ENVIRONMENT READY!"
echo "========================================"
echo ""
echo "📋 Contract Addresses:"
echo "  AdvancedWalletGuardian: $ADVANCED_GUARDIAN_ADDRESS"
echo "  WalletGuardianCallback: $CALLBACK_ADDRESS"
echo "  MockAttackContract:     $MOCK_ATTACK_ADDRESS"
echo ""
echo "🌐 Access Points:"
echo "  Landing Page:     http://localhost:8080/index.html"
echo "  Same Chain:       http://localhost:8080/test-dashboard.html"
echo "  Cross-Chain:      http://localhost:8080/advanced-dashboard.html"
echo ""
echo "🔧 MetaMask Configuration:"
echo "  Network: Anvil Local"
echo "  RPC URL: http://localhost:8545"
echo "  Chain ID: 31337"
echo "  Currency: ETH"
echo ""
echo "🔑 Test Account:"
echo "  Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "  Private Key: $PRIVATE_KEY"
echo "  Balance: $BALANCE_ETH ETH"
echo ""
echo "🧪 Testing Steps:"
echo "  1. Open: http://localhost:8080/index.html"
echo "  2. Choose 'Cross-Chain Protection'"
echo "  3. Connect MetaMask to Anvil"
echo "  4. Import the test account"
echo "  5. Test fund deposits and protection"
echo ""
echo "🚨 Ready for cross-chain testing!"

# Cleanup function
cleanup() {
    if [ -f http_server.pid ]; then
        kill $(cat http_server.pid) 2>/dev/null
        rm http_server.pid
    fi
}

# Set trap for cleanup
trap cleanup EXIT