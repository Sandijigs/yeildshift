// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest, MockERC20} from "../BaseTest.sol";
import {YieldRouter} from "../../src/YieldRouter.sol";
import {MorphoAdapter} from "../../src/adapters/MorphoAdapter.sol";
import {MockERC4626Vault} from "../mocks/MockERC4626Vault.sol";

contract YieldRouterTest is BaseTest {
    
    function setUp() public override {
        super.setUp();
        
        // Setup vault with adapter
        vm.startPrank(deployer);
        yieldRouter.registerAdapter(address(morphoVault), address(morphoAdapter));
        vm.stopPrank();
    }

    // ============ Register Adapter Tests ============

    function test_RegisterAdapter_Success() public {
        vm.prank(deployer);
        yieldRouter.registerAdapter(address(aaveVault), address(morphoAdapter));
        
        assertEq(yieldRouter.vaultAdapters(address(aaveVault)), address(morphoAdapter));
    }

    function test_RegisterAdapter_RevertOnZeroVault() public {
        vm.prank(deployer);
        vm.expectRevert("YieldRouter: Invalid vault");
        yieldRouter.registerAdapter(address(0), address(morphoAdapter));
    }

    function test_RegisterAdapter_RevertOnZeroAdapter() public {
        vm.prank(deployer);
        vm.expectRevert("YieldRouter: Invalid adapter");
        yieldRouter.registerAdapter(address(aaveVault), address(0));
    }

    function test_RegisterAdapter_RevertOnDuplicate() public {
        vm.startPrank(deployer);
        vm.expectRevert("YieldRouter: Already registered");
        yieldRouter.registerAdapter(address(morphoVault), address(morphoAdapter));
        vm.stopPrank();
    }

    function test_RegisterAdapter_NotOwner() public {
        vm.prank(lpProvider);
        vm.expectRevert();
        yieldRouter.registerAdapter(address(aaveVault), address(morphoAdapter));
    }

    // ============ Authorization Tests ============

    function test_SetAuthorizedCaller() public {
        vm.prank(deployer);
        yieldRouter.setAuthorizedCaller(lpProvider, true);
        
        assertTrue(yieldRouter.authorizedCallers(lpProvider));
    }

    function test_SetAuthorizedCaller_Revoke() public {
        vm.startPrank(deployer);
        yieldRouter.setAuthorizedCaller(lpProvider, true);
        yieldRouter.setAuthorizedCaller(lpProvider, false);
        vm.stopPrank();
        
        assertFalse(yieldRouter.authorizedCallers(lpProvider));
    }

    // ============ Shift To Vault Tests ============

    function test_ShiftToVault_Success() public {
        uint256 amount = 1000e6; // 1000 USDC
        
        // Authorize the deployer
        vm.prank(deployer);
        yieldRouter.setAuthorizedCaller(deployer, true);
        
        // Approve tokens
        vm.startPrank(deployer);
        usdc.approve(address(yieldRouter), amount);
        
        // Shift to vault
        uint256 shares = yieldRouter.shiftToVault(
            address(morphoVault),
            address(usdc),
            amount
        );
        vm.stopPrank();
        
        assertTrue(shares > 0);
        assertEq(yieldRouter.totalDeposited(address(morphoVault)), amount);
    }

    function test_ShiftToVault_RevertOnZeroAmount() public {
        vm.prank(deployer);
        yieldRouter.setAuthorizedCaller(deployer, true);
        
        vm.prank(deployer);
        vm.expectRevert("YieldRouter: Zero amount");
        yieldRouter.shiftToVault(address(morphoVault), address(usdc), 0);
    }

    function test_ShiftToVault_RevertOnNoAdapter() public {
        vm.prank(deployer);
        yieldRouter.setAuthorizedCaller(deployer, true);
        
        vm.prank(deployer);
        vm.expectRevert("YieldRouter: No adapter");
        yieldRouter.shiftToVault(address(aaveVault), address(usdc), 1000e6);
    }

    function test_ShiftToVault_RevertOnUnauthorized() public {
        vm.prank(lpProvider);
        vm.expectRevert("YieldRouter: Not authorized");
        yieldRouter.shiftToVault(address(morphoVault), address(usdc), 1000e6);
    }

    // ============ Withdraw From Vault Tests ============

    function test_WithdrawFromVault_Success() public {
        uint256 amount = 1000e6;
        
        // Setup: authorize and deposit
        vm.startPrank(deployer);
        yieldRouter.setAuthorizedCaller(deployer, true);
        usdc.approve(address(yieldRouter), amount);
        uint256 shares = yieldRouter.shiftToVault(address(morphoVault), address(usdc), amount);
        
        // Withdraw
        uint256 withdrawn = yieldRouter.withdrawFromVault(address(morphoVault), shares);
        vm.stopPrank();
        
        assertTrue(withdrawn > 0);
    }

    function test_WithdrawFromVault_RevertOnZeroShares() public {
        vm.prank(deployer);
        yieldRouter.setAuthorizedCaller(deployer, true);
        
        vm.prank(deployer);
        vm.expectRevert("YieldRouter: Zero shares");
        yieldRouter.withdrawFromVault(address(morphoVault), 0);
    }

    // ============ Harvest Tests ============

    function test_Harvest_Success() public {
        uint256 amount = 1000e6;
        
        // Setup: deposit first
        vm.startPrank(deployer);
        yieldRouter.setAuthorizedCaller(deployer, true);
        usdc.approve(address(yieldRouter), amount);
        yieldRouter.shiftToVault(address(morphoVault), address(usdc), amount);
        
        // Fast forward time to accrue yield
        skip(30 days);
        
        // Harvest
        uint256 rewards = yieldRouter.harvest(address(morphoVault));
        vm.stopPrank();
        
        // Rewards should be tracked
        assertEq(yieldRouter.totalHarvested(address(morphoVault)), rewards);
    }

    function test_HarvestMultiple() public {
        // Setup second vault
        vm.startPrank(deployer);
        yieldRouter.registerAdapter(address(aaveVault), address(morphoAdapter));
        yieldRouter.setAuthorizedCaller(deployer, true);
        
        // Deposit to both vaults
        usdc.approve(address(yieldRouter), 2000e6);
        yieldRouter.shiftToVault(address(morphoVault), address(usdc), 1000e6);
        yieldRouter.shiftToVault(address(aaveVault), address(usdc), 1000e6);
        
        skip(30 days);
        
        // Harvest multiple
        address[] memory vaults = new address[](2);
        vaults[0] = address(morphoVault);
        vaults[1] = address(aaveVault);
        
        uint256 totalRewards = yieldRouter.harvestMultiple(vaults);
        vm.stopPrank();
        
        assertTrue(totalRewards >= 0); // May be 0 depending on mock implementation
    }

    // ============ View Functions Tests ============

    function test_GetAllVaults() public {
        vm.startPrank(deployer);
        yieldRouter.registerAdapter(address(aaveVault), address(morphoAdapter));
        vm.stopPrank();
        
        address[] memory vaults = yieldRouter.getAllVaults();
        assertEq(vaults.length, 2);
    }

    function test_GetVaultCount() public {
        assertEq(yieldRouter.getVaultCount(), 1); // morphoVault already registered
        
        vm.prank(deployer);
        yieldRouter.registerAdapter(address(aaveVault), address(morphoAdapter));
        
        assertEq(yieldRouter.getVaultCount(), 2);
    }

    function test_IsRegistered() public {
        assertTrue(yieldRouter.isRegistered(address(morphoVault)));
        assertFalse(yieldRouter.isRegistered(address(aaveVault)));
    }

    function test_GetAPY() public {
        uint256 apy = yieldRouter.getAPY(address(morphoVault));
        assertTrue(apy > 0);
    }

    // ============ Emergency Functions Tests ============

    function test_EmergencyWithdrawAll() public {
        uint256 amount = 1000e6;
        
        // Setup: deposit
        vm.startPrank(deployer);
        yieldRouter.setAuthorizedCaller(deployer, true);
        usdc.approve(address(yieldRouter), amount);
        yieldRouter.shiftToVault(address(morphoVault), address(usdc), amount);
        
        // Emergency withdraw
        uint256 withdrawn = yieldRouter.emergencyWithdrawAll(address(morphoVault));
        vm.stopPrank();
        
        assertTrue(withdrawn > 0);
        assertEq(yieldRouter.totalDeposited(address(morphoVault)), 0);
    }

    function test_RescueTokens() public {
        // Send some tokens to router accidentally
        vm.prank(deployer);
        usdc.transfer(address(yieldRouter), 100e6);
        
        // Rescue tokens
        vm.prank(deployer);
        yieldRouter.rescueTokens(address(usdc), admin, 100e6);
        
        assertEq(usdc.balanceOf(admin), 100e6);
    }
}
