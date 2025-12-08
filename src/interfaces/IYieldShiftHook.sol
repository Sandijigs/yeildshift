// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";

/// @title IYieldShiftHook
/// @notice Interface for YieldShiftHook contract
interface IYieldShiftHook {
    struct YieldConfig {
        uint8 shiftPercentage;      // 10-50: % of idle liquidity to shift
        uint16 minAPYThreshold;     // in basis points (500 = 5%)
        uint8 harvestFrequency;     // swaps between harvests
        uint8 riskTolerance;        // 1-10: max risk score
        bool isPaused;              // emergency pause
        address admin;              // can pause/unpause
    }

    event YieldShifted(
        PoolId indexed poolId,
        address indexed vault,
        uint256 amount,
        uint256 apy
    );
    
    event RewardsHarvested(
        PoolId indexed poolId,
        uint256 amount
    );
    
    event YieldCompounded(
        PoolId indexed poolId,
        uint256 amount0,
        uint256 amount1
    );
    
    event PoolConfigured(
        PoolId indexed poolId,
        uint8 shiftPercentage,
        uint16 minAPYThreshold,
        uint8 riskTolerance
    );
    
    event EmergencyPause(
        PoolId indexed poolId,
        bool paused
    );

    function configurePool(PoolKey calldata key, YieldConfig memory config) external;
    function pauseShifting(PoolId poolId) external;
    function resumeShifting(PoolId poolId) external;
    function emergencyWithdraw(PoolId poolId) external;
    function getPoolState(PoolId poolId) external view returns (
        uint256 totalShifted,
        uint256 totalHarvested,
        uint256 swapCount,
        uint256 lastHarvestTime,
        address[] memory activeVaults
    );
    function poolConfigs(PoolId poolId) external view returns (YieldConfig memory);
}
