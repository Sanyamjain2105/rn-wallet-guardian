// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/AdvancedWalletGuardian.sol";
import "../src/MockV3Aggregator.sol";

contract DeployAdvanced is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Mock Price Feed for local testing
        // ETH/USD price feed with 8 decimals, starting at $2000
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(8, 2000 * 1e8);
        
        // Deploy Advanced Wallet Guardian with mock price feed
        AdvancedWalletGuardian guardian = new AdvancedWalletGuardian(
            address(ethUsdPriceFeed),
            true  // isTestMode = true for local testing
        );
        
        console.log("Mock ETH/USD Price Feed deployed at:", address(ethUsdPriceFeed));
        console.log("Advanced Wallet Guardian deployed at:", address(guardian));
        console.log("Current ETH Price: $2000 (mock)");
        console.log("");
        console.log("Features enabled:");
        console.log("  [+] Real fund protection");
        console.log("  [+] Demo mode for safe testing");
        console.log("  [+] Chainlink price monitoring (mock for local)");
        console.log("  [+] Multi-chain support");
        console.log("  [+] Advanced threat detection");
        console.log("");
        console.log("To simulate price changes:");
        console.log("  ethUsdPriceFeed.updateAnswer(newPrice * 1e8)");
        
        vm.stopBroadcast();
    }
}