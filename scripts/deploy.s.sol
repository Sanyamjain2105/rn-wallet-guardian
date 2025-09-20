// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/WalletGuardianRN.sol";
import "../src/WalletGuardianCallback.sol";

contract DeployWalletGuardian is Script {
    function run() external {
        string memory pkStr = vm.envString("PRIVATE_KEY");
        uint256 pk = vm.parseUint(pkStr);
        
        vm.startBroadcast(pk);
        
        if (block.chainid == 167008) {
            // Deploy on Lasna testnet (Reactive Network)
            deployReactiveContract(pk);
        } else {
            // Deploy callback contract on destination chains (Anvil, Sepolia, etc.)
            deployCallbackContract(pk);
        }
        
        vm.stopBroadcast();
    }
    
    function deployReactiveContract(uint256 /* pk */) internal {
        // For Reactive Network deployment, we need the system contract address
        address systemContract = vm.envOr("SYSTEM_CONTRACT_ADDR", address(0x0000000000000000000000000000000000fffFfF));
        
        require(systemContract != address(0), "System contract address required for Reactive Network");
        
        // Deploy with required payment for subscriptions (0.1 ether)
        WalletGuardianRN guardian = new WalletGuardianRN{value: 0.1 ether}();
        
        console.log("WalletGuardianRN (Reactive) deployed at:", address(guardian));
        console.log("System contract used:", systemContract);
        console.log("Chain ID:", block.chainid);
        console.log("Subscriptions: Uniswap V2 Sync, ERC20 Transfers, Liquidations");
    }
    
    function deployCallbackContract(uint256 pk) internal {
        // For destination chains, deploy callback contract
        address callbackProxy = vm.envOr("CALLBACK_PROXY_ADDR", address(0));
        
        if (callbackProxy == address(0)) {
            // Default callback proxy addresses for different networks
            if (block.chainid == 11155111) {
                // Sepolia testnet - check Reactive docs for actual address
                callbackProxy = 0x0000000000000000000000000000000000000000; // Update with real address
            } else if (block.chainid == 31337) {
                // Anvil local - for testing, use deployer address
                callbackProxy = vm.addr(pk);
            }
        }
        
        require(callbackProxy != address(0), "Callback proxy address required");
        
        WalletGuardianCallback callback = new WalletGuardianCallback{value: 0.05 ether}(callbackProxy);
        
        console.log("WalletGuardianCallback deployed at:", address(callback));
        console.log("Callback proxy used:", callbackProxy);
        console.log("Chain ID:", block.chainid);
        console.log("Ready to receive emergency transfers");
    }
}
