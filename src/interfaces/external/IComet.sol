// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IComet
/// @notice Interface for Compound v3 (Comet) contract
interface IComet {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function borrowBalanceOf(address account) external view returns (uint256);
    function baseToken() external view returns (address);
    function getUtilization() external view returns (uint256);
    function getSupplyRate(uint256 utilization) external view returns (uint64);
    function getBorrowRate(uint256 utilization) external view returns (uint64);
    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    
    // Rewards
    function baseTrackingSupplySpeed() external view returns (uint256);
    function baseTrackingBorrowSpeed() external view returns (uint256);
    
    // Allow/disallow interactions
    function allow(address manager, bool isAllowed) external;
    function allowBySig(
        address owner,
        address manager,
        bool isAllowed,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @title ICometRewards
/// @notice Interface for Compound v3 Rewards contract
interface ICometRewards {
    struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }

    function claim(address comet, address src, bool shouldAccrue) external;
    function getRewardOwed(address comet, address account) external returns (address, uint256);
    function rewardConfig(address comet) external view returns (RewardConfig memory);
}
