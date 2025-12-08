// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest, MockERC20} from "../BaseTest.sol";
import {YieldOracle} from "../../src/YieldOracle.sol";
import {MockERC4626Vault} from "../mocks/MockERC4626Vault.sol";

contract YieldOracleTest is BaseTest {
    
    function setUp() public override {
        super.setUp();
    }

    // ============ Add Vault Tests ============

    function test_AddVault_Success() public {
        vm.prank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        
        YieldOracle.VaultConfig memory config = yieldOracle.getVaultConfig(address(morphoVault));
        
        assertEq(config.vaultAddress, address(morphoVault));
        assertEq(config.riskScore, 5);
        assertTrue(config.isWhitelisted);
    }

    function test_AddVault_RevertOnZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert("YieldOracle: Invalid vault");
        yieldOracle.addVault(address(0), address(0), 5);
    }

    function test_AddVault_RevertOnInvalidRiskScore() public {
        vm.prank(deployer);
        vm.expectRevert("YieldOracle: Invalid risk score");
        yieldOracle.addVault(address(morphoVault), address(0), 0);

        vm.prank(deployer);
        vm.expectRevert("YieldOracle: Invalid risk score");
        yieldOracle.addVault(address(morphoVault), address(0), 11);
    }

    function test_AddVault_RevertOnDuplicate() public {
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        
        vm.expectRevert("YieldOracle: Vault already added");
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        vm.stopPrank();
    }

    function test_AddVault_NotOwner() public {
        vm.prank(lpProvider);
        vm.expectRevert();
        yieldOracle.addVault(address(morphoVault), address(0), 5);
    }

    // ============ Remove Vault Tests ============

    function test_RemoveVault_Success() public {
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        yieldOracle.removeVault(address(morphoVault));
        vm.stopPrank();
        
        YieldOracle.VaultConfig memory config = yieldOracle.getVaultConfig(address(morphoVault));
        assertFalse(config.isWhitelisted);
    }

    function test_RemoveVault_RevertOnNotFound() public {
        vm.prank(deployer);
        vm.expectRevert("YieldOracle: Vault not found");
        yieldOracle.removeVault(address(morphoVault));
    }

    // ============ Get APY Tests ============

    function test_GetAPY_FromVault() public {
        vm.prank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        
        // Mock vault returns 12% APY (1200 bps)
        uint256 apy = yieldOracle.getAPY(address(morphoVault));
        
        // Should return estimated APY since no updates have been made
        assertTrue(apy > 0);
    }

    function test_SetAPY_ManualUpdate() public {
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        yieldOracle.setAPY(address(morphoVault), 1500); // 15%
        vm.stopPrank();
        
        uint256 apy = yieldOracle.getAPY(address(morphoVault));
        assertEq(apy, 1500);
    }

    // ============ Get Best Yield Tests ============

    function test_GetBestYield_SingleVault() public {
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        yieldOracle.setAPY(address(morphoVault), 1200);
        vm.stopPrank();
        
        (address bestVault, uint256 bestAPY) = yieldOracle.getBestYield(10);
        
        assertEq(bestVault, address(morphoVault));
        assertEq(bestAPY, 1200);
    }

    function test_GetBestYield_MultipleVaults() public {
        vm.startPrank(deployer);
        
        // Add three vaults with different APYs and risk scores
        yieldOracle.addVault(address(morphoVault), address(0), 6);   // Medium risk
        yieldOracle.addVault(address(aaveVault), address(0), 3);     // Low risk
        yieldOracle.addVault(address(compoundVault), address(0), 4); // Low-medium risk
        
        yieldOracle.setAPY(address(morphoVault), 1200);    // 12%
        yieldOracle.setAPY(address(aaveVault), 600);       // 6%
        yieldOracle.setAPY(address(compoundVault), 400);   // 4%
        
        vm.stopPrank();
        
        // With high risk tolerance, should pick highest APY
        (address bestVault, uint256 bestAPY) = yieldOracle.getBestYield(10);
        
        // Morpho has highest risk-adjusted score (1200 * 5 / 10 = 600)
        // Aave: 600 * 8 / 10 = 480
        // Compound: 400 * 7 / 10 = 280
        assertEq(bestVault, address(morphoVault));
        assertEq(bestAPY, 1200);
    }

    function test_GetBestYield_RiskFiltering() public {
        vm.startPrank(deployer);
        
        // Add vault with high risk
        yieldOracle.addVault(address(morphoVault), address(0), 8); // High risk
        yieldOracle.addVault(address(aaveVault), address(0), 3);   // Low risk
        
        yieldOracle.setAPY(address(morphoVault), 1500);
        yieldOracle.setAPY(address(aaveVault), 600);
        
        vm.stopPrank();
        
        // With low risk tolerance, should skip high-risk vault
        (address bestVault, ) = yieldOracle.getBestYield(5);
        
        assertEq(bestVault, address(aaveVault));
    }

    function test_GetBestYield_NoValidVault() public {
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 10); // Maximum risk
        yieldOracle.setAPY(address(morphoVault), 1200);
        vm.stopPrank();
        
        // With very low risk tolerance
        vm.expectRevert("YieldOracle: No valid vault found");
        yieldOracle.getBestYield(1);
    }

    // ============ Get All APYs Tests ============

    function test_GetAllAPYs() public {
        vm.startPrank(deployer);
        
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        yieldOracle.addVault(address(aaveVault), address(0), 3);
        
        yieldOracle.setAPY(address(morphoVault), 1200);
        yieldOracle.setAPY(address(aaveVault), 600);
        
        vm.stopPrank();
        
        (address[] memory vaults, uint256[] memory apys) = yieldOracle.getAllAPYs();
        
        assertEq(vaults.length, 2);
        assertEq(apys.length, 2);
        
        // Find indices (order may vary)
        bool foundMorpho = false;
        bool foundAave = false;
        
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaults[i] == address(morphoVault)) {
                assertEq(apys[i], 1200);
                foundMorpho = true;
            }
            if (vaults[i] == address(aaveVault)) {
                assertEq(apys[i], 600);
                foundAave = true;
            }
        }
        
        assertTrue(foundMorpho);
        assertTrue(foundAave);
    }

    // ============ Risk Score Update Tests ============

    function test_SetRiskScore() public {
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        yieldOracle.setRiskScore(address(morphoVault), 8);
        vm.stopPrank();
        
        YieldOracle.VaultConfig memory config = yieldOracle.getVaultConfig(address(morphoVault));
        assertEq(config.riskScore, 8);
    }

    // ============ Active Vaults Tests ============

    function test_GetActiveVaultsCount() public {
        assertEq(yieldOracle.getActiveVaultsCount(), 0);
        
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        assertEq(yieldOracle.getActiveVaultsCount(), 1);
        
        yieldOracle.addVault(address(aaveVault), address(0), 3);
        assertEq(yieldOracle.getActiveVaultsCount(), 2);
        
        yieldOracle.removeVault(address(morphoVault));
        assertEq(yieldOracle.getActiveVaultsCount(), 1);
        vm.stopPrank();
    }

    function test_ActiveVaults_Index() public {
        vm.startPrank(deployer);
        yieldOracle.addVault(address(morphoVault), address(0), 5);
        yieldOracle.addVault(address(aaveVault), address(0), 3);
        vm.stopPrank();
        
        address vault0 = yieldOracle.activeVaults(0);
        address vault1 = yieldOracle.activeVaults(1);
        
        assertTrue(vault0 == address(morphoVault) || vault0 == address(aaveVault));
        assertTrue(vault1 == address(morphoVault) || vault1 == address(aaveVault));
        assertTrue(vault0 != vault1);
    }
}
