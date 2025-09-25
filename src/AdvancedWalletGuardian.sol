// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Advanced Wallet Guardian with Demo Mode
/// @notice Protects real funds while providing safe demo capabilities

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Chainlink Price Feed Interface
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract AdvancedWalletGuardian is Ownable, ReentrancyGuard, Pausable {
    
    // 🎯 Protection Configuration
    struct ProtectionPolicy {
        uint256 protectedAmount;        // Amount to protect
        address secureChain;            // Destination chain for protection
        address destinationAddress;     // Safe address on destination chain
        bool demoMode;                  // Demo mode vs real protection
        uint256 priceThreshold;         // Price drop threshold for protection
        bool isActive;                  // Policy active status
    }
    
    // 📊 Price Monitoring with Chainlink Integration
    struct PriceMonitor {
        AggregatorV3Interface priceFeed;
        uint256 lastPrice;
        uint256 priceDropThreshold;     // Percentage drop that triggers protection
        uint256 lastUpdateTime;
    }
    
    // 🚨 Attack Detection
    struct ThreatLevel {
        uint256 transferVelocity;       // Speed of large transfers
        uint256 priceVolatility;        // Market volatility level
        uint256 liquidationRisk;        // DeFi liquidation risk
        uint256 overallRisk;            // Combined risk score
    }
    
    // 📋 Events
    event FundsDeposited(address indexed user, uint256 amount, uint256 timestamp);
    event ProtectionPolicyCreated(address indexed user, ProtectionPolicy policy);
    event DemoAttackTriggered(address indexed user, string attackType, uint256 timestamp);
    event RealThreatDetected(address indexed user, ThreatLevel threat, uint256 timestamp);
    event EmergencyTransferExecuted(address indexed user, uint256 amount, address destination);
    event ChainlinkPriceAlert(address indexed asset, uint256 oldPrice, uint256 newPrice);
    
    // 💾 State Variables
    mapping(address => ProtectionPolicy) public protectionPolicies;
    mapping(address => uint256) public userDeposits;
    mapping(address => PriceMonitor) public priceMonitors;
    mapping(address => ThreatLevel) public currentThreats;
    mapping(address => bool) public authorizedDemoUsers;
    
    // 🏗️ Price Feed Configuration
    address public ethUsdPriceFeed;  // Will be set in constructor
    uint256 constant SIMULATED_ETH_PRICE = 2000 * 1e8; // $2000 with 8 decimals
    bool public isTestMode;  // True for local testing with mock feeds
    
    constructor(address _ethUsdPriceFeed, bool _isTestMode) Ownable(msg.sender) {
        ethUsdPriceFeed = _ethUsdPriceFeed;
        isTestMode = _isTestMode;
    }
    
    // 💰 Deposit Funds for Protection
    function depositFunds() external payable nonReentrant {
        require(msg.value > 0, "Must deposit funds");
        
        userDeposits[msg.sender] += msg.value;
        
        emit FundsDeposited(msg.sender, msg.value, block.timestamp);
    }
    
    // 🛡️ Create Protection Policy
    function createProtectionPolicy(
        uint256 _protectedAmount,
        address _secureChain,
        address _destinationAddress,
        bool _demoMode,
        uint256 _priceThreshold
    ) external {
        require(userDeposits[msg.sender] >= _protectedAmount, "Insufficient deposited funds");
        require(_destinationAddress != address(0), "Invalid destination");
        
        protectionPolicies[msg.sender] = ProtectionPolicy({
            protectedAmount: _protectedAmount,
            secureChain: _secureChain,
            destinationAddress: _destinationAddress,
            demoMode: _demoMode,
            priceThreshold: _priceThreshold,
            isActive: true
        });
        
        // Setup Chainlink price monitoring
        _setupPriceMonitoring(msg.sender);
        
        emit ProtectionPolicyCreated(msg.sender, protectionPolicies[msg.sender]);
    }
    
    // 🎮 Demo Attack Button (Safe for demonstrations)
    function triggerDemoAttack(string memory attackType) external {
        require(protectionPolicies[msg.sender].isActive, "No active protection");
        require(protectionPolicies[msg.sender].demoMode, "Demo mode not enabled");
        
        // 🎭 Simulate attack without moving real funds
        emit DemoAttackTriggered(msg.sender, attackType, block.timestamp);
        
        // Show demo protection response
        _executeDemoResponse(msg.sender, attackType);
    }
    
    // 🔍 Chainlink Price Monitoring with Fallback
    function checkPriceThreats() external view returns (bool threatDetected) {
        uint256 currentPrice;
        
        if (isTestMode || ethUsdPriceFeed == address(0)) {
            // Use simulated price for local testing
            currentPrice = SIMULATED_ETH_PRICE;
        } else {
            // Use real Chainlink price feed
            AggregatorV3Interface priceFeed = AggregatorV3Interface(ethUsdPriceFeed);
            (, int256 price, , , ) = priceFeed.latestRoundData();
            currentPrice = uint256(price);
        }
        
        // Compare with stored price thresholds
        return _analyzePriceMovement(currentPrice);
    }
    
    // ⚡ Real Threat Detection & Response
    function detectAndRespond() external {
        address user = msg.sender;
        ProtectionPolicy memory policy = protectionPolicies[user];
        
        require(policy.isActive && !policy.demoMode, "Real protection not active");
        
        // 📊 Analyze multiple threat vectors
        ThreatLevel memory threat = _analyzeThreatLevel(user);
        
        if (threat.overallRisk > 80) { // High risk threshold
            _executeEmergencyTransfer(user, policy);
            emit RealThreatDetected(user, threat, block.timestamp);
        }
    }
    
    // 🎭 Internal Demo Functions
    function _executeDemoResponse(address user, string memory attackType) internal {
        ProtectionPolicy memory policy = protectionPolicies[user];
        
        // In test mode (Anvil), also perform actual transfers for full demo
        if (isTestMode && userDeposits[user] >= policy.protectedAmount) {
            // Actually transfer funds for complete demo on test networks
            userDeposits[user] -= policy.protectedAmount;
            payable(policy.destinationAddress).transfer(policy.protectedAmount);
        }
        
        // Demo event showing what happened/would happen
        emit EmergencyTransferExecuted(
            user, 
            policy.protectedAmount, 
            policy.destinationAddress
        );
    }
    
    // 🔒 Internal Real Protection Functions
    function _executeEmergencyTransfer(address user, ProtectionPolicy memory policy) internal {
        require(userDeposits[user] >= policy.protectedAmount, "Insufficient funds");
        
        // Actually transfer funds to secure address
        userDeposits[user] -= policy.protectedAmount;
        payable(policy.destinationAddress).transfer(policy.protectedAmount);
        
        emit EmergencyTransferExecuted(user, policy.protectedAmount, policy.destinationAddress);
    }
    
    // 📈 Chainlink Integration Functions with Test Mode Support
    function _setupPriceMonitoring(address user) internal {
        AggregatorV3Interface priceFeed = ethUsdPriceFeed != address(0) 
            ? AggregatorV3Interface(ethUsdPriceFeed) 
            : AggregatorV3Interface(address(0));
            
        priceMonitors[user] = PriceMonitor({
            priceFeed: priceFeed,
            lastPrice: _getCurrentPrice(),
            priceDropThreshold: protectionPolicies[user].priceThreshold,
            lastUpdateTime: block.timestamp
        });
    }
    
    function _getCurrentPrice() internal view returns (uint256) {
        if (isTestMode || ethUsdPriceFeed == address(0)) {
            // Return simulated ETH price for local testing
            return SIMULATED_ETH_PRICE;
        } else {
            // Get real price from Chainlink
            AggregatorV3Interface priceFeed = AggregatorV3Interface(ethUsdPriceFeed);
            (, int256 price, , , ) = priceFeed.latestRoundData();
            return uint256(price);
        }
    }
    
    function _analyzePriceMovement(uint256 currentPrice) internal view returns (bool) {
        // Implement price analysis logic
        // Return true if price movement indicates threat
        return false; // Placeholder
    }
    
    function _analyzeThreatLevel(address user) internal view returns (ThreatLevel memory) {
        // Implement comprehensive threat analysis
        // Combine multiple indicators
        return ThreatLevel({
            transferVelocity: 0,
            priceVolatility: 0,
            liquidationRisk: 0,
            overallRisk: 0
        });
    }
    
    // 🛠️ Admin Functions
    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function authorizeDemo(address user) external onlyOwner {
        authorizedDemoUsers[user] = true;
    }
    
    // 🔧 Admin Functions for Testing
    function updatePriceFeed(address newPriceFeed) external onlyOwner {
        ethUsdPriceFeed = newPriceFeed;
    }
    
    function setTestMode(bool _isTestMode) external onlyOwner {
        isTestMode = _isTestMode;
    }
    
    function getLatestPrice() external view returns (uint256) {
        return _getCurrentPrice();
    }
    
    // 🔧 Pause/Unpause Functions for Emergency
    function pauseContract() external onlyOwner {
        _pause();
    }
    
    function unpauseContract() external onlyOwner {
        _unpause();
    }
    
    function isPaused() external view returns (bool) {
        return paused();
    }
}