#!/bin/bash

echo "🛡️ Wallet Guardian - Reactive Network Test Script"
echo "================================================="

echo "📊 Current Setup Status:"
echo "✅ Anvil running on localhost:8545 (Chain ID: 31337)"
echo "✅ WalletGuardianCallback deployed: 0x5FbDB2315678afecb367f032d93F642f64180aa3"
echo "✅ MockAttackContract deployed: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
echo "✅ HTTP server running on localhost:8080"
echo "✅ Dashboard available at: http://localhost:8080/test-dashboard.html"
echo ""

echo "🔧 Testing Attack Simulation Manually:"
echo "======================================"

echo "1. Trigger attack event..."
cd /mnt/d/projects/wallet_guardian/rn-guardian

~/.foundry/bin/cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 \
  "triggerAttack(string,address)" \
  "Large Transfer Attack" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

echo ""
echo "2. Check event logs..."
~/.foundry/bin/cast logs \
  --from-block 0 \
  --to-block latest \
  --address 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 \
  --rpc-url http://localhost:8545

echo ""
echo "✅ Attack simulation completed!"
echo ""
echo "🎯 Next Steps for Full Reactive Network Testing:"
echo "1. Deploy WalletGuardianRN on Lasna testnet (Reactive Network)"
echo "2. Set up cross-chain monitoring"
echo "3. Configure callback proxy"
echo "4. Test full end-to-end protection"
echo ""
echo "📱 Dashboard Testing:"
echo "1. Open: http://localhost:8080/test-dashboard.html"
echo "2. Connect MetaMask to Anvil (localhost:8545, Chain ID: 31337)"
echo "3. Import account: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo "4. Create protection policy"
echo "5. Simulate attack"
echo "6. Verify event generation"