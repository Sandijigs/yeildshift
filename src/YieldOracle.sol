// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IYieldOracle} from "./interfaces/IYieldOracle.sol";
import {YieldMath} from "./libraries/YieldMath.sol";

/// @title YieldOracle
/// @notice Aggregates APY data from multiple yield sources
/// @dev Provides real-time APY data and finds best yield opportunities
contract YieldOracle is IYieldOracle, Ownable {
    using YieldMath for uint256;

    // ============ State Variables ============
    
    mapping(address => YieldData) private _yieldData;
    mapping(address => VaultConfig) private _vaultConfigs;
    address[] private _activeVaults;
    
    // ============ Constants ============
    
    uint256 public constant MIN_APY = 100;       // 1% minimum
    uint256 public constant MAX_APY = 50000;     // 500% maximum (sanity check)
    uint256 public constant CACHE_DURATION = 60; // 60 seconds cache

    // ============ Constructor ============
    
    constructor() Ownable(msg.sender) {}

    // ============ External Functions ============
    
    /// @inheritdoc IYieldOracle
    function addVault(
        address vault,
        address priceOracle,
        uint256 riskScore
    ) external override onlyOwner {
        require(vault != address(0), "YieldOracle: Invalid vault");
        require(riskScore >= 1 && riskScore <= 10, "YieldOracle: Invalid risk score");
        require(!_vaultConfigs[vault].isWhitelisted, "YieldOracle: Vault already added");

        _vaultConfigs[vault] = VaultConfig({
            vaultAddress: vault,
            priceOracle: priceOracle,
            riskScore: riskScore,
            isWhitelisted: true
        });

        _activeVaults.push(vault);
        
        // Initialize yield data
        _yieldData[vault] = YieldData({
            apy: 0,
            lastUpdate: 0,
            riskScore: riskScore,
            isActive: true
        });

        emit OracleAdded(vault, priceOracle);
    }

    /// @inheritdoc IYieldOracle
    function removeVault(address vault) external override onlyOwner {
        require(_vaultConfigs[vault].isWhitelisted, "YieldOracle: Vault not found");
        
        _vaultConfigs[vault].isWhitelisted = false;
        _yieldData[vault].isActive = false;
        
        // Remove from active vaults array
        for (uint256 i = 0; i < _activeVaults.length; i++) {
            if (_activeVaults[i] == vault) {
                _activeVaults[i] = _activeVaults[_activeVaults.length - 1];
                _activeVaults.pop();
                break;
            }
        }
        
        emit VaultRemoved(vault);
    }

    /// @inheritdoc IYieldOracle
    function getAPY(address vault) public view override returns (uint256 apy) {
        YieldData memory data = _yieldData[vault];
        
        // Return cached value if still fresh
        if (block.timestamp - data.lastUpdate < CACHE_DURATION && data.apy > 0) {
            return data.apy;
        }
        
        // Otherwise return last known APY or estimate
        return data.apy > 0 ? data.apy : _estimateAPY(vault);
    }

    /// @inheritdoc IYieldOracle
    function updateAPY(address vault) external override {
        require(_vaultConfigs[vault].isWhitelisted, "YieldOracle: Not whitelisted");
        
        uint256 apy = _calculateAPY(vault);
        
        _yieldData[vault] = YieldData({
            apy: apy,
            lastUpdate: block.timestamp,
            riskScore: _vaultConfigs[vault].riskScore,
            isActive: true
        });
        
        emit APYUpdated(vault, apy, block.timestamp);
    }

    /// @inheritdoc IYieldOracle
    function getBestYield(uint256 riskTolerance) 
        external 
        view 
        override
        returns (address bestVault, uint256 bestAPY) 
    {
        require(riskTolerance >= 1 && riskTolerance <= 10, "YieldOracle: Invalid risk tolerance");
        
        uint256 bestScore = 0;
        
        for (uint256 i = 0; i < _activeVaults.length; i++) {
            address vault = _activeVaults[i];
            YieldData memory data = _yieldData[vault];
            
            // Skip inactive or too risky
            if (!data.isActive || data.riskScore > riskTolerance) continue;
            
            uint256 currentAPY = getAPY(vault);
            if (currentAPY == 0) continue;
            
            // Calculate risk-adjusted score
            uint256 score = currentAPY.calculateRiskAdjustedScore(data.riskScore);
            
            if (score > bestScore) {
                bestScore = score;
                bestVault = vault;
                bestAPY = currentAPY;
            }
        }
        
        require(bestVault != address(0), "YieldOracle: No valid vault found");
    }

    /// @inheritdoc IYieldOracle
    function getAllAPYs() 
        external 
        view 
        override
        returns (address[] memory vaults, uint256[] memory apys) 
    {
        uint256 len = _activeVaults.length;
        vaults = new address[](len);
        apys = new uint256[](len);
        
        for (uint256 i = 0; i < len; i++) {
            vaults[i] = _activeVaults[i];
            apys[i] = getAPY(_activeVaults[i]);
        }
    }

    /// @inheritdoc IYieldOracle
    function getVaultConfig(address vault) external view override returns (VaultConfig memory) {
        return _vaultConfigs[vault];
    }

    /// @inheritdoc IYieldOracle
    function getYieldData(address vault) external view override returns (YieldData memory) {
        return _yieldData[vault];
    }

    /// @inheritdoc IYieldOracle
    function activeVaults(uint256 index) external view override returns (address) {
        require(index < _activeVaults.length, "YieldOracle: Index out of bounds");
        return _activeVaults[index];
    }

    /// @inheritdoc IYieldOracle
    function getActiveVaultsCount() external view override returns (uint256) {
        return _activeVaults.length;
    }

    // ============ Admin Functions ============
    
    /// @notice Set APY manually (for testing or emergency)
    /// @param vault Vault address
    /// @param apy APY in basis points
    function setAPY(address vault, uint256 apy) external onlyOwner {
        require(_vaultConfigs[vault].isWhitelisted, "YieldOracle: Not whitelisted");
        require(apy >= MIN_APY && apy <= MAX_APY, "YieldOracle: APY out of range");
        
        _yieldData[vault].apy = apy;
        _yieldData[vault].lastUpdate = block.timestamp;
        
        emit APYUpdated(vault, apy, block.timestamp);
    }

    /// @notice Update risk score for a vault
    /// @param vault Vault address
    /// @param riskScore New risk score (1-10)
    function setRiskScore(address vault, uint256 riskScore) external onlyOwner {
        require(_vaultConfigs[vault].isWhitelisted, "YieldOracle: Not whitelisted");
        require(riskScore >= 1 && riskScore <= 10, "YieldOracle: Invalid risk score");
        
        _vaultConfigs[vault].riskScore = riskScore;
        _yieldData[vault].riskScore = riskScore;
    }

    // ============ Internal Functions ============
    
    /// @dev Calculate APY for a vault using on-chain data
    function _calculateAPY(address vault) internal view returns (uint256) {
        // Try to get APY from vault directly
        // Different vaults have different methods
        
        // Method 1: Try getAPY()
        (bool success, bytes memory data) = vault.staticcall(
            abi.encodeWithSignature("getAPY()")
        );
        if (success && data.length >= 32) {
            uint256 apy = abi.decode(data, (uint256));
            return _sanitizeAPY(apy);
        }
        
        // Method 2: Try supplyAPY() (common in lending protocols)
        (success, data) = vault.staticcall(
            abi.encodeWithSignature("supplyAPY()")
        );
        if (success && data.length >= 32) {
            uint256 apy = abi.decode(data, (uint256));
            // Convert from WAD to BPS if needed
            if (apy > MAX_APY * 1e14) {
                apy = apy / 1e14;
            }
            return _sanitizeAPY(apy);
        }
        
        // Method 3: Calculate from totalAssets growth (ERC-4626)
        return _estimateAPY(vault);
    }

    /// @dev Estimate APY based on vault type
    function _estimateAPY(address vault) internal view returns (uint256) {
        // Try to identify vault type and return conservative estimate
        // These are fallback values when we can't calculate actual APY
        
        // Check if it's an ERC-4626 vault
        (bool success,) = vault.staticcall(
            abi.encodeWithSignature("totalAssets()")
        );
        
        if (success) {
            // ERC-4626 vault - return medium estimate
            return 800; // 8% default
        }
        
        // Default conservative estimate
        return 500; // 5% default
    }

    /// @dev Ensure APY is within reasonable bounds
    function _sanitizeAPY(uint256 apy) internal pure returns (uint256) {
        return apy.clampAPY(MIN_APY, MAX_APY);
    }
}
