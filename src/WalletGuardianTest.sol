// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MockERC20.sol";
import "./MockUniswapV2Pair.sol";
import "./MockLiquidationContract.sol";

/// @title WalletGuardianTest - Standalone version for testing core logic
contract WalletGuardianTest {
    struct UserProtection {
        address destinationAddress;
        uint256 emergencyThresholdPercent; // Price drop threshold (10 = 10%)
        uint256 maxTransferAmount; // Max single transfer amount
        bool isActive;
    }

    mapping(address => UserProtection) public userProtections;
    address[] public protectedUsers;
    
    constructor() payable {}
    
    event UserRegistered(address indexed user, address destinationAddress, uint256 threshold);
    event EmergencyTransferExecuted(address indexed user, string reason, uint256 amount);
    event PriceDropDetected(address indexed pair, uint256 oldPrice, uint256 newPrice, uint256 dropPercent);
    event LargeTransferDetected(address indexed user, address token, uint256 amount);
    event LiquidationDetected(address indexed user, address asset, uint256 amount);

    function registerUser(
        address destinationAddress,
        uint256 emergencyThresholdPercent,
        uint256 maxTransferAmount
    ) external payable {
        require(destinationAddress != address(0), "Invalid destination");
        require(emergencyThresholdPercent > 0 && emergencyThresholdPercent <= 50, "Invalid threshold");
        
        userProtections[msg.sender] = UserProtection({
            destinationAddress: destinationAddress,
            emergencyThresholdPercent: emergencyThresholdPercent,
            maxTransferAmount: maxTransferAmount,
            isActive: true
        });
        
        protectedUsers.push(msg.sender);
        
        emit UserRegistered(msg.sender, destinationAddress, emergencyThresholdPercent);
    }

    function checkPriceDrop(address pairAddress) external {
        MockUniswapV2Pair pair = MockUniswapV2Pair(pairAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        // Simple price calculation (token0/token1)
        uint256 currentPrice = (uint256(reserve1) * 1e18) / uint256(reserve0);
        
        // For testing, we'll assume we have a stored "previous price"
        // In real implementation, this would be stored and updated
        uint256 previousPrice = currentPrice * 120 / 100; // Simulate 20% higher previous price
        
        if (currentPrice < previousPrice) {
            uint256 dropPercent = ((previousPrice - currentPrice) * 100) / previousPrice;
            
            emit PriceDropDetected(pairAddress, previousPrice, currentPrice, dropPercent);
            
            // Check all protected users and trigger emergency if threshold exceeded
            for (uint i = 0; i < protectedUsers.length; i++) {
                address user = protectedUsers[i];
                UserProtection memory protection = userProtections[user];
                
                if (protection.isActive && dropPercent >= protection.emergencyThresholdPercent) {
                    _executeEmergencyTransfer(user, "Price drop detected", user.balance);
                }
            }
        }
    }

    function checkLargeTransfer(address user, address token, uint256 amount) external {
        UserProtection memory protection = userProtections[user];
        
        if (protection.isActive && amount > protection.maxTransferAmount) {
            emit LargeTransferDetected(user, token, amount);
            _executeEmergencyTransfer(user, "Large transfer detected", user.balance);
        }
    }

    function simulateLiquidationEvent(address user, address asset, uint256 amount) external {
        emit LiquidationDetected(user, asset, amount);
        
        UserProtection memory protection = userProtections[user];
        if (protection.isActive) {
            _executeEmergencyTransfer(user, "Liquidation detected", user.balance);
        }
    }

    function _executeEmergencyTransfer(address user, string memory reason, uint256 amount) internal {
        UserProtection memory protection = userProtections[user];
        
        if (amount > 0 && protection.destinationAddress != address(0)) {
            // In real implementation, this would transfer the actual funds
            // For testing, we just emit the event
            emit EmergencyTransferExecuted(user, reason, amount);
            
            // Simulate sending ETH (if available in this contract)
            if (address(this).balance > 0) {
                uint256 transferAmount = address(this).balance < amount ? address(this).balance : amount;
                payable(protection.destinationAddress).transfer(transferAmount);
            }
        }
    }

    function emergencyWithdraw(address user) external {
        UserProtection memory protection = userProtections[user];
        require(msg.sender == user || msg.sender == protection.destinationAddress, "Unauthorized");
        
        _executeEmergencyTransfer(user, "Manual emergency withdrawal", user.balance);
    }

    function getUserProtection(address user) external view returns (UserProtection memory) {
        return userProtections[user];
    }

    function getProtectedUsersCount() external view returns (uint256) {
        return protectedUsers.length;
    }

    // Allow contract to receive ETH for testing
    receive() external payable {}
}