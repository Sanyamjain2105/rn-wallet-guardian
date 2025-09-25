#!/bin/bash

# 🚀 Advanced Wallet Guardian Testing Workflow
# ============================================

echo "🛡️ Starting Advanced Wallet Guardian Testing..."
echo ""

# Step 1: Deploy Advanced Contract
echo "📦 Step 1: Deploying Advanced Wallet Guardian..."
forge script scripts/deployAdvanced.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

if [ $? -eq 0 ]; then
    echo "✅ Advanced contract deployed successfully!"
else
    echo "❌ Contract deployment failed!"
    exit 1
fi

echo ""

# Step 2: Verify Contract Functions
echo "🔍 Step 2: Verifying contract functions..."

# Get the deployed contract address (you'll need to extract this from the deployment output)
CONTRACT_ADDRESS="0x5FbDB2315678afecb367f032d93F642f64180aa3"  # Update after deployment

# Test deposit function
echo "💰 Testing fund deposit..."
cast send $CONTRACT_ADDRESS "depositFunds()" --value 1ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545

# Test protection setup
echo "🛡️ Testing protection setup..."
cast send $CONTRACT_ADDRESS "createProtectionPolicy(uint256,address,address,bool,uint256)" 500000000000000000 0x0000000000000000000000000000000000000004 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 true 20 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545

# Test demo attack
echo "🎮 Testing demo attack..."
cast send $CONTRACT_ADDRESS "triggerDemoAttack(string)" "flash-loan-attack" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545

echo ""

# Step 3: Start Dashboard Server
echo "🌐 Step 3: Starting Advanced Dashboard..."
echo "Open your browser to: http://localhost:8080/advanced-dashboard.html"
echo ""
echo "🎯 Testing Workflow:"
echo "1. Connect MetaMask to Anvil (localhost:8545)"
echo "2. Switch between Demo/Real modes"
echo "3. Deposit funds (Real mode)"
echo "4. Setup protection policy"
echo "5. Try demo attacks (Demo mode)"
echo "6. Monitor Chainlink price feeds"
echo ""

# Start the server
python3 -m http.server 8080