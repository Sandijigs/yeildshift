// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseAdapter} from "./BaseAdapter.sol";
import {IMorphoVault} from "../interfaces/external/IMorpho.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {YieldMath} from "../libraries/YieldMath.sol";

/// @title MorphoAdapter
/// @notice Adapter for Morpho Blue ERC-4626 vaults (MetaMorpho)
/// @dev Implements BaseAdapter interface for Morpho integration
contract MorphoAdapter is BaseAdapter {
    using SafeERC20 for IERC20;
    using YieldMath for uint256;

    // ============ State Variables ============
    
    // Track shares per user per vault
    mapping(address => mapping(address => uint256)) public userShares;
    
    // Store historical data for APY calculation
    mapping(address => uint256) public lastExchangeRate;
    mapping(address => uint256) public lastUpdateTime;

    // ============ Constructor ============
    
    constructor() {}

    // ============ External Functions ============
    
    /// @inheritdoc BaseAdapter
    function deposit(
        address vault,
        address token,
        uint256 amount
    ) external override returns (uint256 shares) {
        require(amount > 0, "MorphoAdapter: Zero amount");
        
        IMorphoVault morphoVault = IMorphoVault(vault);
        
        // Verify token matches vault asset
        require(morphoVault.asset() == token, "MorphoAdapter: Token mismatch");
        
        // Transfer tokens from caller
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve Morpho vault
        _safeApprove(token, vault, amount);
        
        // Deposit to Morpho vault
        shares = morphoVault.deposit(amount, address(this));
        
        // Track shares
        userShares[msg.sender][vault] += shares;
        
        // Update exchange rate for APY tracking
        _updateExchangeRate(vault);
        
        emit Deposited(vault, token, amount, shares);
    }

    /// @inheritdoc BaseAdapter
    function withdraw(
        address vault,
        uint256 shares
    ) external override returns (uint256 amount) {
        require(shares > 0, "MorphoAdapter: Zero shares");
        require(userShares[msg.sender][vault] >= shares, "MorphoAdapter: Insufficient shares");
        
        IMorphoVault morphoVault = IMorphoVault(vault);
        
        // Update tracked shares
        userShares[msg.sender][vault] -= shares;
        
        // Redeem shares from Morpho vault
        amount = morphoVault.redeem(shares, msg.sender, address(this));
        
        emit Withdrawn(vault, shares, amount);
    }

    /// @inheritdoc BaseAdapter
    function harvest(address vault) external override returns (uint256 rewards) {
        // Morpho vaults auto-compound, no separate harvest needed
        // Yield is reflected in share price appreciation
        
        // Update exchange rate to track yield
        _updateExchangeRate(vault);
        
        rewards = 0;
        emit RewardHarvested(vault, address(0), rewards);
    }

    /// @inheritdoc BaseAdapter
    function getAPY(address vault) external view override returns (uint256 apy) {
        // Try to get APY from vault if it exposes it
        (bool success, bytes memory data) = vault.staticcall(
            abi.encodeWithSignature("supplyAPY()")
        );
        
        if (success && data.length >= 32) {
            uint256 vaultAPY = abi.decode(data, (uint256));
            // Morpho typically returns APY in WAD (1e18)
            if (vaultAPY > 50000) {
                // If value is in WAD, convert to BPS
                return vaultAPY.wadToBps();
            }
            return vaultAPY;
        }
        
        // Calculate APY from exchange rate change
        return _calculateAPYFromExchangeRate(vault);
    }

    /// @inheritdoc BaseAdapter
    function balanceOf(
        address vault,
        address account
    ) external view override returns (uint256 balance) {
        return userShares[account][vault];
    }

    /// @inheritdoc BaseAdapter
    function getUnderlyingAsset(address vault) external view override returns (address asset) {
        return IMorphoVault(vault).asset();
    }

    // ============ View Functions ============
    
    /// @notice Get current exchange rate (assets per share)
    /// @param vault Morpho vault address
    /// @return rate Exchange rate scaled by 1e18
    function getExchangeRate(address vault) public view returns (uint256 rate) {
        IMorphoVault morphoVault = IMorphoVault(vault);
        uint256 totalSupply = morphoVault.totalSupply();
        
        if (totalSupply == 0) {
            return 1e18; // 1:1 for empty vault
        }
        
        return (morphoVault.totalAssets() * 1e18) / totalSupply;
    }

    /// @notice Get user's share value in underlying assets
    /// @param vault Morpho vault address
    /// @param account User address
    /// @return value Value in underlying assets
    function getUserValue(
        address vault,
        address account
    ) external view returns (uint256 value) {
        uint256 shares = userShares[account][vault];
        if (shares == 0) return 0;
        
        return IMorphoVault(vault).convertToAssets(shares);
    }

    // ============ Internal Functions ============
    
    /// @dev Update stored exchange rate
    function _updateExchangeRate(address vault) internal {
        lastExchangeRate[vault] = getExchangeRate(vault);
        lastUpdateTime[vault] = block.timestamp;
    }

    /// @dev Calculate APY from exchange rate change
    function _calculateAPYFromExchangeRate(address vault) internal view returns (uint256 apy) {
        uint256 currentRate = getExchangeRate(vault);
        uint256 storedRate = lastExchangeRate[vault];
        uint256 storedTime = lastUpdateTime[vault];
        
        // If no historical data, return estimate
        if (storedRate == 0 || storedTime == 0) {
            return 1000; // 10% default estimate
        }
        
        uint256 timeElapsed = block.timestamp - storedTime;
        if (timeElapsed == 0) {
            return 1000; // Return default if no time passed
        }
        
        // Calculate rate growth
        if (currentRate <= storedRate) {
            return 0; // No yield or negative (shouldn't happen)
        }
        
        uint256 rateGrowth = ((currentRate - storedRate) * 1e18) / storedRate;
        
        // Annualize: APY = rateGrowth * (SECONDS_PER_YEAR / timeElapsed) * 10000 / 1e18
        uint256 secondsPerYear = 365 days;
        apy = (rateGrowth * secondsPerYear * 10000) / (timeElapsed * 1e18);
        
        // Sanity check
        if (apy > 50000) apy = 50000; // Cap at 500%
        if (apy < 100) apy = 100; // Floor at 1%
        
        return apy;
    }
}
