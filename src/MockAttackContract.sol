// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title MockAttackContract - Simulates various attacks for testing Reactive Network
contract MockAttackContract {
    
    // Events that Reactive Network will monitor
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Sync(uint112 reserve0, uint112 reserve1);
    event LiquidationExecuted(address indexed user, address indexed asset, uint256 amount);
    
    // Custom event for our attack simulation
    event AttackSimulated(string attackType, address indexed target, uint256 amount);
    
    constructor() {}
    
    /// @notice Simulate a large suspicious transfer (triggers ERC20_TRANSFER_TOPIC_0)
    function simulateLargeTransfer(address from, address to, uint256 amount) external {
        emit Transfer(from, to, amount);
        emit AttackSimulated("Large Transfer Attack", from, amount);
    }
    
    /// @notice Simulate a price drop (triggers UNISWAP_V2_SYNC_TOPIC_0)  
    function simulatePriceDrop(uint112 newReserve0, uint112 newReserve1) external {
        emit Sync(newReserve0, newReserve1);
        emit AttackSimulated("Price Drop Attack", msg.sender, 0);
    }
    
    /// @notice Simulate liquidation event (triggers LIQUIDATION_TOPIC_0)
    function simulateLiquidation(address user, address asset, uint256 amount) external {
        emit LiquidationExecuted(user, asset, amount);
        emit AttackSimulated("Liquidation Attack", user, amount);
    }
    
    /// @notice General attack simulation
    function triggerAttack(string memory attackType, address target) external {
        // Emit a large transfer to trigger Reactive Network monitoring
        emit Transfer(target, address(0xdead), 1000 ether);
        emit AttackSimulated(attackType, target, 1000 ether);
    }
}