// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseAdapter} from "./BaseAdapter.sol";
import {IComet, ICometRewards} from "../interfaces/external/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {YieldMath} from "../libraries/YieldMath.sol";

/// @title CompoundAdapter
/// @notice Adapter for Compound v3 (Comet) protocol
/// @dev Implements BaseAdapter interface for Compound v3 integration
contract CompoundAdapter is BaseAdapter {
    using SafeERC20 for IERC20;
    using YieldMath for uint256;

    // ============ State Variables ============
    
    // Rewards contract (optional, may not be deployed on all chains)
    ICometRewards public cometRewards;
    
    // Track deposits per user per comet market
    mapping(address => mapping(address => uint256)) public userDeposits;

    // ============ Constructor ============
    
    constructor() {}

    // ============ Admin Functions ============
    
    /// @notice Set the rewards contract address
    /// @param _cometRewards Address of CometRewards contract
    function setCometRewards(address _cometRewards) external onlyOwner {
        cometRewards = ICometRewards(_cometRewards);
    }

    // ============ External Functions ============
    
    /// @inheritdoc BaseAdapter
    function deposit(
        address vault,
        address token,
        uint256 amount
    ) external override returns (uint256 shares) {
        require(amount > 0, "CompoundAdapter: Zero amount");
        
        IComet comet = IComet(vault);
        
        // Verify token matches comet base token
        require(comet.baseToken() == token, "CompoundAdapter: Token mismatch");
        
        // Transfer tokens from caller
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve Comet
        _safeApprove(token, vault, amount);
        
        // Get balance before
        uint256 balanceBefore = comet.balanceOf(address(this));
        
        // Supply to Compound
        comet.supply(token, amount);
        
        // Calculate shares (Compound v3 is 1:1 for base asset)
        shares = comet.balanceOf(address(this)) - balanceBefore;
        
        // Track deposit
        userDeposits[msg.sender][vault] += shares;
        
        emit Deposited(vault, token, amount, shares);
    }

    /// @inheritdoc BaseAdapter
    function withdraw(
        address vault,
        uint256 shares
    ) external override returns (uint256 amount) {
        require(shares > 0, "CompoundAdapter: Zero shares");
        require(userDeposits[msg.sender][vault] >= shares, "CompoundAdapter: Insufficient balance");
        
        IComet comet = IComet(vault);
        address baseToken = comet.baseToken();
        
        // Update tracked deposits
        userDeposits[msg.sender][vault] -= shares;
        
        // Get balance before
        uint256 balanceBefore = IERC20(baseToken).balanceOf(address(this));
        
        // Withdraw from Compound
        comet.withdraw(baseToken, shares);
        
        // Calculate actual amount received
        amount = IERC20(baseToken).balanceOf(address(this)) - balanceBefore;
        
        // Transfer to user
        IERC20(baseToken).safeTransfer(msg.sender, amount);
        
        emit Withdrawn(vault, shares, amount);
    }

    /// @inheritdoc BaseAdapter
    function harvest(address vault) external override returns (uint256 rewards) {
        // Check if rewards contract is set
        if (address(cometRewards) == address(0)) {
            emit RewardHarvested(vault, address(0), 0);
            return 0;
        }
        
        // Try to claim rewards
        try cometRewards.claim(vault, address(this), true) {
            // Get reward token info
            ICometRewards.RewardConfig memory config = cometRewards.getRewardOwed(vault, address(this));
            
            if (config.token != address(0)) {
                rewards = IERC20(config.token).balanceOf(address(this));
                emit RewardHarvested(vault, config.token, rewards);
            }
        } catch {
            rewards = 0;
            emit RewardHarvested(vault, address(0), 0);
        }
    }

    /// @inheritdoc BaseAdapter
    function getAPY(address vault) external view override returns (uint256 apy) {
        IComet comet = IComet(vault);
        
        // Get current utilization
        uint256 utilization = comet.getUtilization();
        
        // Get supply rate at current utilization
        uint64 supplyRate = comet.getSupplyRate(utilization);
        
        // Convert from per-second rate to annual APY
        // Compound v3 rates are in 1e18 precision per second
        apy = uint256(supplyRate).rateToAPY();
    }

    /// @inheritdoc BaseAdapter
    function balanceOf(
        address vault,
        address account
    ) external view override returns (uint256 balance) {
        return userDeposits[account][vault];
    }

    /// @inheritdoc BaseAdapter
    function getUnderlyingAsset(address vault) external view override returns (address asset) {
        return IComet(vault).baseToken();
    }

    // ============ View Functions ============
    
    /// @notice Get current utilization of a Comet market
    /// @param vault Comet address
    /// @return utilization Current utilization scaled by 1e18
    function getUtilization(address vault) external view returns (uint256 utilization) {
        return IComet(vault).getUtilization();
    }

    /// @notice Get current supply rate
    /// @param vault Comet address
    /// @return rate Supply rate per second in 1e18
    function getSupplyRate(address vault) external view returns (uint64 rate) {
        uint256 utilization = IComet(vault).getUtilization();
        return IComet(vault).getSupplyRate(utilization);
    }

    /// @notice Get current borrow rate
    /// @param vault Comet address
    /// @return rate Borrow rate per second in 1e18
    function getBorrowRate(address vault) external view returns (uint64 rate) {
        uint256 utilization = IComet(vault).getUtilization();
        return IComet(vault).getBorrowRate(utilization);
    }

    /// @notice Get user's actual balance including accrued interest
    /// @param vault Comet address
    /// @param account User address
    /// @return balance Current balance with interest
    function getActualBalance(
        address vault,
        address account
    ) external view returns (uint256 balance) {
        // This returns the actual balance in Comet
        return IComet(vault).balanceOf(account);
    }
}
