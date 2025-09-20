// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MockERC20.sol";

/// @title MockUniswapV2Pair - Simplified Uniswap V2 pair for testing
contract MockUniswapV2Pair {
    address public token0;
    address public token1;
    
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    event Sync(uint112 reserve0, uint112 reserve1);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = uint32(block.timestamp);
        emit Sync(reserve0, reserve1);
    }

    function simulatePriceDrop(uint256 dropPercentage) external {
        require(dropPercentage <= 100, "Invalid drop percentage");
        
        // Simulate price drop by reducing token0 reserves (assuming token0 is the monitored token)
        uint112 newReserve0 = uint112(reserve0 * (100 - dropPercentage) / 100);
        reserve0 = newReserve0;
        blockTimestampLast = uint32(block.timestamp);
        
        emit Sync(reserve0, reserve1);
    }

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata /* data */
    ) external {
        require(amount0Out > 0 || amount1Out > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        
        if (amount0Out > 0) MockERC20(token0).transfer(to, amount0Out);
        if (amount1Out > 0) MockERC20(token1).transfer(to, amount1Out);
        
        emit Swap(msg.sender, 0, 0, amount0Out, amount1Out, to);
    }
}