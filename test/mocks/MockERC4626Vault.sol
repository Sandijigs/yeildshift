// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title MockERC4626Vault
/// @notice Mock ERC-4626 vault for testing YieldShift
contract MockERC4626Vault is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    uint256 public apy; // APY in basis points
    uint256 public lastHarvestTime;
    
    // Simulate yield accrual
    uint256 public totalAssetsStored;

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        uint256 _apy
    ) ERC20(_name, _symbol) {
        asset = IERC20(_asset);
        apy = _apy;
        lastHarvestTime = block.timestamp;
    }

    // ============ ERC-4626 Functions ============

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        require(assets > 0, "MockVault: Zero assets");
        
        // Transfer assets
        asset.safeTransferFrom(msg.sender, address(this), assets);
        
        // Calculate shares (1:1 for simplicity)
        shares = assets;
        
        // Mint shares
        _mint(receiver, shares);
        
        // Update total assets
        totalAssetsStored += assets;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares) {
        shares = assets; // 1:1
        
        // Check balance
        require(balanceOf(owner) >= shares, "MockVault: Insufficient balance");
        
        // Burn shares
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        
        // Transfer assets
        asset.safeTransfer(receiver, assets);
        
        // Update total assets
        if (totalAssetsStored >= assets) {
            totalAssetsStored -= assets;
        }
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets) {
        require(balanceOf(owner) >= shares, "MockVault: Insufficient balance");
        
        // Calculate assets (include accrued yield)
        assets = convertToAssets(shares);
        
        // Burn shares
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        
        // Transfer assets
        asset.safeTransfer(receiver, assets);
        
        // Update total assets
        if (totalAssetsStored >= assets) {
            totalAssetsStored -= assets;
        }
    }

    // ============ View Functions ============

    function totalAssets() public view returns (uint256) {
        // Simulate yield accrual
        uint256 timeElapsed = block.timestamp - lastHarvestTime;
        uint256 yieldAccrued = (totalAssetsStored * apy * timeElapsed) / (365 days * 10000);
        return totalAssetsStored + yieldAccrued;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return assets;
        return (assets * supply) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) return shares;
        return (shares * totalAssets()) / supply;
    }

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }

    // ============ APY Functions ============

    function getAPY() external view returns (uint256) {
        return apy;
    }

    function supplyAPY() external view returns (uint256) {
        // Return in WAD format (1e18)
        return apy * 1e14;
    }

    function setAPY(uint256 _apy) external {
        apy = _apy;
    }

    // ============ Harvest Simulation ============

    function harvest() external returns (uint256 rewards) {
        // Calculate accrued yield
        uint256 timeElapsed = block.timestamp - lastHarvestTime;
        rewards = (totalAssetsStored * apy * timeElapsed) / (365 days * 10000);
        
        // Add yield to total assets
        totalAssetsStored += rewards;
        lastHarvestTime = block.timestamp;
    }

    // ============ Admin ============

    function addYield(uint256 amount) external {
        // Directly add yield for testing
        asset.safeTransferFrom(msg.sender, address(this), amount);
        totalAssetsStored += amount;
    }
}
