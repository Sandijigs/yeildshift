// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IYieldOracle
/// @notice Interface for YieldOracle contract
interface IYieldOracle {
    struct YieldData {
        uint256 apy;
        uint256 lastUpdate;
        uint256 riskScore;
        bool isActive;
    }

    struct VaultConfig {
        address vaultAddress;
        address priceOracle;
        uint256 riskScore;
        bool isWhitelisted;
    }

    event APYUpdated(address indexed vault, uint256 apy, uint256 timestamp);
    event OracleAdded(address indexed vault, address oracle);
    event VaultRemoved(address indexed vault);

    function addVault(address vault, address priceOracle, uint256 riskScore) external;
    function removeVault(address vault) external;
    function getAPY(address vault) external view returns (uint256 apy);
    function updateAPY(address vault) external;
    function getBestYield(uint256 riskTolerance) external view returns (address bestVault, uint256 bestAPY);
    function getAllAPYs() external view returns (address[] memory vaults, uint256[] memory apys);
    function getVaultConfig(address vault) external view returns (VaultConfig memory);
    function getYieldData(address vault) external view returns (YieldData memory);
    function activeVaults(uint256 index) external view returns (address);
    function getActiveVaultsCount() external view returns (uint256);
}
