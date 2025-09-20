// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/SimpleWalletGuardian.sol";

contract DeploySimple is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the simple contract
        SimpleWalletGuardian guardian = new SimpleWalletGuardian();
        
        console.log("SimpleWalletGuardian deployed at:", address(guardian));
        
        vm.stopBroadcast();
    }
}