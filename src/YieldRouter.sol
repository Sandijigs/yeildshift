// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IYieldRouter} from "./interfaces/IYieldRouter.sol";
import {BaseAdapter} from "./adapters/BaseAdapter.sol";

/// @title YieldRouter
/// @notice Routes capital to yield sources via adapters
/// @dev Central hub for managing deposits/withdrawals across yield protocols
contract YieldRouter is IYieldRouter, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State Variables ============
    
    // vault => adapter mapping
    mapping(address => address) private _vaultAdapters;
    
    // Track total deposits per vault
    mapping(address => uint256) public totalDeposited;
    
    // Track total harvested rewards per vault
    mapping(address => uint256) public totalHarvested;
    
    // Authorized callers (e.g., YieldShiftHook)
    mapping(address => bool) public authorizedCallers;
    
    // All registered vaults
    address[] public registeredVaults;

    // ============ Events ============
    
    event CallerAuthorized(address indexed caller, bool authorized);
    event EmergencyWithdraw(address indexed vault, uint256 amount);

    // ============ Modifiers ============
    
    modifier onlyAuthorized() {
        require(
            authorizedCallers[msg.sender] || msg.sender == owner(),
            "YieldRouter: Not authorized"
        );
        _;
    }

    // ============ Constructor ============
    
    constructor() Ownable(msg.sender) {}

    // ============ Admin Functions ============
    
    /// @notice Authorize a caller (e.g., YieldShiftHook)
    /// @param caller Address to authorize
    /// @param authorized Whether to authorize or revoke
    function setAuthorizedCaller(address caller, bool authorized) external onlyOwner {
        authorizedCallers[caller] = authorized;
        emit CallerAuthorized(caller, authorized);
    }

    /// @inheritdoc IYieldRouter
    function registerAdapter(address vault, address adapter) external override onlyOwner {
        require(vault != address(0), "YieldRouter: Invalid vault");
        require(adapter != address(0), "YieldRouter: Invalid adapter");
        require(_vaultAdapters[vault] == address(0), "YieldRouter: Already registered");
        
        _vaultAdapters[vault] = adapter;
        registeredVaults.push(vault);
        
        emit AdapterRegistered(vault, adapter);
    }

    /// @notice Update adapter for a vault
    /// @param vault Vault address
    /// @param newAdapter New adapter address
    function updateAdapter(address vault, address newAdapter) external onlyOwner {
        require(_vaultAdapters[vault] != address(0), "YieldRouter: Not registered");
        require(newAdapter != address(0), "YieldRouter: Invalid adapter");
        
        _vaultAdapters[vault] = newAdapter;
        emit AdapterRegistered(vault, newAdapter);
    }

    // ============ Core Functions ============
    
    /// @inheritdoc IYieldRouter
    function shiftToVault(
        address vault,
        address token,
        uint256 amount
    ) external override onlyAuthorized nonReentrant returns (uint256 shares) {
        require(amount > 0, "YieldRouter: Zero amount");
        
        address adapter = _vaultAdapters[vault];
        require(adapter != address(0), "YieldRouter: No adapter");
        
        // Transfer tokens to router (caller must have approved)
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve adapter
        IERC20(token).safeIncreaseAllowance(adapter, amount);
        
        // Deposit via adapter
        shares = BaseAdapter(adapter).deposit(vault, token, amount);
        
        // Track deposit
        totalDeposited[vault] += amount;
        
        emit VaultDeposit(vault, amount, shares);
    }

    /// @inheritdoc IYieldRouter
    function withdrawFromVault(
        address vault,
        uint256 shares
    ) external override onlyAuthorized nonReentrant returns (uint256 amount) {
        require(shares > 0, "YieldRouter: Zero shares");
        
        address adapter = _vaultAdapters[vault];
        require(adapter != address(0), "YieldRouter: No adapter");
        
        // Withdraw via adapter
        amount = BaseAdapter(adapter).withdraw(vault, shares);
        
        // Update tracked deposits
        if (totalDeposited[vault] >= amount) {
            totalDeposited[vault] -= amount;
        } else {
            totalDeposited[vault] = 0;
        }
        
        emit VaultWithdraw(vault, shares, amount);
    }

    /// @inheritdoc IYieldRouter
    function harvest(address vault) external override onlyAuthorized nonReentrant returns (uint256 rewards) {
        address adapter = _vaultAdapters[vault];
        require(adapter != address(0), "YieldRouter: No adapter");
        
        // Harvest via adapter
        rewards = BaseAdapter(adapter).harvest(vault);
        
        // Track harvested rewards
        totalHarvested[vault] += rewards;
        
        emit Harvested(vault, rewards);
    }

    /// @notice Harvest from multiple vaults
    /// @param vaults Array of vault addresses
    /// @return totalRewards Total rewards harvested
    function harvestMultiple(
        address[] calldata vaults
    ) external onlyAuthorized nonReentrant returns (uint256 totalRewards) {
        for (uint256 i = 0; i < vaults.length; i++) {
            address adapter = _vaultAdapters[vaults[i]];
            if (adapter != address(0)) {
                uint256 rewards = BaseAdapter(adapter).harvest(vaults[i]);
                totalHarvested[vaults[i]] += rewards;
                totalRewards += rewards;
                emit Harvested(vaults[i], rewards);
            }
        }
    }

    // ============ Emergency Functions ============
    
    /// @notice Emergency withdraw all from a vault
    /// @param vault Vault address
    /// @return amount Amount withdrawn
    function emergencyWithdrawAll(address vault) external onlyOwner returns (uint256 amount) {
        address adapter = _vaultAdapters[vault];
        require(adapter != address(0), "YieldRouter: No adapter");
        
        // Get total balance
        uint256 balance = BaseAdapter(adapter).balanceOf(vault, address(this));
        if (balance == 0) return 0;
        
        // Withdraw all
        amount = BaseAdapter(adapter).withdraw(vault, balance);
        
        totalDeposited[vault] = 0;
        
        emit EmergencyWithdraw(vault, amount);
    }

    /// @notice Rescue stuck tokens
    /// @param token Token address
    /// @param to Recipient
    /// @param amount Amount to rescue
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "YieldRouter: Invalid recipient");
        IERC20(token).safeTransfer(to, amount);
    }

    // ============ View Functions ============
    
    /// @inheritdoc IYieldRouter
    function vaultAdapters(address vault) external view override returns (address) {
        return _vaultAdapters[vault];
    }

    /// @inheritdoc IYieldRouter
    function getBalance(
        address vault,
        address account
    ) external view override returns (uint256) {
        address adapter = _vaultAdapters[vault];
        if (adapter == address(0)) return 0;
        
        return BaseAdapter(adapter).balanceOf(vault, account);
    }

    /// @notice Get APY for a vault
    /// @param vault Vault address
    /// @return apy APY in basis points
    function getAPY(address vault) external view returns (uint256 apy) {
        address adapter = _vaultAdapters[vault];
        if (adapter == address(0)) return 0;
        
        return BaseAdapter(adapter).getAPY(vault);
    }

    /// @notice Get all registered vaults
    /// @return vaults Array of vault addresses
    function getAllVaults() external view returns (address[] memory vaults) {
        return registeredVaults;
    }

    /// @notice Get number of registered vaults
    /// @return count Number of vaults
    function getVaultCount() external view returns (uint256 count) {
        return registeredVaults.length;
    }

    /// @notice Check if adapter is registered for vault
    /// @param vault Vault address
    /// @return registered True if adapter exists
    function isRegistered(address vault) external view returns (bool registered) {
        return _vaultAdapters[vault] != address(0);
    }
}
