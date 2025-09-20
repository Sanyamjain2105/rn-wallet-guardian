// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title WalletGuardianRN - Reactive Smart Contract for chain security monitoring and cross-chain fund protection
/// @notice Uses Reactive Network's native subscription service to monitor chain events and price drops

import "reactive-lib/src/interfaces/IReactive.sol";
import "reactive-lib/src/abstract-base/AbstractReactive.sol";
import "reactive-lib/src/interfaces/ISystemContract.sol";

/// @dev Reactive contract that monitors multiple chains for security threats and price drops
contract WalletGuardianRN is IReactive, AbstractReactive {
    // Event topic constants for monitoring
    uint256 private constant UNISWAP_V2_SYNC_TOPIC_0 = 0x1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1;
    uint256 private constant ERC20_TRANSFER_TOPIC_0 = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    uint256 private constant LIQUIDATION_TOPIC_0 = 0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52; // Common liquidation event
    
    // Chain IDs for monitoring
    uint256 private constant ETHEREUM_MAINNET = 1;
    uint256 private constant ETHEREUM_SEPOLIA = 11155111;
    uint256 private constant ANVIL_LOCAL = 31337;
    uint256 private constant LASNA_TESTNET = 167008;
    
    uint64 private constant CALLBACK_GAS_LIMIT = 1000000;

    // Policy storage for wallet protection
    struct Policy {
        address user;
        uint256 insuredAmount;
        uint256 priceDropThresholdBp; // Basis points (e.g., 2000 = 20% drop)
        uint256 liquidationThreshold; // Amount threshold for liquidation concerns
        uint64 destinationChainId; // Target chain for emergency transfers
        address destinationAddress; // Target address for fund transfer
        bool active;
        bool triggered;
    }

    uint256 public policyCount;
    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public userPolicies; // Track policies per user

    // Events
    event PolicyCreated(
        uint256 indexed policyId, 
        address indexed user, 
        uint64 destinationChainId,
        address destinationAddress
    );
    event SecurityThreatDetected(
        uint256 indexed policyId,
        string threatType,
        uint256 chainId,
        address contractAddress
    );
    event PriceDropDetected(
        uint256 indexed policyId,
        uint256 chainId,
        address tokenPair,
        uint256 dropPercentage
    );
    event EmergencyTransferInitiated(
        uint256 indexed policyId,
        address indexed user,
        uint256 amount,
        uint64 destinationChainId,
        address destinationAddress
    );

    constructor() payable {
        
        // Subscribe to multiple monitoring targets when deployed on Reactive Network
        if (!vm) {
            // Monitor Uniswap V2 Sync events on Anvil for price drops
            service.subscribe(
                ANVIL_LOCAL, // Monitor Anvil for testing
                address(0), // Any contract
                UNISWAP_V2_SYNC_TOPIC_0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
            
            // Monitor large ERC20 transfers that might indicate attacks
            service.subscribe(
                ANVIL_LOCAL,
                address(0), // Any contract
                ERC20_TRANSFER_TOPIC_0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
            
            // Monitor liquidation events
            service.subscribe(
                ANVIL_LOCAL,
                address(0), // Any contract
                LIQUIDATION_TOPIC_0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }

    // Create a new wallet protection policy
    function createPolicy(
        uint256 insuredAmount,
        uint256 priceDropThresholdBp,
        uint256 liquidationThreshold,
        uint64 destinationChainId,
        address destinationAddress
    ) external payable returns (uint256) {
        require(insuredAmount > 0, "Insured amount must be > 0");
        require(priceDropThresholdBp > 0 && priceDropThresholdBp <= 10000, "Invalid threshold");
        require(destinationChainId != 0, "Destination chain required");
        require(destinationAddress != address(0), "Destination address required");

        policyCount++;
        policies[policyCount] = Policy({
            user: msg.sender,
            insuredAmount: insuredAmount,
            priceDropThresholdBp: priceDropThresholdBp,
            liquidationThreshold: liquidationThreshold,
            destinationChainId: destinationChainId,
            destinationAddress: destinationAddress,
            active: true,
            triggered: false
        });

        userPolicies[msg.sender].push(policyCount);

        emit PolicyCreated(policyCount, msg.sender, destinationChainId, destinationAddress);
        return policyCount;
    }

    // The main reactive function - called by RN when subscribed events occur
    function react(LogRecord calldata log) external vmOnly {
        if (log.topic_0 == UNISWAP_V2_SYNC_TOPIC_0) {
            _handlePriceDropEvent(log);
        } else if (log.topic_0 == ERC20_TRANSFER_TOPIC_0) {
            _handleLargeTransferEvent(log);
        } else if (log.topic_0 == LIQUIDATION_TOPIC_0) {
            _handleLiquidationEvent(log);
        }
    }

    // Handle Uniswap V2 Sync events to detect price drops
    function _handlePriceDropEvent(LogRecord calldata log) internal {
        // Decode Uniswap V2 Sync event data: (uint112 reserve0, uint112 reserve1)
        (uint112 reserve0, uint112 reserve1) = abi.decode(log.data, (uint112, uint112));
        
        // Check all active policies for price drop triggers
        for (uint256 i = 1; i <= policyCount; i++) {
            Policy storage policy = policies[i];
            if (policy.active && !policy.triggered) {
                // Simplified price drop detection - in production, would track historical ratios
                // For demo, trigger if reserves indicate significant imbalance suggesting price drop
                bool significantImbalance = (reserve0 < reserve1 / 2) || (reserve1 < reserve0 / 2);
                if (significantImbalance) {
                    _triggerEmergencyTransfer(i, "PRICE_DROP", log.chain_id, log._contract);
                }
            }
        }
    }

    // Handle large ERC20 transfers that might indicate attacks
    function _handleLargeTransferEvent(LogRecord calldata log) internal {
        // Decode ERC20 Transfer event: Transfer(address from, address to, uint256 value)
        uint256 amount = abi.decode(log.data, (uint256));
        
        // Check for unusually large transfers
        for (uint256 i = 1; i <= policyCount; i++) {
            Policy storage policy = policies[i];
            if (policy.active && !policy.triggered && amount >= policy.liquidationThreshold) {
                _triggerEmergencyTransfer(i, "LARGE_TRANSFER", log.chain_id, log._contract);
            }
        }
    }

    // Handle liquidation events
    function _handleLiquidationEvent(LogRecord calldata log) internal {
        // Trigger emergency transfers for all active policies when liquidations detected
        for (uint256 i = 1; i <= policyCount; i++) {
            Policy storage policy = policies[i];
            if (policy.active && !policy.triggered) {
                _triggerEmergencyTransfer(i, "LIQUIDATION_DETECTED", log.chain_id, log._contract);
            }
        }
    }

    // Trigger emergency transfer via callback
    function _triggerEmergencyTransfer(
        uint256 policyId, 
        string memory threatType,
        uint256 eventChainId,
        address eventContract
    ) internal {
        Policy storage policy = policies[policyId];
        policy.triggered = true;

        emit SecurityThreatDetected(policyId, threatType, eventChainId, eventContract);

        // Emit callback to initiate cross-chain transfer
        bytes memory payload = abi.encodeWithSignature(
            "executeEmergencyTransfer(address,uint256,address)",
            policy.user,
            policy.insuredAmount,
            policy.destinationAddress
        );

        emit Callback(
            policy.destinationChainId,
            policy.destinationAddress, // This should be a callback contract on destination chain
            CALLBACK_GAS_LIMIT,
            payload
        );

        emit EmergencyTransferInitiated(
            policyId,
            policy.user,
            policy.insuredAmount,
            policy.destinationChainId,
            policy.destinationAddress
        );
    }

    // Manually trigger emergency transfer for testing
    function manualTrigger(uint256 policyId, string memory threatType) external {
        require(policyId > 0 && policyId <= policyCount, "Invalid policy ID");
        Policy storage policy = policies[policyId];
        require(policy.user == msg.sender, "Only policy owner can trigger");
        require(policy.active && !policy.triggered, "Policy not active or already triggered");

        _triggerEmergencyTransfer(policyId, threatType, block.chainid, address(this));
    }

    // Deactivate a policy
    function deactivatePolicy(uint256 policyId) external {
        require(policyId > 0 && policyId <= policyCount, "Invalid policy ID");
        Policy storage policy = policies[policyId];
        require(policy.user == msg.sender, "Only policy owner can deactivate");
        
        policy.active = false;
    }

    // View functions
    function getPolicy(uint256 policyId) external view returns (Policy memory) {
        return policies[policyId];
    }

    function getUserPolicies(address user) external view returns (uint256[] memory) {
        return userPolicies[user];
    }

    function getPolicyCount() external view returns (uint256) {
        return policyCount;
    }

    // Emergency function to pause all monitoring (only for testing)
    function emergencyPause() external {
        // In a real implementation, would unsubscribe from all events
        // For now, just emit an event
        emit SecurityThreatDetected(0, "EMERGENCY_PAUSE", block.chainid, address(this));
    }
}
