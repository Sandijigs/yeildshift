// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IYieldOracle} from "./interfaces/IYieldOracle.sol";
import {IYieldRouter} from "./interfaces/IYieldRouter.sol";
import {IYieldShiftHook} from "./interfaces/IYieldShiftHook.sol";
import {YieldCompound} from "./YieldCompound.sol";
import {YieldMath} from "./libraries/YieldMath.sol";

/// @title YieldShiftHook
/// @notice Uniswap v4 hook that automatically optimizes yield for LPs
/// @dev Routes idle liquidity to best yield sources and auto-compounds rewards
contract YieldShiftHook is IHooks, IYieldShiftHook, ReentrancyGuard {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;
    using YieldMath for uint256;

    // ============ State Variables ============

    IPoolManager public immutable poolManager;
    IYieldOracle public immutable yieldOracle;
    IYieldRouter public immutable yieldRouter;
    YieldCompound public immutable yieldCompound;
    
    // Pool configurations
    mapping(PoolId => YieldConfig) private _poolConfigs;
    
    // Pool state tracking
    struct PoolState {
        uint256 totalShifted;
        uint256 totalHarvested;
        uint256 swapCount;
        uint256 lastHarvestTime;
        uint256 lastShiftTime;
    }
    mapping(PoolId => PoolState) private _poolStates;
    
    // Active vaults per pool
    mapping(PoolId => address[]) private _activeVaults;
    
    // Vault balances per pool
    mapping(PoolId => mapping(address => uint256)) private _vaultBalances;

    // ============ Constants ============
    
    uint8 public constant MIN_SHIFT_PERCENTAGE = 10;
    uint8 public constant MAX_SHIFT_PERCENTAGE = 50;
    uint16 public constant MIN_APY_THRESHOLD = 200;  // 2%
    uint256 public constant MIN_SHIFT_INTERVAL = 30; // 30 seconds minimum between shifts

    // ============ Constructor ============
    
    constructor(
        IPoolManager _poolManager,
        address _yieldOracle,
        address _yieldRouter,
        address _yieldCompound
    ) {
        require(address(_poolManager) != address(0), "YieldShiftHook: Invalid pool manager");
        require(_yieldOracle != address(0), "YieldShiftHook: Invalid oracle");
        require(_yieldRouter != address(0), "YieldShiftHook: Invalid router");
        require(_yieldCompound != address(0), "YieldShiftHook: Invalid compound");

        poolManager = _poolManager;
        yieldOracle = IYieldOracle(_yieldOracle);
        yieldRouter = IYieldRouter(_yieldRouter);
        yieldCompound = YieldCompound(payable(_yieldCompound));

        // Validate hook address permissions
        Hooks.validateHookPermissions(this, getHookPermissions());
    }

    /// @notice Modifier to ensure only pool manager can call
    modifier onlyPoolManager() {
        require(msg.sender == address(poolManager), "YieldShiftHook: Not pool manager");
        _;
    }

    // ============ Hook Permissions ============
    
    /// @notice Returns the hook's permissions
    function getHookPermissions()
        public
        pure
        returns (Hooks.Permissions memory) 
    {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,           // ✅ Route capital to yield sources
            afterSwap: true,            // ✅ Harvest and compound rewards
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ============ Configuration ============
    
    /// @inheritdoc IYieldShiftHook
    function configurePool(
        PoolKey calldata key,
        YieldConfig memory config
    ) external override {
        PoolId poolId = key.toId();
        
        // Validate config
        require(
            config.shiftPercentage >= MIN_SHIFT_PERCENTAGE &&
            config.shiftPercentage <= MAX_SHIFT_PERCENTAGE,
            "YieldShiftHook: Invalid shift percentage"
        );
        require(
            config.minAPYThreshold >= MIN_APY_THRESHOLD,
            "YieldShiftHook: Invalid min APY"
        );
        require(
            config.riskTolerance >= 1 && config.riskTolerance <= 10,
            "YieldShiftHook: Invalid risk tolerance"
        );
        require(
            config.harvestFrequency > 0,
            "YieldShiftHook: Invalid harvest frequency"
        );
        require(config.admin != address(0), "YieldShiftHook: Invalid admin");
        
        _poolConfigs[poolId] = config;
        
        emit PoolConfigured(
            poolId,
            config.shiftPercentage,
            config.minAPYThreshold,
            config.riskTolerance
        );
    }

    // ============ Hook Callbacks ============

    /// @inheritdoc IHooks
    function beforeInitialize(address, PoolKey calldata, uint160) external pure returns (bytes4) {
        revert("YieldShiftHook: Not implemented");
    }

    /// @inheritdoc IHooks
    function afterInitialize(address, PoolKey calldata, uint160, int24) external pure returns (bytes4) {
        revert("YieldShiftHook: Not implemented");
    }

    /// @inheritdoc IHooks
    function beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert("YieldShiftHook: Not implemented");
    }

    /// @inheritdoc IHooks
    function afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert("YieldShiftHook: Not implemented");
    }

    /// @inheritdoc IHooks
    function beforeRemoveLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert("YieldShiftHook: Not implemented");
    }

    /// @inheritdoc IHooks
    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert("YieldShiftHook: Not implemented");
    }

    /// @notice Called before every swap - routes capital to best yield source
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        YieldConfig memory config = _poolConfigs[poolId];
        
        // Skip if not configured or paused
        if (config.admin == address(0) || config.isPaused) {
            return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
        }

        // Check if enough time has passed since last shift
        PoolState storage state = _poolStates[poolId];
        if (block.timestamp - state.lastShiftTime < MIN_SHIFT_INTERVAL) {
            return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
        }
        
        // Try to find best yield source
        try yieldOracle.getBestYield(config.riskTolerance) returns (
            address bestVault, 
            uint256 bestAPY
        ) {
            // Only shift if APY meets threshold
            if (bestAPY >= config.minAPYThreshold && bestVault != address(0)) {
                _shiftToVault(key, poolId, config, bestVault, bestAPY);
            }
        } catch {
            // If oracle fails, continue without shifting
        }

        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    /// @notice Called after every swap - harvests and compounds rewards
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4, int128) {
        PoolId poolId = key.toId();
        YieldConfig memory config = _poolConfigs[poolId];
        PoolState storage state = _poolStates[poolId];

        // Skip if not configured or paused
        if (config.admin == address(0) || config.isPaused) {
            return (IHooks.afterSwap.selector, 0);
        }

        // Increment swap counter
        state.swapCount++;

        // Check if it's time to harvest
        if (state.swapCount >= config.harvestFrequency) {
            _harvestAndCompound(key, poolId);
            state.swapCount = 0;
        }

        return (IHooks.afterSwap.selector, 0);
    }

    /// @inheritdoc IHooks
    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        revert("YieldShiftHook: Not implemented");
    }

    /// @inheritdoc IHooks
    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        revert("YieldShiftHook: Not implemented");
    }

    // ============ Admin Functions ============
    
    /// @inheritdoc IYieldShiftHook
    function pauseShifting(PoolId poolId) external override {
        YieldConfig storage config = _poolConfigs[poolId];
        require(msg.sender == config.admin, "YieldShiftHook: Not admin");
        
        config.isPaused = true;
        emit EmergencyPause(poolId, true);
    }

    /// @inheritdoc IYieldShiftHook
    function resumeShifting(PoolId poolId) external override {
        YieldConfig storage config = _poolConfigs[poolId];
        require(msg.sender == config.admin, "YieldShiftHook: Not admin");
        
        config.isPaused = false;
        emit EmergencyPause(poolId, false);
    }

    /// @inheritdoc IYieldShiftHook
    function emergencyWithdraw(PoolId poolId) external override nonReentrant {
        YieldConfig memory config = _poolConfigs[poolId];
        require(msg.sender == config.admin, "YieldShiftHook: Not admin");
        
        address[] storage vaults = _activeVaults[poolId];
        
        // Withdraw from all vaults
        for (uint256 i = 0; i < vaults.length; i++) {
            address vault = vaults[i];
            uint256 balance = _vaultBalances[poolId][vault];
            
            if (balance > 0) {
                try yieldRouter.withdrawFromVault(vault, balance) {
                    _vaultBalances[poolId][vault] = 0;
                } catch {
                    // Continue even if one withdrawal fails
                }
            }
        }
        
        // Clear state
        delete _activeVaults[poolId];
        _poolStates[poolId].totalShifted = 0;
    }

    /// @notice Update admin for a pool
    /// @param poolId Pool ID
    /// @param newAdmin New admin address
    function updateAdmin(PoolId poolId, address newAdmin) external {
        YieldConfig storage config = _poolConfigs[poolId];
        require(msg.sender == config.admin, "YieldShiftHook: Not admin");
        require(newAdmin != address(0), "YieldShiftHook: Invalid admin");
        
        config.admin = newAdmin;
    }

    // ============ View Functions ============
    
    /// @inheritdoc IYieldShiftHook
    function getPoolState(PoolId poolId) 
        external 
        view 
        override 
        returns (
            uint256 totalShifted,
            uint256 totalHarvested,
            uint256 swapCount,
            uint256 lastHarvestTime,
            address[] memory activeVaults
        ) 
    {
        PoolState memory state = _poolStates[poolId];
        return (
            state.totalShifted,
            state.totalHarvested,
            state.swapCount,
            state.lastHarvestTime,
            _activeVaults[poolId]
        );
    }

    /// @inheritdoc IYieldShiftHook
    function poolConfigs(PoolId poolId) external view override returns (YieldConfig memory) {
        return _poolConfigs[poolId];
    }

    /// @notice Get vault balance for a pool
    /// @param poolId Pool ID
    /// @param vault Vault address
    /// @return balance Balance in vault
    function getVaultBalance(PoolId poolId, address vault) external view returns (uint256 balance) {
        return _vaultBalances[poolId][vault];
    }

    /// @notice Get current best yield opportunity
    /// @param riskTolerance Maximum risk score
    /// @return vault Best vault address
    /// @return apy Best APY
    function getCurrentBestYield(uint256 riskTolerance) 
        external 
        view 
        returns (address vault, uint256 apy) 
    {
        return yieldOracle.getBestYield(riskTolerance);
    }

    // ============ Internal Functions ============
    
    /// @dev Shift capital to a vault
    function _shiftToVault(
        PoolKey calldata key,
        PoolId poolId,
        YieldConfig memory config,
        address vault,
        uint256 apy
    ) internal {
        PoolState storage state = _poolStates[poolId];
        
        // Calculate amount to shift
        uint256 shiftAmount = _calculateShiftAmount(key, config.shiftPercentage);
        
        if (shiftAmount == 0) return;
        
        // Get the token to shift (prefer stablecoins)
        address token = _getPreferredToken(key);
        if (token == address(0)) return;
        
        // Execute shift via router
        try yieldRouter.shiftToVault(vault, token, shiftAmount) returns (uint256 shares) {
            // Update state
            state.totalShifted += shiftAmount;
            state.lastShiftTime = block.timestamp;
            _vaultBalances[poolId][vault] += shares;
            
            // Add to active vaults if not present
            if (!_isVaultActive(poolId, vault)) {
                _activeVaults[poolId].push(vault);
            }
            
            emit YieldShifted(poolId, vault, shiftAmount, apy);
        } catch {
            // Shift failed - continue without error
        }
    }

    /// @dev Harvest rewards and compound
    function _harvestAndCompound(PoolKey calldata key, PoolId poolId) internal {
        PoolState storage state = _poolStates[poolId];
        address[] storage vaults = _activeVaults[poolId];
        
        uint256 totalHarvested = 0;
        
        // Harvest from all active vaults
        for (uint256 i = 0; i < vaults.length; i++) {
            try yieldRouter.harvest(vaults[i]) returns (uint256 rewards) {
                totalHarvested += rewards;
            } catch {
                // Continue even if one harvest fails
            }
        }
        
        if (totalHarvested > 0) {
            state.totalHarvested += totalHarvested;
            state.lastHarvestTime = block.timestamp;

            emit RewardsHarvested(poolId, totalHarvested);

            // Compound rewards back to pool
            // Note: Compounding requires the YieldCompound contract to:
            // 1. Convert harvested rewards to pool tokens via swap
            // 2. Add liquidity back to the pool via PoolManager
            // The YieldCompound contract handles this logic separately
            // This allows for flexible compounding strategies per pool
        }
    }

    /// @dev Calculate amount to shift based on pool liquidity
    function _calculateShiftAmount(
        PoolKey calldata key,
        uint8 shiftPercentage
    ) internal view returns (uint256) {
        // Get token addresses
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        // Strategy: Use hook's balance as proxy for shiftable liquidity
        // In V4, hooks can hold tokens as part of the pool's accounting
        // This is a conservative approach that only shifts what we control

        uint256 balance0 = token0 == address(0) ?
            address(this).balance :
            IERC20(token0).balanceOf(address(this));
        uint256 balance1 = token1 == address(0) ?
            0 :
            IERC20(token1).balanceOf(address(this));

        // Use the larger balance as the shiftable amount
        uint256 availableBalance = balance0 > balance1 ? balance0 : balance1;

        // Only shift if we have a minimum threshold (e.g., $100 worth)
        if (availableBalance < 100e6) return 0; // Assume 6 decimals (USDC)

        // Calculate shift amount based on percentage
        return availableBalance.calculateShiftAmount(shiftPercentage);
    }

    /// @dev Get preferred token to shift (prefer stablecoins)
    function _getPreferredToken(PoolKey calldata key) internal view returns (address) {
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);
        
        // Prefer non-native token
        if (token0 == address(0)) return token1;
        if (token1 == address(0)) return token0;
        
        // Otherwise return token1 (typically the quote token)
        return token1;
    }

    /// @dev Check if vault is in active list
    function _isVaultActive(PoolId poolId, address vault) internal view returns (bool) {
        address[] storage vaults = _activeVaults[poolId];
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] == vault) return true;
        }
        return false;
    }

    // ============ Receive ============
    
    receive() external payable {}
}
