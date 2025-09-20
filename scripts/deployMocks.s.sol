// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/MockERC20.sol";
import "../src/MockUniswapV2Pair.sol";
import "../src/MockLiquidationContract.sol";
import "../src/WalletGuardianCallback.sol";

contract DeployMockContracts is Script {
    function run() external {
        uint256 pk = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        vm.startBroadcast(pk);
        
        // Deploy tokens
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 1000000 * 10**6); // 1M USDC with 6 decimals
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 1000 * 10**18); // 1000 WETH
        
        console.log("USDC deployed at:", address(usdc));
        console.log("WETH deployed at:", address(weth));
        
        // Deploy Uniswap V2 pair
        MockUniswapV2Pair pair = new MockUniswapV2Pair(address(usdc), address(weth));
        console.log("Uniswap V2 Pair deployed at:", address(pair));
        
        // Set initial reserves (1 ETH = 2000 USDC)
        pair.setReserves(2000000 * 10**6, 1000 * 10**18); // 2M USDC, 1000 WETH
        
        // Deploy liquidation contract
        MockLiquidationContract liquidation = new MockLiquidationContract();
        console.log("Liquidation contract deployed at:", address(liquidation));
        
        // Deploy callback contract (using deployer as callback proxy for testing)
        WalletGuardianCallback callback = new WalletGuardianCallback{value: 0.1 ether}(vm.addr(pk));
        console.log("WalletGuardianCallback deployed at:", address(callback));
        
        // Fund some accounts with tokens for testing
        address user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        
        usdc.transfer(user1, 10000 * 10**6); // 10,000 USDC
        usdc.transfer(user2, 5000 * 10**6);  // 5,000 USDC
        weth.transfer(user1, 10 * 10**18);   // 10 WETH
        weth.transfer(user2, 5 * 10**18);    // 5 WETH
        
        console.log("Funded user1:", user1);
        console.log("Funded user2:", user2);
        
        vm.stopBroadcast();
        
        // Save addresses to file for frontend
        string memory addresses = string(abi.encodePacked(
            "USDC_ADDRESS=", vm.toString(address(usdc)), "\n",
            "WETH_ADDRESS=", vm.toString(address(weth)), "\n",
            "PAIR_ADDRESS=", vm.toString(address(pair)), "\n",
            "LIQUIDATION_ADDRESS=", vm.toString(address(liquidation)), "\n",
            "CALLBACK_ADDRESS=", vm.toString(address(callback)), "\n"
        ));
        
        vm.writeFile("deployed_addresses.env", addresses);
        console.log("Addresses saved to deployed_addresses.env");
    }
}