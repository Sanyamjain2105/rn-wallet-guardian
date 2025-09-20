// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/WalletGuardianRN.sol";
import "../src/WalletGuardianCallback.sol";
import "../src/MockAttackContract.sol";

contract DeployReactiveSystem is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        if (block.chainid == 167008) {
            // Deploy on Lasna testnet (Reactive Network)
            deployReactiveContract();
        } else if (block.chainid == 31337) {
            // Deploy on Anvil (destination chain)
            deployAnvilContracts();
        } else {
            revert("Unsupported chain. Use Lasna (167008) or Anvil (31337)");
        }
        
        vm.stopBroadcast();
    }
    
    function deployReactiveContract() internal {
        console.log("Deploying on Reactive Network (Lasna)...");
        
        // Deploy the reactive monitoring contract
        WalletGuardianRN guardianRN = new WalletGuardianRN();
        
        console.log("WalletGuardianRN deployed at:", address(guardianRN));
        console.log("This contract will monitor Anvil chain for threats");
        
        // The contract automatically subscribes to events in its constructor
        console.log("Subscriptions active for:");
        console.log("- ERC20 Transfer events (large transfers)");
        console.log("- Uniswap V2 Sync events (price drops)");  
        console.log("- Liquidation events");
    }
    
    function deployAnvilContracts() internal {
        console.log("Deploying on Anvil (destination chain)...");
        
        // For Anvil, we need the callback proxy address
        // In real deployment, this would be the Reactive Network callback proxy
        address callbackProxy = vm.envOr("CALLBACK_PROXY_ADDR", address(0x0000000000000000000000000000000000001000));
        
        // Deploy callback contract
        WalletGuardianCallback callback = new WalletGuardianCallback{value: 1 ether}(callbackProxy);
        console.log("WalletGuardianCallback deployed at:", address(callback));
        
        // Deploy mock attack contract for testing
        MockAttackContract mockAttack = new MockAttackContract();
        console.log("MockAttackContract deployed at:", address(mockAttack));
        
        console.log("");
        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("Callback Contract:", address(callback));
        console.log("Mock Attack Contract:", address(mockAttack));
        console.log("");
        console.log("Next steps:");
        console.log("1. Update dashboard with contract addresses");
        console.log("2. Create protection policy on Reactive Network");
        console.log("3. Test attack simulation");
    }
    
    function deployTestingSetup() external {
        // Helper function for testing
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy callback (simulated)
        WalletGuardianCallback callback = new WalletGuardianCallback{value: 1 ether}(address(0x1000));
        
        // Deploy mock attack
        MockAttackContract mockAttack = new MockAttackContract();
        
        vm.stopBroadcast();
        
        console.log("Testing setup deployed:");
        console.log("Callback:", address(callback));
        console.log("Mock Attack:", address(mockAttack));
    }
}