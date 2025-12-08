// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseAdapter} from "./BaseAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {YieldMath} from "../libraries/YieldMath.sol";

/// @title ILRT
/// @notice Interface for Liquid Restaking Tokens
interface ILRT {
    function deposit() external payable returns (uint256);
    function withdraw(uint256 amount) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function exchangeRate() external view returns (uint256);
}

/// @title EigenLayerAdapter
/// @notice Adapter for EigenLayer Liquid Restaking Tokens (weETH, ezETH, mETH)
/// @dev Implements BaseAdapter interface for LRT integration
contract EigenLayerAdapter is BaseAdapter {
    using SafeERC20 for IERC20;
    using YieldMath for uint256;

    // ============ State Variables ============
    
    // Supported LRT protocols
    address public weETH;   // Ether.fi
    address public ezETH;   // Renzo
    address public mETH;    // Mantle
    address public weth;    // Wrapped ETH
    
    // Default APY estimates (in basis points)
    // These should be updated regularly via oracle or admin
    mapping(address => uint256) public apyEstimates;
    
    // Track deposits per user per LRT
    mapping(address => mapping(address => uint256)) public userShares;
    
    // Exchange rate tracking for APY calculation
    mapping(address => uint256) public lastExchangeRate;
    mapping(address => uint256) public lastUpdateTime;

    // ============ Events ============
    
    event LRTConfigured(address indexed lrt, uint256 apyEstimate);
    event APYEstimateUpdated(address indexed lrt, uint256 newAPY);

    // ============ Constructor ============
    
    constructor(
        address _weth,
        address _weETH,
        address _ezETH,
        address _mETH
    ) {
        weth = _weth;
        weETH = _weETH;
        ezETH = _ezETH;
        mETH = _mETH;
        
        // Set default APY estimates
        // weETH: ~3.5% staking + ~4% restaking = ~7.5%
        if (_weETH != address(0)) apyEstimates[_weETH] = 750;
        // ezETH: ~3.5% staking + ~5% restaking = ~8.5%
        if (_ezETH != address(0)) apyEstimates[_ezETH] = 850;
        // mETH: ~3.5% staking + ~3% restaking = ~6.5%
        if (_mETH != address(0)) apyEstimates[_mETH] = 650;
    }

    // ============ Admin Functions ============
    
    /// @notice Configure an LRT token
    /// @param lrt LRT token address
    /// @param apyEstimate Initial APY estimate in basis points
    function configureLRT(address lrt, uint256 apyEstimate) external onlyOwner {
        require(lrt != address(0), "EigenLayerAdapter: Invalid LRT");
        require(apyEstimate > 0 && apyEstimate <= 50000, "EigenLayerAdapter: Invalid APY");
        
        apyEstimates[lrt] = apyEstimate;
        emit LRTConfigured(lrt, apyEstimate);
    }

    /// @notice Update APY estimate for an LRT
    /// @param lrt LRT token address
    /// @param newAPY New APY estimate in basis points
    function updateAPYEstimate(address lrt, uint256 newAPY) external onlyOwner {
        require(_isValidLRT(lrt), "EigenLayerAdapter: Invalid LRT");
        require(newAPY > 0 && newAPY <= 50000, "EigenLayerAdapter: Invalid APY");
        
        apyEstimates[lrt] = newAPY;
        emit APYEstimateUpdated(lrt, newAPY);
    }

    // ============ External Functions ============
    
    /// @inheritdoc BaseAdapter
    function deposit(
        address vault,
        address token,
        uint256 amount
    ) external override returns (uint256 shares) {
        require(_isValidLRT(vault), "EigenLayerAdapter: Invalid LRT");
        require(amount > 0, "EigenLayerAdapter: Zero amount");
        
        // For LRTs, we can deposit ETH or WETH
        if (token == weth) {
            // Transfer WETH from caller
            IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
            
            // Unwrap WETH to ETH
            (bool success,) = weth.call(abi.encodeWithSignature("withdraw(uint256)", amount));
            require(success, "EigenLayerAdapter: WETH unwrap failed");
        } else if (token == address(0)) {
            // ETH deposit - already received via msg.value
            require(msg.value == amount, "EigenLayerAdapter: ETH amount mismatch");
        } else {
            revert("EigenLayerAdapter: Invalid token");
        }
        
        // Deposit ETH to get LRT
        shares = _depositToLRT(vault, amount);
        
        // Track shares
        userShares[msg.sender][vault] += shares;
        
        // Update exchange rate tracking
        _updateExchangeRate(vault);
        
        emit Deposited(vault, token, amount, shares);
    }

    /// @inheritdoc BaseAdapter
    function withdraw(
        address vault,
        uint256 shares
    ) external override returns (uint256 amount) {
        require(_isValidLRT(vault), "EigenLayerAdapter: Invalid LRT");
        require(shares > 0, "EigenLayerAdapter: Zero shares");
        require(userShares[msg.sender][vault] >= shares, "EigenLayerAdapter: Insufficient shares");
        
        // Update tracked shares
        userShares[msg.sender][vault] -= shares;
        
        // Withdraw from LRT
        // Note: Most LRTs have withdrawal queues, this is simplified
        amount = _withdrawFromLRT(vault, shares);
        
        // Transfer ETH or WETH to user
        if (amount > 0) {
            // Wrap to WETH and send
            (bool success,) = weth.call{value: amount}(abi.encodeWithSignature("deposit()"));
            require(success, "EigenLayerAdapter: WETH wrap failed");
            IERC20(weth).safeTransfer(msg.sender, amount);
        }
        
        emit Withdrawn(vault, shares, amount);
    }

    /// @inheritdoc BaseAdapter
    function harvest(address vault) external override returns (uint256 rewards) {
        require(_isValidLRT(vault), "EigenLayerAdapter: Invalid LRT");
        
        // LRTs auto-compound restaking rewards into token value
        // Update exchange rate to track yield
        _updateExchangeRate(vault);
        
        rewards = 0;
        emit RewardHarvested(vault, address(0), rewards);
    }

    /// @inheritdoc BaseAdapter
    function getAPY(address vault) external view override returns (uint256 apy) {
        require(_isValidLRT(vault), "EigenLayerAdapter: Invalid LRT");
        
        // Try to calculate from exchange rate change
        uint256 calculatedAPY = _calculateAPYFromExchangeRate(vault);
        
        if (calculatedAPY > 0) {
            return calculatedAPY;
        }
        
        // Fall back to stored estimate
        return apyEstimates[vault];
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
        // LRTs are backed by ETH/WETH
        return weth;
    }

    // ============ View Functions ============
    
    /// @notice Check if an address is a valid LRT
    /// @param lrt Address to check
    /// @return isValid True if valid LRT
    function isValidLRT(address lrt) external view returns (bool isValid) {
        return _isValidLRT(lrt);
    }

    /// @notice Get exchange rate for an LRT
    /// @param lrt LRT address
    /// @return rate Exchange rate (ETH per LRT token)
    function getExchangeRate(address lrt) public view returns (uint256 rate) {
        if (!_isValidLRT(lrt)) return 0;
        
        // Try to get exchange rate from LRT
        (bool success, bytes memory data) = lrt.staticcall(
            abi.encodeWithSignature("exchangeRate()")
        );
        
        if (success && data.length >= 32) {
            return abi.decode(data, (uint256));
        }
        
        // Fallback: calculate from total supply and total ETH
        return 1e18; // 1:1 as default
    }

    /// @notice Get user's share value in ETH
    /// @param lrt LRT address
    /// @param account User address
    /// @return value Value in ETH (wei)
    function getUserValue(
        address lrt,
        address account
    ) external view returns (uint256 value) {
        uint256 shares = userShares[account][lrt];
        if (shares == 0) return 0;
        
        uint256 rate = getExchangeRate(lrt);
        return (shares * rate) / 1e18;
    }

    // ============ Internal Functions ============
    
    function _isValidLRT(address lrt) internal view returns (bool) {
        return lrt == weETH || lrt == ezETH || lrt == mETH || apyEstimates[lrt] > 0;
    }

    function _depositToLRT(address lrt, uint256 amount) internal returns (uint256 shares) {
        // Different LRTs have different deposit interfaces
        // This is a generalized approach
        
        uint256 balanceBefore = IERC20(lrt).balanceOf(address(this));
        
        // Try calling deposit with ETH value
        (bool success,) = lrt.call{value: amount}(abi.encodeWithSignature("deposit()"));
        
        if (!success) {
            // Try alternative method
            (success,) = lrt.call{value: amount}("");
            require(success, "EigenLayerAdapter: Deposit failed");
        }
        
        shares = IERC20(lrt).balanceOf(address(this)) - balanceBefore;
        require(shares > 0, "EigenLayerAdapter: No shares received");
    }

    function _withdrawFromLRT(address lrt, uint256 shares) internal returns (uint256 amount) {
        // Most LRTs have withdrawal queues
        // For simplicity, try direct withdrawal
        
        uint256 ethBefore = address(this).balance;
        
        // Try calling withdraw
        (bool success,) = lrt.call(
            abi.encodeWithSignature("withdraw(uint256)", shares)
        );
        
        if (!success) {
            // Try burn method
            (success,) = lrt.call(
                abi.encodeWithSignature("burn(uint256)", shares)
            );
        }
        
        // Calculate ETH received (may be 0 if queued)
        amount = address(this).balance - ethBefore;
        
        // If no ETH received, the withdrawal is probably queued
        // In production, would need to handle withdrawal queue
    }

    function _updateExchangeRate(address lrt) internal {
        lastExchangeRate[lrt] = getExchangeRate(lrt);
        lastUpdateTime[lrt] = block.timestamp;
    }

    function _calculateAPYFromExchangeRate(address lrt) internal view returns (uint256 apy) {
        uint256 currentRate = getExchangeRate(lrt);
        uint256 storedRate = lastExchangeRate[lrt];
        uint256 storedTime = lastUpdateTime[lrt];
        
        if (storedRate == 0 || storedTime == 0 || currentRate <= storedRate) {
            return 0;
        }
        
        uint256 timeElapsed = block.timestamp - storedTime;
        if (timeElapsed == 0) return 0;
        
        uint256 rateGrowth = ((currentRate - storedRate) * 1e18) / storedRate;
        
        // Annualize
        uint256 secondsPerYear = 365 days;
        apy = (rateGrowth * secondsPerYear * 10000) / (timeElapsed * 1e18);
        
        // Sanity check
        if (apy > 50000) apy = 50000;
        
        return apy;
    }

    // ============ Receive ============
    
    receive() external payable override {}
}
