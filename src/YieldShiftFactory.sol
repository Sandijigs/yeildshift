// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

import {YieldShiftHook} from "./YieldShiftHook.sol";
import {IYieldShiftHook} from "./interfaces/IYieldShiftHook.sol";

/// @title YieldShiftFactory
/// @notice Factory for deploying YieldShift-enabled pools
/// @dev Simplifies creation of pools with YieldShiftHook attached
contract YieldShiftFactory is Ownable {
    using PoolIdLibrary for PoolKey;

    // ============ State Variables ============
    
    IPoolManager public immutable poolManager;
    YieldShiftHook public immutable yieldShiftHook;
    
    // Track deployed pools
    PoolId[] public deployedPools;
    mapping(PoolId => PoolKey) public poolKeys;
    mapping(PoolId => bool) public isDeployed;

    // Default configuration
    IYieldShiftHook.YieldConfig public defaultConfig;

    // ============ Events ============
    
    event PoolDeployed(
        PoolId indexed poolId,
        address indexed currency0,
        address indexed currency1,
        uint24 fee,
        int24 tickSpacing
    );
    event DefaultConfigUpdated(
        uint8 shiftPercentage,
        uint16 minAPYThreshold,
        uint8 riskTolerance
    );

    // ============ Constructor ============
    
    constructor(
        address _poolManager, 
        address _yieldShiftHook
    ) Ownable(msg.sender) {
        require(_poolManager != address(0), "Factory: Invalid pool manager");
        require(_yieldShiftHook != address(0), "Factory: Invalid hook");
        
        poolManager = IPoolManager(_poolManager);
        yieldShiftHook = YieldShiftHook(payable(_yieldShiftHook));
        
        // Set default configuration
        defaultConfig = IYieldShiftHook.YieldConfig({
            shiftPercentage: 30,      // 30% of idle capital
            minAPYThreshold: 500,     // 5% minimum APY
            harvestFrequency: 10,     // Harvest every 10 swaps
            riskTolerance: 7,         // Accept up to medium-high risk
            isPaused: false,
            admin: msg.sender
        });
    }

    // ============ Admin Functions ============
    
    /// @notice Update default configuration
    /// @param config New default configuration
    function setDefaultConfig(
        IYieldShiftHook.YieldConfig memory config
    ) external onlyOwner {
        require(config.shiftPercentage >= 10 && config.shiftPercentage <= 50, "Factory: Invalid shift %");
        require(config.minAPYThreshold >= 200, "Factory: Invalid min APY");
        require(config.riskTolerance >= 1 && config.riskTolerance <= 10, "Factory: Invalid risk");
        
        defaultConfig = config;
        
        emit DefaultConfigUpdated(
            config.shiftPercentage,
            config.minAPYThreshold,
            config.riskTolerance
        );
    }

    // ============ Pool Deployment ============
    
    /// @notice Deploy a new YieldShift-enabled pool with default config
    /// @param currency0 First currency
    /// @param currency1 Second currency
    /// @param fee Pool fee (in hundredths of a bip)
    /// @param tickSpacing Tick spacing
    /// @param sqrtPriceX96 Initial sqrt price
    /// @return poolId The deployed pool ID
    function deployPool(
        Currency currency0,
        Currency currency1,
        uint24 fee,
        int24 tickSpacing,
        uint160 sqrtPriceX96
    ) external returns (PoolId poolId) {
        IYieldShiftHook.YieldConfig memory config = defaultConfig;
        config.admin = msg.sender;
        
        return _deployPool(
            currency0,
            currency1,
            fee,
            tickSpacing,
            sqrtPriceX96,
            config
        );
    }

    /// @notice Deploy a new YieldShift-enabled pool with custom config
    /// @param currency0 First currency
    /// @param currency1 Second currency
    /// @param fee Pool fee
    /// @param tickSpacing Tick spacing
    /// @param sqrtPriceX96 Initial sqrt price
    /// @param config Custom yield configuration
    /// @return poolId The deployed pool ID
    function deployPoolWithConfig(
        Currency currency0,
        Currency currency1,
        uint24 fee,
        int24 tickSpacing,
        uint160 sqrtPriceX96,
        IYieldShiftHook.YieldConfig memory config
    ) external returns (PoolId poolId) {
        return _deployPool(
            currency0,
            currency1,
            fee,
            tickSpacing,
            sqrtPriceX96,
            config
        );
    }

    // ============ View Functions ============
    
    /// @notice Get all deployed pools
    /// @return pools Array of pool IDs
    function getDeployedPools() external view returns (PoolId[] memory pools) {
        return deployedPools;
    }

    /// @notice Get number of deployed pools
    /// @return count Number of pools
    function getPoolCount() external view returns (uint256 count) {
        return deployedPools.length;
    }

    /// @notice Get pool key for a pool ID
    /// @param poolId Pool ID
    /// @return key Pool key
    function getPoolKey(PoolId poolId) external view returns (PoolKey memory key) {
        require(isDeployed[poolId], "Factory: Pool not deployed");
        return poolKeys[poolId];
    }

    /// @notice Check if a pool was deployed by this factory
    /// @param poolId Pool ID to check
    /// @return deployed True if deployed by this factory
    function isPoolDeployed(PoolId poolId) external view returns (bool deployed) {
        return isDeployed[poolId];
    }

    // ============ Internal Functions ============
    
    function _deployPool(
        Currency currency0,
        Currency currency1,
        uint24 fee,
        int24 tickSpacing,
        uint160 sqrtPriceX96,
        IYieldShiftHook.YieldConfig memory config
    ) internal returns (PoolId poolId) {
        // Ensure currencies are in correct order
        require(
            Currency.unwrap(currency0) < Currency.unwrap(currency1),
            "Factory: Currencies not sorted"
        );
        
        // Create pool key
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: IHooks(address(yieldShiftHook))
        });
        
        poolId = key.toId();
        
        // Check not already deployed
        require(!isDeployed[poolId], "Factory: Already deployed");
        
        // Initialize pool via PoolManager
        poolManager.initialize(key, sqrtPriceX96);
        
        // Configure YieldShift hook for this pool
        yieldShiftHook.configurePool(key, config);
        
        // Track deployment
        deployedPools.push(poolId);
        poolKeys[poolId] = key;
        isDeployed[poolId] = true;
        
        emit PoolDeployed(
            poolId,
            Currency.unwrap(currency0),
            Currency.unwrap(currency1),
            fee,
            tickSpacing
        );
    }
}
