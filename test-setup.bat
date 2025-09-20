@echo off
echo 🛡️ Wallet Guardian - Reactive Network Test Setup
echo ================================================

echo 1. Checking if Foundry is available...
where forge >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Foundry not found. Please install Foundry first.
    echo Run: curl -L https://foundry.paradigm.xyz ^| bash
    pause
    exit /b 1
)

echo 2. Starting Anvil (destination chain)...
start /B anvil --port 8546 --accounts 10 --balance 1000 --chain-id 31337
timeout /t 3 >nul

echo 3. Deploying contracts on Anvil...
echo Deploying WalletGuardianCallback and MockAttackContract...
for /f "delims=" %%i in ('forge script scripts/deployReactive.s.sol --rpc-url http://localhost:8546 --broadcast --chain-id 31337 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 2^>^&1 ^| findstr "deployed at:"') do (
    echo %%i
)

echo 4. Starting HTTP server...
start /B python -m http.server 8080
timeout /t 2 >nul

echo.
echo 🚀 REACTIVE NETWORK SETUP COMPLETE!
echo =====================================
echo.
echo 📊 ARCHITECTURE:
echo ┌─ Reactive Network (Lasna) ────────────────┐
echo │  WalletGuardianRN.sol                     │
echo │  ↓ Monitors Anvil events                  │
echo │  ↓ Executes react() on threats            │
echo └───────────────────────────────────────────┘
echo                    ↓ Cross-chain callback
echo ┌─ Anvil (localhost:8546) ──────────────────┐
echo │  WalletGuardianCallback.sol               │
echo │  MockAttackContract.sol                   │
echo │  ↓ Receives emergency transfers           │
echo └───────────────────────────────────────────┘
echo.
echo 🔗 NEXT STEPS:
echo 1. Open: http://localhost:8080/test-dashboard.html
echo 2. Connect MetaMask to Anvil (Chain ID: 31337)
echo 3. Deploy WalletGuardianRN on Lasna testnet (manual step)
echo 4. Create protection policy 
echo 5. Run attack simulation
echo 6. Watch funds transfer automatically!
echo.
echo 📋 Test Accounts (1000 ETH each):
echo Account #1: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
echo Account #2: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
echo Account #3: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
echo.
echo 🔑 Private Keys:
echo Account #1: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
echo Account #2: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
echo.
echo ⚠️  IMPORTANT: For full testing, you need:
echo 1. Funds on Lasna testnet (get from faucet)
echo 2. Deploy WalletGuardianRN on Lasna manually
echo 3. Set up callback proxy addresses
echo.
echo Press any key to stop all services...
pause >nul

echo Stopping services...
taskkill /F /IM anvil.exe >nul 2>nul
taskkill /F /IM python.exe >nul 2>nul
echo ✅ Services stopped