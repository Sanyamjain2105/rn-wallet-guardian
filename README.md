# WalletGuardianRN - Reactive Network Wallet Protection

A decentralized wallet protection system built on Reactive Network that automatically monitors Ethereum for security threats and price drops, then executes emergency fund transfers to safe destinations on other chains.

## 🔍 How It Works

WalletGuardianRN uses **Reactive Network's native subscription service** to monitor Ethereum Sepolia for:

- **Price Drops**: Monitors Uniswap V2 Sync events to detect significant price decreases
- **Large Transfers**: Detects unusually large ERC20 transfers that may indicate attacks
- **Liquidations**: Watches for liquidation events on DeFi protocols

When threats are detected, the system automatically triggers emergency transfers to your specified destination address on any supported chain.

## 🏗️ Architecture

```
Ethereum Sepolia (Monitored Chain)
       ↓ (Events: Uniswap Sync, ERC20 Transfers, Liquidations)
Reactive Network (Lasna Testnet)
  ↓ (WalletGuardianRN Contract - Event Processing)
Destination Chain (Anvil/Sepolia/etc)
  ↓ (WalletGuardianCallback Contract - Emergency Transfer)
User's Safe Address
```

## 🚀 Quick Start

### Prerequisites

1. **Foundry** installed: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
2. **Node.js** for frontend
3. **Private key** with funds on Reactive Network (Lasna testnet)
4. **Test funds** from [Reactive Network Faucet](https://lasna-faucet.rnk.dev/)

### Environment Setup

Create `.env` file:

```bash
# Required for Reactive Network deployment
PRIVATE_KEY=0x1234...  # Your private key (with 0x prefix)
SYSTEM_CONTRACT_ADDR=0x0000000000000000000000000000000000fffFfF  # RN System Contract
REACTIVE_RPC=https://lasna-rpc.rnk.dev  # Lasna testnet RPC

# Required for destination chain deployment  
CALLBACK_PROXY_ADDR=0x...  # Callback proxy address (see RN docs)
DESTINATION_RPC=http://127.0.0.1:8545  # Anvil or other destination chain
```

### Deployment

#### 1. Deploy on Reactive Network (Lasna Testnet)

First, deploy the reactive monitoring contract:

```bash
# Switch to Lasna testnet and deploy reactive contract
forge script scripts/deploy.s.sol --rpc-url $REACTIVE_RPC --broadcast --verify
```

This deploys `WalletGuardianRN` which will:
- Subscribe to Uniswap V2 Sync events on Ethereum Sepolia
- Subscribe to ERC20 Transfer events for large transfer detection  
- Subscribe to liquidation events
- Monitor these events via Reactive Network's subscription service

#### 2. Deploy Callback Contract on Destination Chain

Next, deploy the callback receiver on your destination chain:

```bash
# Deploy to Anvil local testnet
anvil &  # Start Anvil in background
forge script scripts/deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# OR deploy to other chains by updating RPC URL
```

This deploys `WalletGuardianCallback` which receives emergency transfer callbacks.

### Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

Access at `http://localhost:3000`

## 📋 Usage

### Creating a Protection Policy

1. **Connect Wallet**: Connect MetaMask to Anvil (local) or destination chain
2. **Configure Policy**:
   - **Amount to Secure**: How much ETH/tokens to protect
   - **Price Drop Threshold**: Percentage drop that triggers transfer (e.g., 20%)
   - **Large Transfer Threshold**: Transfer amount that indicates attack (e.g., 100 ETH)
   - **Destination Chain**: Where to send funds in emergency
   - **Destination Address**: Your safe address on destination chain

3. **Create Policy**: Click "Create Reactive Protection Policy"

### Policy Monitoring

Once created, your policy will be automatically monitored by Reactive Network. The system will:

- Watch Ethereum Sepolia for the specified threat patterns
- Process events through the `react()` function on Reactive Network
- Trigger emergency transfers when threats are detected
- Send funds to your specified destination address

### Manual Testing

Use the "Test Emergency Transfer" button to manually trigger a transfer and verify the system works.

## 🔧 Development

### Contract Architecture

#### WalletGuardianRN.sol (Reactive Network)
- **Extends**: `AbstractReactive`, `AbstractCallback`, `IReactive`
- **Key Functions**:
  - `createPolicy()`: Create new protection policy
  - `react()`: Process incoming events from subscriptions
  - `_handlePriceDropEvent()`: Process Uniswap V2 price changes
  - `_handleLargeTransferEvent()`: Detect suspicious transfers
  - `_triggerEmergencyTransfer()`: Execute cross-chain callback

#### WalletGuardianCallback.sol (Destination Chain)
- **Extends**: `AbstractCallback`, `Ownable`
- **Key Functions**:
  - `executeEmergencyTransfer()`: Receive and process emergency transfers
  - `withdrawFunds()`: Admin function for stuck funds

### Event Subscriptions

The contract subscribes to these event topics:

```solidity
// Uniswap V2 Sync events for price monitoring
uint256 private constant UNISWAP_V2_SYNC_TOPIC_0 = 0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1;

// ERC20 Transfer events for large transfer detection
uint256 private constant ERC20_TRANSFER_TOPIC_0 = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

// Common liquidation event signature
uint256 private constant LIQUIDATION_TOPIC_0 = 0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52;
```

### Testing

#### Local Testing with Anvil

1. **Start Anvil**: `anvil`
2. **Deploy Contracts**: Use deployment scripts
3. **Generate Test Events**: Interact with ERC20 tokens or DEX contracts on Sepolia
4. **Verify Monitoring**: Check that Reactive Network processes events and triggers callbacks

#### Integration Testing

1. **Deploy on Lasna**: Deploy reactive contract to Reactive Network testnet
2. **Monitor Real Events**: Watch actual Ethereum Sepolia events
3. **Verify Cross-Chain**: Confirm callbacks reach destination chains

## 🌐 Network Configuration

### Supported Chains

**Monitoring Chain** (via Reactive Network):
- Ethereum Sepolia (11155111)

**Destination Chains**:
- Anvil Local (31337)
- Ethereum Sepolia (11155111)  
- Lasna Testnet (167008)
- Ethereum Mainnet (1)
- Polygon (137)
- And more...

### Network Addresses

**Reactive Network (Lasna)**:
- RPC: `https://lasna-rpc.rnk.dev`
- Chain ID: `167008`
- System Contract: `0x0000000000000000000000000000000000fffFfF`
- Faucet: https://lasna-faucet.rnk.dev/

**Ethereum Sepolia**:
- RPC: `https://ethereum-sepolia.publicnode.com`
- Chain ID: `11155111`

## 🔒 Security Considerations

- **Private Key Management**: Never commit private keys to version control
- **Destination Address**: Use hardware wallets or multisig for destination addresses
- **Threshold Tuning**: Set appropriate thresholds to avoid false positives
- **Callback Authorization**: Only authorized senders can trigger callbacks
- **Emergency Pause**: Admin functions available for emergency situations

## 📖 Resources

- [Reactive Network Documentation](https://dev.reactive.network/)
- [Reactive Network Examples](https://github.com/Reactive-Network/reactive-smart-contract-demos)
- [Reactive Library GitHub](https://github.com/Reactive-Network/reactive-lib)
- [Foundry Book](https://book.getfoundry.sh/)

## ⚠️ Disclaimer

This is experimental software for educational and testing purposes. Use at your own risk. Always test thoroughly before using with real funds.
