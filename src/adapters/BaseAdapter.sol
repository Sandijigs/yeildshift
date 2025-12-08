// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title BaseAdapter
/// @notice Abstract base contract for all yield source adapters
/// @dev All adapters must inherit from this and implement the virtual functions
abstract contract BaseAdapter is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Events ============
    
    event Deposited(address indexed vault, address indexed token, uint256 amount, uint256 shares);
    event Withdrawn(address indexed vault, uint256 shares, uint256 amount);
    event RewardHarvested(address indexed vault, address indexed rewardToken, uint256 amount);

    // ============ State Variables ============
    
    address public immutable owner;
    bool public paused;

    // ============ Modifiers ============
    
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseAdapter: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "BaseAdapter: Paused");
        _;
    }

    // ============ Constructor ============
    
    constructor() {
        owner = msg.sender;
    }

    // ============ External Functions ============
    
    /// @notice Deposit assets into yield source
    /// @param vault Address of the vault/protocol
    /// @param token Address of the token to deposit
    /// @param amount Amount to deposit
    /// @return shares Shares/tokens received
    function deposit(
        address vault,
        address token,
        uint256 amount
    ) external virtual nonReentrant whenNotPaused returns (uint256 shares);

    /// @notice Withdraw assets from yield source
    /// @param vault Address of the vault/protocol
    /// @param shares Shares to redeem
    /// @return amount Assets received
    function withdraw(
        address vault,
        uint256 shares
    ) external virtual nonReentrant whenNotPaused returns (uint256 amount);

    /// @notice Harvest pending rewards
    /// @param vault Address of the vault/protocol
    /// @return rewards Amount of rewards harvested
    function harvest(
        address vault
    ) external virtual nonReentrant whenNotPaused returns (uint256 rewards);

    /// @notice Get current APY
    /// @param vault Address of the vault/protocol
    /// @return apy APY in basis points (10000 = 100%)
    function getAPY(
        address vault
    ) external view virtual returns (uint256 apy);

    /// @notice Get balance of shares/position
    /// @param vault Address of the vault/protocol
    /// @param account Account to check
    /// @return balance Share/position balance
    function balanceOf(
        address vault,
        address account
    ) external view virtual returns (uint256 balance);

    /// @notice Get the underlying asset for a vault
    /// @param vault Address of the vault/protocol
    /// @return asset Address of the underlying asset
    function getUnderlyingAsset(
        address vault
    ) external view virtual returns (address asset);

    // ============ Admin Functions ============
    
    /// @notice Pause the adapter
    function pause() external onlyOwner {
        paused = true;
    }

    /// @notice Unpause the adapter
    function unpause() external onlyOwner {
        paused = false;
    }

    /// @notice Emergency rescue tokens stuck in contract
    /// @param token Token to rescue
    /// @param to Recipient address
    /// @param amount Amount to rescue
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "BaseAdapter: Invalid recipient");
        IERC20(token).safeTransfer(to, amount);
    }

    // ============ Internal Functions ============
    
    /// @dev Safe approval with reset for tokens that require it
    function _safeApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20 tokenContract = IERC20(token);
        
        // Reset approval if needed (for USDT-like tokens)
        uint256 currentAllowance = tokenContract.allowance(address(this), spender);
        if (currentAllowance > 0) {
            tokenContract.safeDecreaseAllowance(spender, currentAllowance);
        }
        
        if (amount > 0) {
            tokenContract.safeIncreaseAllowance(spender, amount);
        }
    }

    // ============ Receive ============
    
    /// @notice Allow receiving ETH
    receive() external payable {}
}
