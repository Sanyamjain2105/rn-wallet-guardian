#!/usr/bin/env bash

# Wallet Guardian Test Script
# This script sets up everything needed for testing

echo "🛡️ Wallet Guardian - Test Setup"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Anvil is running
echo -e "${BLUE}1. Checking Anvil...${NC}"
if curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8546 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Anvil is running${NC}"
else
    echo -e "${YELLOW}⚠️  Starting Anvil...${NC}"
    anvil --port 8546 --accounts 10 --balance 1000 &
    ANVIL_PID=$!
    echo "Anvil PID: $ANVIL_PID"
    sleep 3
fi

# Deploy the contract
echo -e "${BLUE}2. Deploying SimpleWalletGuardian...${NC}"
DEPLOY_OUTPUT=$(forge create src/SimpleWalletGuardian.sol:SimpleWalletGuardian \
    --rpc-url http://localhost:8546 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 2>&1)

if [ $? -eq 0 ]; then
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
    echo -e "${GREEN}✅ Contract deployed at: $CONTRACT_ADDRESS${NC}"
    
    # Update the dashboard with the contract address
    sed -i "s/let contractAddress.*/let contractAddress = '$CONTRACT_ADDRESS';/" test-dashboard.html
    echo -e "${GREEN}✅ Dashboard updated with contract address${NC}"
else
    echo -e "${RED}❌ Contract deployment failed:${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

# Start HTTP server
echo -e "${BLUE}3. Starting HTTP server...${NC}"
python3 -m http.server 8080 &
HTTP_PID=$!
echo "HTTP Server PID: $HTTP_PID"
sleep 2

# Display test accounts
echo -e "${BLUE}4. Test Accounts Available:${NC}"
echo "Account #1 (Deployer): 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "Account #2: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo "Account #3: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
echo "Account #4: 0x90F79bf6EB2c4f870365E785982E1f101E93b906"
echo "Account #5: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"

# Display instructions
echo -e "${GREEN}"
echo "🚀 Setup Complete! Next Steps:"
echo "=============================="
echo "1. Open: http://localhost:8080/test-dashboard.html"
echo "2. Connect MetaMask to Anvil (localhost:8546)"
echo "3. Import one of the accounts above using private key"
echo "4. Follow the dashboard workflow:"
echo "   • Connect wallet"
echo "   • Select amount to protect (e.g., 0.1 ETH)"
echo "   • Choose destination (different account)"
echo "   • Simulate attack"
echo "   • See funds transfer!"
echo ""
echo "📋 Private Keys for Testing:"
echo "Account #1: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo "Account #2: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
echo "Account #3: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
echo ""
echo "Press Ctrl+C to stop all services"
echo -e "${NC}"

# Wait for user to stop
trap "echo -e '\n${YELLOW}Stopping services...${NC}'; kill $ANVIL_PID $HTTP_PID 2>/dev/null; exit 0" INT
wait