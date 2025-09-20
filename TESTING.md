# 🛡️ Wallet Guardian - Reactive Network Integration

**IMPORTANT**: This project MUST use Reactive Network for cross-chain monitoring and protection.

## �️ **Reactive Network Architecture**

```
┌─ REACTIVE NETWORK (Lasna Testnet) ────────────────┐
│  WalletGuardianRN.sol                             │
│  • Subscribes to Anvil chain events               │
│  • Monitors: ERC20 transfers, price drops, etc.   │
│  • Executes react() when threats detected         │
│  • Sends cross-chain callbacks                    │
└────────────────────────────────────────────────────┘
                    ↓ Cross-chain callback
┌─ DESTINATION CHAIN (Anvil) ───────────────────────┐
│  WalletGuardianCallback.sol                       │
│  • Receives callbacks from Reactive Network       │
│  • Executes emergency fund transfers              │
│  • Protects user funds                            │
│                                                   │
│  MockAttackContract.sol                           │
│  • Simulates attacks (price drops, large txs)     │
│  • Generates events for Reactive Network          │
└────────────────────────────────────────────────────┘
```

## 🚀 **Complete Test Setup**

### **Prerequisites**
1. **Foundry**: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
2. **Lasna Testnet Funds**: Get from [Reactive Network Faucet](https://lasna-faucet.rnk.dev/)
3. **MetaMask**: For wallet interactions

### **Step 1: Environment Setup**
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your details:
# - PRIVATE_KEY: Your private key with Lasna testnet funds
# - Keep other values as defaults for testing
```

### **Step 2: Deploy on Anvil (Destination Chain)**
```bash
# Start local test environment
test-setup.bat  # Windows
# OR
./test-setup.sh  # Linux/Mac
```

This deploys:
- ✅ `WalletGuardianCallback.sol` (receives emergency transfers)
- ✅ `MockAttackContract.sol` (simulates attacks)

### **Step 3: Deploy on Reactive Network (Monitoring)**
```bash
# Deploy monitoring contract on Lasna testnet
forge script scripts/deployReactive.s.sol \
  --rpc-url https://lasna-rpc.rnk.dev \
  --broadcast \
  --chain-id 167008 \
  --private-key $PRIVATE_KEY
```

This deploys:
- ✅ `WalletGuardianRN.sol` (monitors Anvil chain)
- ✅ Automatically subscribes to event monitoring

## 🔄 **Testing Workflow**

### **1. Create Protection Policy**
- Open: `http://localhost:8080/test-dashboard.html`
- Connect MetaMask to Anvil (Chain ID: 31337)
- Create protection policy with destination address
- Funds are held by callback contract

### **2. Simulate Attack**
```bash
# Trigger attack simulation
cast send [MOCK_ATTACK_CONTRACT] \
  "triggerAttack(string,address)" \
  "Large Transfer Attack" \
  [USER_ADDRESS] \
  --rpc-url http://localhost:8546 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### **3. Reactive Network Response**
1. **Event Detection**: Reactive Network detects attack event on Anvil
2. **React() Execution**: `WalletGuardianRN.react()` function triggered
3. **Cross-chain Callback**: Emergency transfer initiated
4. **Fund Protection**: Callback contract executes transfer

### **4. Verify Results**
- Check user balance (should decrease)
- Check destination balance (should increase)
- View transaction history on Anvil

## � **Monitoring Events**

The Reactive Network contract subscribes to:

| Event Type | Topic Hash | Purpose |
|------------|------------|---------|
| ERC20 Transfer | `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef` | Large transfer detection |
| Uniswap V2 Sync | `0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1` | Price drop monitoring |
| Liquidation | `0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52` | Liquidation threats |

## 🔧 **Key Contracts**

### **WalletGuardianRN.sol** (Reactive Network)
```solidity
function react(LogRecord calldata log) external vmOnly {
    // Processes events from monitored chains
    // Triggers emergency transfers when threats detected
}

function createPolicy(
    uint256 insuredAmount,
    uint256 priceDropThresholdBp,
    address destinationAddress
) external payable returns (uint256) {
    // Creates protection policy
}
```

### **WalletGuardianCallback.sol** (Destination Chain)
```solidity
function executeEmergencyTransfer(
    address user,
    uint256 amount,
    address destinationAddress
) external authorizedSenderOnly {
    // Receives callback from Reactive Network
    // Executes actual fund transfer
}
```

### **MockAttackContract.sol** (Testing)
```solidity
function triggerAttack(string memory attackType, address target) external {
    // Emits events that trigger Reactive Network monitoring
    emit Transfer(target, address(0xdead), 1000 ether);
}
```

## 🎯 **Success Criteria**

- ✅ Reactive Network contract deployed on Lasna
- ✅ Callback contract deployed on Anvil  
- ✅ Event subscriptions active
- ✅ Attack simulation triggers cross-chain callback
- ✅ Funds automatically transferred to safe address
- ✅ End-to-end protection verified

## 🌐 **Network Configuration**

### **Lasna Testnet (Reactive Network)**
- **RPC**: `https://lasna-rpc.rnk.dev`
- **Chain ID**: `167008`
- **Faucet**: https://lasna-faucet.rnk.dev/
- **Explorer**: https://lasna.reactscan.net/

### **Anvil (Testing)**
- **RPC**: `http://localhost:8546`
- **Chain ID**: `31337`
- **Accounts**: 10 accounts with 1000 ETH each

## ⚠️ **Important Notes**

1. **Reactive Network is NON-NEGOTIABLE** - This is the core technology
2. **Cross-chain Monitoring** - Events on Anvil trigger actions on Reactive Network
3. **Real Fund Transfers** - Not simulation, actual blockchain transactions
4. **Event-Driven** - Uses Reactive Network's subscription service
5. **Gasless for Users** - Reactive Network handles cross-chain execution

---

**The power is in Reactive Network's ability to monitor one chain and execute on another automatically!**