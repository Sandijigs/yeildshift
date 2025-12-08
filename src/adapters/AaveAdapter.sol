// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseAdapter} from "./BaseAdapter.sol";
import {IAavePool} from "../interfaces/external/IAavePool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {YieldMath} from "../libraries/YieldMath.sol";

/// @title AaveAdapter
/// @notice Adapter for Aave v3 lending protocol
/// @dev Implements BaseAdapter interface for Aave v3 integration
contract AaveAdapter is BaseAdapter {
    using SafeERC20 for IERC20;
    using YieldMath for uint256;

    // ============ State Variables ============
    
    IAavePool public immutable aavePool;
    
    // Track deposits per user per asset
    mapping(address => mapping(address => uint256)) public userDeposits;

    // ============ Constructor ============
    
    constructor(address _aavePool) {
        require(_aavePool != address(0), "AaveAdapter: Invalid pool");
        aavePool = IAavePool(_aavePool);
    }

    // ============ External Functions ============
    
    /// @inheritdoc BaseAdapter
    function deposit(
        address vault,
        address token,
        uint256 amount
    ) external override returns (uint256 shares) {
        require(amount > 0, "AaveAdapter: Zero amount");
        
        // Transfer tokens from caller
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve Aave pool
        _safeApprove(token, address(aavePool), amount);
        
        // Get aToken balance before
        IAavePool.ReserveData memory reserveData = aavePool.getReserveData(token);
        address aToken = reserveData.aTokenAddress;
        uint256 balanceBefore = IERC20(aToken).balanceOf(address(this));
        
        // Supply to Aave
        aavePool.supply(token, amount, address(this), 0);
        
        // Calculate shares received (aTokens are 1:1 with underlying)
        shares = IERC20(aToken).balanceOf(address(this)) - balanceBefore;
        
        // Track deposit
        userDeposits[msg.sender][token] += shares;
        
        emit Deposited(vault, token, amount, shares);
    }

    /// @inheritdoc BaseAdapter
    function withdraw(
        address vault,
        uint256 shares
    ) external override returns (uint256 amount) {
        // For Aave, vault param is the asset address
        address asset = vault;
        
        require(shares > 0, "AaveAdapter: Zero shares");
        require(userDeposits[msg.sender][asset] >= shares, "AaveAdapter: Insufficient balance");
        
        // Update tracked deposits
        userDeposits[msg.sender][asset] -= shares;
        
        // Withdraw from Aave (aTokens are burned automatically)
        amount = aavePool.withdraw(asset, shares, msg.sender);
        
        emit Withdrawn(vault, shares, amount);
    }

    /// @inheritdoc BaseAdapter
    function harvest(address vault) external override returns (uint256 rewards) {
        // Aave v3 doesn't have separate rewards to harvest in base implementation
        // Yield accrues directly to aToken balance
        // For safety rewards (e.g., stkAAVE), would need separate integration
        
        rewards = 0;
        emit RewardHarvested(vault, address(0), rewards);
    }

    /// @inheritdoc BaseAdapter
    function getAPY(address vault) external view override returns (uint256 apy) {
        // vault param is the asset address for Aave
        IAavePool.ReserveData memory reserveData = aavePool.getReserveData(vault);
        
        // currentLiquidityRate is in RAY (1e27) and represents the supply APY
        // Convert from RAY to basis points
        apy = reserveData.currentLiquidityRate.rayToBps();
    }

    /// @inheritdoc BaseAdapter
    function balanceOf(
        address vault,
        address account
    ) external view override returns (uint256 balance) {
        // vault param is the asset address
        IAavePool.ReserveData memory reserveData = aavePool.getReserveData(vault);
        address aToken = reserveData.aTokenAddress;
        
        // For this adapter, return tracked deposits for the account
        // In production, you'd track per-user aToken balances
        return userDeposits[account][vault];
    }

    /// @inheritdoc BaseAdapter
    function getUnderlyingAsset(address vault) external pure override returns (address asset) {
        // For Aave, the vault IS the asset
        return vault;
    }

    // ============ View Functions ============
    
    /// @notice Get aToken address for an asset
    /// @param asset The underlying asset
    /// @return aToken The aToken address
    function getAToken(address asset) external view returns (address aToken) {
        IAavePool.ReserveData memory reserveData = aavePool.getReserveData(asset);
        return reserveData.aTokenAddress;
    }

    /// @notice Get current supply rate
    /// @param asset The underlying asset
    /// @return rate The current liquidity rate in RAY
    function getCurrentRate(address asset) external view returns (uint128 rate) {
        IAavePool.ReserveData memory reserveData = aavePool.getReserveData(asset);
        return reserveData.currentLiquidityRate;
    }
}
