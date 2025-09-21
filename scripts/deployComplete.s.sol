// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/AdvancedWalletGuardian.sol";
import "../src/MockV3Aggregator.sol";
import "../src/MockAttackContract.sol";
import "../src/WalletGuardianCallback.sol";
import "../src/MockERC20.sol";
import "../src/MockUniswapV2Pair.sol";
import "../src/MockLiquidationContract.sol";

contract DeployComplete is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==============================================");
        console.log(" DEPLOYING COMPLETE WALLET GUARDIAN SYSTEM");
        console.log("==============================================");
        
        // Step 1: Deploy Mock Price Feed
        console.log(" Deploying Chainlink Mock Price Feed...");
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(8, 2000 * 1e8); // $2000 ETH
        console.log(" ETH/USD Price Feed:", address(ethUsdPriceFeed));
        
        // Step 2: Deploy Advanced Wallet Guardian
        console.log(" Deploying Advanced Wallet Guardian...");
        AdvancedWalletGuardian guardian = new AdvancedWalletGuardian(
            address(ethUsdPriceFeed),
            true  // isTestMode = true for local testing
        );
        console.log(" Advanced Guardian:", address(guardian));
        
        // Step 3: Deploy Mock Attack Contract  
        console.log(" Deploying Mock Attack Contract...");
        MockAttackContract attackContract = new MockAttackContract();
        console.log(" Mock Attack Contract:", address(attackContract));
        
        // Step 4: Deploy Callback Contract
        console.log(" Deploying Callback Contract...");
        WalletGuardianCallback callback = new WalletGuardianCallback{value: 0.1 ether}(vm.addr(deployerPrivateKey));
        console.log(" Callback Contract:", address(callback));
        
        // Step 5: Deploy Mock Tokens
        console.log(" Deploying Mock Tokens...");
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 1000000 * 10**6); // 1M USDC
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 1000 * 10**18); // 1000 WETH
        console.log(" USDC Token:", address(usdc));
        console.log(" WETH Token:", address(weth));
        
        // Step 6: Deploy Uniswap V2 Pair Mock
        console.log(" Deploying Uniswap V2 Pair Mock...");
        MockUniswapV2Pair pair = new MockUniswapV2Pair(address(usdc), address(weth));
        pair.setReserves(2000000 * 10**6, 1000 * 10**18); // 1 ETH = 2000 USDC
        console.log(" Uniswap V2 Pair:", address(pair));
        
        // Step 7: Deploy Liquidation Contract
        console.log(" Deploying Liquidation Contract...");
        MockLiquidationContract liquidation = new MockLiquidationContract();
        console.log(" Liquidation Contract:", address(liquidation));
        
        // Step 8: Fund test accounts
        console.log(" Funding test accounts...");
        address user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        
        usdc.transfer(user1, 10000 * 10**6); // 10,000 USDC
        usdc.transfer(user2, 5000 * 10**6);  // 5,000 USDC
        weth.transfer(user1, 10 * 10**18);   // 10 WETH
        weth.transfer(user2, 5 * 10**18);    // 5 WETH
        console.log(" Funded test accounts");
        
        console.log("");
        console.log("==============================================");
        console.log(" DEPLOYMENT COMPLETE!");
        console.log("==============================================");
        console.log(" CONTRACT ADDRESSES:");
        console.log("   Advanced Guardian:  ", address(guardian));
        console.log("   ETH/USD Price Feed: ", address(ethUsdPriceFeed));
        console.log("   Mock Attack:        ", address(attackContract));
        console.log("   Callback Contract:  ", address(callback));
        console.log("   USDC Token:         ", address(usdc));
        console.log("   WETH Token:         ", address(weth));
        console.log("   Uniswap V2 Pair:    ", address(pair));
        console.log("   Liquidation:        ", address(liquidation));
        console.log("");
        console.log(" SYSTEM FEATURES:");
        console.log("   [+] Real fund protection with deposits");
        console.log("   [+] Demo mode for safe testing");
        console.log("   [+] Chainlink price monitoring (mock)");
        console.log("   [+] Attack simulation contracts");
        console.log("   [+] Cross-chain callback system");
        console.log("   [+] Multi-token support");
        console.log("");
        console.log(" READY FOR TESTING:");
        console.log("   1. Open http://localhost:3000/index.html");
        console.log("   2. Connect MetaMask to Anvil (localhost:8545)");
        console.log("   3. Import test account with 1000 ETH");
        console.log("   4. Test both same-chain and cross-chain modes");
        console.log("");
        console.log(" Price Feed Commands:");
        console.log("   Update ETH price: ethUsdPriceFeed.updateAnswer(newPrice * 1e8)");
        console.log("   Current price: $2000 (can be changed for testing)");
        
        vm.stopBroadcast();
    }
}