// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/MockERC20.sol";
import "../src/MockUniswapV2Pair.sol";
import "../src/MockLiquidationContract.sol";
import "../src/WalletGuardianTest.sol";

contract TestWalletGuardian is Script {
    MockERC20 usdc;
    MockERC20 weth;
    MockUniswapV2Pair pair;
    MockLiquidationContract liquidation;
    WalletGuardianTest guardian;
    
    address deployer;
    address user1;
    address user2;
    address emergencyAddress;

    function run() external {
        uint256 pk = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        deployer = vm.addr(pk);
        user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        emergencyAddress = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        
        vm.startBroadcast(pk);
        
        console.log("=== DEPLOYING CONTRACTS ===");
        deployContracts();
        
        console.log("\n=== SETTING UP TEST SCENARIO ===");
        setupTestScenario();
        
        console.log("\n=== TESTING PRICE DROP DETECTION ===");
        testPriceDropDetection();
        
        console.log("\n=== TESTING LARGE TRANSFER DETECTION ===");
        testLargeTransferDetection();
        
        console.log("\n=== TESTING LIQUIDATION DETECTION ===");
        testLiquidationDetection();
        
        vm.stopBroadcast();
        
        console.log("\n=== ALL TESTS COMPLETED ===");
    }

    function deployContracts() internal {
        // Deploy tokens
        usdc = new MockERC20("USD Coin", "USDC", 1000000 * 10**6);
        weth = new MockERC20("Wrapped Ether", "WETH", 1000 * 10**18);
        
        console.log("USDC deployed at:", address(usdc));
        console.log("WETH deployed at:", address(weth));
        
        // Deploy Uniswap V2 pair
        pair = new MockUniswapV2Pair(address(usdc), address(weth));
        console.log("Uniswap V2 Pair deployed at:", address(pair));
        
        // Set initial reserves (1 ETH = 2000 USDC)
        pair.setReserves(2000000 * 10**6, 1000 * 10**18);
        console.log("Initial reserves set: 2M USDC, 1000 WETH");
        
        // Deploy liquidation contract
        liquidation = new MockLiquidationContract();
        console.log("Liquidation contract deployed at:", address(liquidation));
        
        // Deploy guardian test contract
        guardian = new WalletGuardianTest{value: 5 ether}();
        console.log("WalletGuardianTest deployed at:", address(guardian));
        console.log("Guardian funded with 5 ETH");
    }

    function setupTestScenario() internal {
        // Fund users with tokens
        usdc.transfer(user1, 10000 * 10**6); // 10,000 USDC
        usdc.transfer(user2, 5000 * 10**6);  // 5,000 USDC
        weth.transfer(user1, 10 * 10**18);   // 10 WETH
        weth.transfer(user2, 5 * 10**18);    // 5 WETH
        
        console.log("Funded user1:", user1, "with 10,000 USDC and 10 WETH");
        console.log("Funded user2:", user2, "with 5,000 USDC and 5 WETH");
        
        // Send some ETH to users for gas and testing
        payable(user1).transfer(10 ether);
        payable(user2).transfer(10 ether);
        
        console.log("Sent 10 ETH to each user for testing");
        
        // Register users with the guardian
        vm.stopBroadcast();
        
        // Register user1 with 15% price drop threshold
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d); // user1 pk
        guardian.registerUser{value: 1 ether}(
            emergencyAddress,
            15, // 15% price drop threshold
            5 ether // Max 5 ETH single transfer
        );
        vm.stopBroadcast();
        
        // Register user2 with 20% price drop threshold
        vm.startBroadcast(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a); // user2 pk
        guardian.registerUser{value: 2 ether}(
            emergencyAddress,
            20, // 20% price drop threshold
            3 ether // Max 3 ETH single transfer
        );
        vm.stopBroadcast();
        
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80); // deployer pk
        
        console.log("User1 registered with 15% threshold");
        console.log("User2 registered with 20% threshold");
    }

    function testPriceDropDetection() internal {
        console.log("Current pair address:", address(pair));
        
        // Simulate a 25% price drop
        console.log("Simulating 25% price drop...");
        pair.simulatePriceDrop(25);
        
        // Check price drop (this should trigger emergency transfers)
        guardian.checkPriceDrop(address(pair));
        
        console.log("Price drop test completed - check events for emergency transfers");
    }

    function testLargeTransferDetection() internal {
        console.log("Testing large transfer detection...");
        
        // Simulate large transfer that exceeds user1's threshold (5 ETH)
        guardian.checkLargeTransfer(user1, address(weth), 7 ether);
        
        console.log("Large transfer test completed for user1 (7 ETH > 5 ETH threshold)");
        
        // Test transfer below threshold
        guardian.checkLargeTransfer(user2, address(weth), 2 ether);
        
        console.log("Normal transfer test completed for user2 (2 ETH < 3 ETH threshold)");
    }

    function testLiquidationDetection() internal {
        console.log("Testing liquidation detection...");
        
        // Simulate liquidation event
        guardian.simulateLiquidationEvent(user1, address(usdc), 5000 * 10**6);
        
        console.log("Liquidation test completed for user1");
        
        // Test emergency withdrawal with correct permissions
        console.log("Testing manual emergency withdrawal...");
        vm.stopBroadcast();
        
        // Use user2's private key to call their own emergency withdrawal
        vm.startBroadcast(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a); // user2 pk
        guardian.emergencyWithdraw(user2);
        vm.stopBroadcast();
        
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80); // back to deployer
        
        console.log("Manual emergency withdrawal test completed for user2");
    }
}