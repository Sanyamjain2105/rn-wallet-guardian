// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title WalletGuardian - Simple wallet protection for testing
/// @notice Allows users to set up protection and test emergency transfers
contract WalletGuardian {
    
    struct Protection {
        address destinationAddress;  // Where to send funds in emergency
        uint256 protectedAmount;     // Amount of ETH being protected
        bool isActive;              // Whether protection is active
    }

    mapping(address => Protection) public userProtections;
    
    event ProtectionCreated(address indexed user, address destination, uint256 amount);
    event EmergencyTransfer(address indexed user, address destination, uint256 amount, string reason);
    event AttackDetected(string attackType, address indexed user);

    /// @notice Set up protection for your wallet
    /// @param destinationAddress Where to send funds in emergency (can be same user or different)
    function createProtection(address destinationAddress) external payable {
        require(msg.value > 0, "Must send ETH to protect");
        require(destinationAddress != address(0), "Invalid destination");
        
        userProtections[msg.sender] = Protection({
            destinationAddress: destinationAddress,
            protectedAmount: msg.value,
            isActive: true
        });
        
        emit ProtectionCreated(msg.sender, destinationAddress, msg.value);
    }

    /// @notice Simulate an attack and trigger emergency transfer
    /// @param user The user whose funds should be protected
    /// @param attackType Type of attack (for logging)
    function simulateAttack(address user, string memory attackType) external {
        Protection memory protection = userProtections[user];
        require(protection.isActive, "No active protection");
        require(protection.protectedAmount > 0, "No funds to protect");
        
        emit AttackDetected(attackType, user);
        
        // Transfer protected funds to destination
        uint256 amount = protection.protectedAmount;
        userProtections[user].protectedAmount = 0;
        userProtections[user].isActive = false;
        
        payable(protection.destinationAddress).transfer(amount);
        
        emit EmergencyTransfer(user, protection.destinationAddress, amount, attackType);
    }

    /// @notice Get protection details for a user
    function getProtection(address user) external view returns (Protection memory) {
        return userProtections[user];
    }

    /// @notice Check contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Emergency function to deactivate protection
    function deactivateProtection() external {
        userProtections[msg.sender].isActive = false;
    }
}