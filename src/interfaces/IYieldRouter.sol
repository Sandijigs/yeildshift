// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IYieldRouter
/// @notice Interface for YieldRouter contract
interface IYieldRouter {
    event VaultDeposit(address indexed vault, uint256 amount, uint256 shares);
    event VaultWithdraw(address indexed vault, uint256 shares, uint256 amount);
    event Harvested(address indexed vault, uint256 rewards);
    event AdapterRegistered(address indexed vault, address indexed adapter);

    function registerAdapter(address vault, address adapter) external;
    function shiftToVault(address vault, address token, uint256 amount) external returns (uint256 shares);
    function withdrawFromVault(address vault, uint256 shares) external returns (uint256 amount);
    function harvest(address vault) external returns (uint256 rewards);
    function getBalance(address vault, address account) external view returns (uint256);
    function vaultAdapters(address vault) external view returns (address);
}
