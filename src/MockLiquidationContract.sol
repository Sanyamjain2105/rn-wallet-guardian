// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MockERC20.sol";

/// @title MockLiquidationContract - Simulates liquidation events
contract MockLiquidationContract {
    event LiquidationCall(
        address indexed user,
        address indexed asset,
        uint256 liquidatedAmount,
        uint256 penalty
    );

    function liquidateUser(
        address user,
        address asset,
        uint256 amount
    ) external {
        uint256 penalty = amount * 10 / 100; // 10% penalty
        
        emit LiquidationCall(user, asset, amount, penalty);
        
        // Transfer the liquidated amount (in real scenario, this would be more complex)
        MockERC20(asset).transferFrom(user, msg.sender, amount);
    }

    function simulateLiquidation(
        address user,
        address asset,
        uint256 amount
    ) external {
        uint256 penalty = amount * 10 / 100;
        emit LiquidationCall(user, asset, amount, penalty);
    }
}