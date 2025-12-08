// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";

/// @title ISwapRouter
/// @notice Simple interface for swap execution
interface ISwapRouter {
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);
}

/// @title YieldCompound
/// @notice Compounds harvested rewards back into liquidity
/// @dev Handles reward conversion and liquidity addition
contract YieldCompound is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // ============ State Variables ============
    
    IPoolManager public immutable poolManager;
    ISwapRouter public swapRouter;
    
    // Authorized callers (e.g., YieldShiftHook)
    mapping(address => bool) public authorizedCallers;
    
    // Track compounded rewards per pool
    mapping(PoolId => uint256) public totalCompounded;
    
    // Slippage tolerance in basis points (default 1%)
    uint256 public slippageTolerance = 100;

    // ============ Events ============
    
    event RewardsCompounded(
        PoolId indexed poolId,
        uint256 rewardAmount,
        uint256 amount0Added,
        uint256 amount1Added
    );
    event SwapRouterUpdated(address indexed oldRouter, address indexed newRouter);
    event SlippageToleranceUpdated(uint256 oldTolerance, uint256 newTolerance);
    event CallerAuthorized(address indexed caller, bool authorized);

    // ============ Modifiers ============
    
    modifier onlyAuthorized() {
        require(
            authorizedCallers[msg.sender] || msg.sender == owner(),
            "YieldCompound: Not authorized"
        );
        _;
    }

    // ============ Constructor ============
    
    constructor(address _poolManager) Ownable(msg.sender) {
        require(_poolManager != address(0), "YieldCompound: Invalid pool manager");
        poolManager = IPoolManager(_poolManager);
    }

    // ============ Admin Functions ============
    
    /// @notice Set the swap router
    /// @param _swapRouter New swap router address
    function setSwapRouter(address _swapRouter) external onlyOwner {
        emit SwapRouterUpdated(address(swapRouter), _swapRouter);
        swapRouter = ISwapRouter(_swapRouter);
    }

    /// @notice Set slippage tolerance
    /// @param _slippageTolerance New tolerance in basis points
    function setSlippageTolerance(uint256 _slippageTolerance) external onlyOwner {
        require(_slippageTolerance <= 1000, "YieldCompound: Tolerance too high"); // Max 10%
        emit SlippageToleranceUpdated(slippageTolerance, _slippageTolerance);
        slippageTolerance = _slippageTolerance;
    }

    /// @notice Authorize a caller
    /// @param caller Address to authorize
    /// @param authorized Whether to authorize or revoke
    function setAuthorizedCaller(address caller, bool authorized) external onlyOwner {
        authorizedCallers[caller] = authorized;
        emit CallerAuthorized(caller, authorized);
    }

    // ============ Core Functions ============
    
    /// @notice Compound rewards back to pool as liquidity
    /// @param key Pool key
    /// @param rewardToken Address of the reward token
    /// @param rewardAmount Total rewards to compound
    /// @return amount0 Amount added of token0
    /// @return amount1 Amount added of token1
    function compoundRewards(
        PoolKey calldata key,
        address rewardToken,
        uint256 rewardAmount
    ) external onlyAuthorized nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(rewardAmount > 0, "YieldCompound: No rewards");
        
        PoolId poolId = key.toId();
        
        // Get pool tokens
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);
        
        // Transfer rewards to this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), rewardAmount);
        
        // Swap rewards to pool tokens (50/50 split)
        (amount0, amount1) = _swapRewardsToPoolTokens(
            rewardToken,
            token0,
            token1,
            rewardAmount
        );
        
        // Add liquidity to pool
        if (amount0 > 0 && amount1 > 0) {
            _addLiquidity(key, amount0, amount1);
        }
        
        // Update tracking
        totalCompounded[poolId] += rewardAmount;
        
        emit RewardsCompounded(poolId, rewardAmount, amount0, amount1);
    }

    /// @notice Compound rewards when reward token is one of the pool tokens
    /// @param key Pool key
    /// @param rewardAmount Total rewards (in either token0 or token1)
    /// @param isToken0 True if rewards are in token0, false for token1
    /// @return amount0 Amount added of token0
    /// @return amount1 Amount added of token1
    function compoundPoolTokenRewards(
        PoolKey calldata key,
        uint256 rewardAmount,
        bool isToken0
    ) external onlyAuthorized nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(rewardAmount > 0, "YieldCompound: No rewards");
        
        PoolId poolId = key.toId();
        
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);
        address rewardToken = isToken0 ? token0 : token1;
        address otherToken = isToken0 ? token1 : token0;
        
        // Transfer rewards to this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), rewardAmount);
        
        // Swap half to the other token
        uint256 swapAmount = rewardAmount / 2;
        uint256 swappedAmount = _swap(rewardToken, otherToken, swapAmount);
        
        // Set amounts based on which token is the reward
        if (isToken0) {
            amount0 = rewardAmount - swapAmount;
            amount1 = swappedAmount;
        } else {
            amount0 = swappedAmount;
            amount1 = rewardAmount - swapAmount;
        }
        
        // Add liquidity
        if (amount0 > 0 && amount1 > 0) {
            _addLiquidity(key, amount0, amount1);
        }
        
        totalCompounded[poolId] += rewardAmount;
        
        emit RewardsCompounded(poolId, rewardAmount, amount0, amount1);
    }

    // ============ Internal Functions ============
    
    /// @dev Swap rewards to both pool tokens
    function _swapRewardsToPoolTokens(
        address rewardToken,
        address token0,
        address token1,
        uint256 rewardAmount
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint256 halfReward = rewardAmount / 2;
        
        // If reward token is already one of the pool tokens
        if (rewardToken == token0) {
            amount0 = halfReward;
            amount1 = _swap(rewardToken, token1, halfReward);
        } else if (rewardToken == token1) {
            amount0 = _swap(rewardToken, token0, halfReward);
            amount1 = halfReward;
        } else {
            // Swap to both tokens
            amount0 = _swap(rewardToken, token0, halfReward);
            amount1 = _swap(rewardToken, token1, halfReward);
        }
    }

    /// @dev Execute a swap via the swap router
    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        if (amountIn == 0) return 0;
        
        // If tokens are the same, no swap needed
        if (tokenIn == tokenOut) return amountIn;
        
        // Check if swap router is set
        if (address(swapRouter) == address(0)) {
            // No router set - return 0 or revert
            // For hackathon demo, we'll just return 0
            return 0;
        }
        
        // Approve router
        IERC20(tokenIn).safeIncreaseAllowance(address(swapRouter), amountIn);
        
        // Calculate minimum output with slippage
        // For simplicity, assume 1:1 price ratio and apply slippage
        uint256 minAmountOut = (amountIn * (10000 - slippageTolerance)) / 10000;
        
        // Execute swap
        amountOut = swapRouter.swap(tokenIn, tokenOut, amountIn, minAmountOut);
    }

    /// @dev Add liquidity to the pool
    function _addLiquidity(
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1
    ) internal {
        // For Uniswap v4, liquidity is added via PoolManager
        // This requires calling modifyLiquidity through unlock callback
        
        // Simplified for hackathon - in production, would implement
        // proper PoolManager interaction via unlock callback
        
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);
        
        // Approve PoolManager
        if (token0 != address(0)) {
            IERC20(token0).safeIncreaseAllowance(address(poolManager), amount0);
        }
        if (token1 != address(0)) {
            IERC20(token1).safeIncreaseAllowance(address(poolManager), amount1);
        }
        
        // Note: Actual liquidity addition requires unlock callback pattern
        // For demo purposes, this is simplified
    }

    // ============ View Functions ============
    
    /// @notice Get total compounded rewards for a pool
    /// @param poolId Pool ID
    /// @return total Total rewards compounded
    function getTotalCompounded(PoolId poolId) external view returns (uint256 total) {
        return totalCompounded[poolId];
    }

    /// @notice Calculate expected output for compounding
    /// @param rewardToken Reward token address
    /// @param amount Amount of rewards
    /// @return token0Amount Expected token0 amount
    /// @return token1Amount Expected token1 amount
    function previewCompound(
        address rewardToken,
        uint256 amount,
        address token0,
        address token1
    ) external view returns (uint256 token0Amount, uint256 token1Amount) {
        // Simplified preview - assumes 1:1 ratios
        // In production, would use oracle prices
        uint256 half = amount / 2;
        
        if (rewardToken == token0) {
            token0Amount = half;
            token1Amount = half; // Assumed 1:1
        } else if (rewardToken == token1) {
            token0Amount = half; // Assumed 1:1
            token1Amount = half;
        } else {
            token0Amount = half;
            token1Amount = half;
        }
    }

    // ============ Rescue Functions ============
    
    /// @notice Rescue stuck tokens
    /// @param token Token to rescue
    /// @param to Recipient
    /// @param amount Amount to rescue
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "YieldCompound: Invalid recipient");
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Rescue stuck ETH
    /// @param to Recipient
    /// @param amount Amount to rescue
    function rescueETH(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "YieldCompound: Invalid recipient");
        (bool success,) = to.call{value: amount}("");
        require(success, "YieldCompound: ETH transfer failed");
    }

    // ============ Receive ============
    
    receive() external payable {}
}
