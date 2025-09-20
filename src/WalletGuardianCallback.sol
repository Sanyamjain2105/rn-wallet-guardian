// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title WalletGuardianCallback - Destination chain contract for receiving emergency transfers
/// @notice Receives callbacks from Reactive Network and executes emergency fund transfers

import "@openzeppelin/contracts/access/Ownable.sol";
import "reactive-lib/src/abstract-base/AbstractCallback.sol";

contract WalletGuardianCallback is AbstractCallback, Ownable {
    event EmergencyTransferReceived(
        address indexed user,
        uint256 amount,
        address destinationAddress,
        uint256 timestamp
    );
    
    event FundsWithdrawn(address indexed owner, uint256 amount);

    constructor(address _callbackProxy) 
        AbstractCallback(_callbackProxy) 
        Ownable(msg.sender) 
        payable 
    {}

    // Called by Reactive Network when emergency transfer is triggered
    function executeEmergencyTransfer(
        address user,
        uint256 amount,
        address destinationAddress
    ) external authorizedSenderOnly {
        // In a real implementation, this would:
        // 1. Verify the user has funds to protect
        // 2. Execute the actual transfer (token transfer, ETH transfer, etc.)
        // 3. Notify the user of the emergency action
        
        // For now, just emit event and handle any ETH sent with the callback
        emit EmergencyTransferReceived(user, amount, destinationAddress, block.timestamp);
        
        // If there's ETH in the contract, send it to the user's destination address
        if (address(this).balance > 0 && destinationAddress != address(0)) {
            payable(destinationAddress).transfer(address(this).balance);
        }
    }

    // Allow owner to withdraw any stuck funds
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(owner()).transfer(balance);
        emit FundsWithdrawn(owner(), balance);
    }

    // Allow the contract to receive ETH
    receive() external payable override {}
    
    // Fallback function
    fallback() external payable {}
}