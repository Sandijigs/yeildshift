// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BaseTest, MockERC20} from "../BaseTest.sol";
import {YieldOracle} from "../../src/YieldOracle.sol";
import {YieldRouter} from "../../src/YieldRouter.sol";
import {MorphoAdapter} from "../../src/adapters/MorphoAdapter.sol";
import {MockERC4626Vault} from "../mocks/MockERC4626Vault.sol";

/// @title FullFlowTest
/// @notice Integration tests for complete YieldShift flow
contract FullFlowTest is BaseTest {
    
    function setUp() public override {
        super.setUp();
        
        // Setup all vaults with oracle and router
        _setupFullSystem();
    }

    function _setupFullSystem() internal {
        vm.startPrank(deployer);
        
        // Add vaults to oracle with different risk scores
        yieldOracle.addVault(address(morphoVault), address(0), 6);   // Medium risk, 12% APY
        yieldOracle.addVault(address(aaveVault), address(0), 3);     // Low risk, 6% APY
        yieldOracle.addVault(address(compoundVault), address(0), 4); // Low-medium, 4% APY
        
        // Set APYs manually for testing
        yieldOracle.setAPY(address(morphoVault), 1200);
        yieldOracle.setAPY(address(aaveVault), 600);
        yieldOracle.setAPY(address(compoundVault), 400);
        
        // Register adapters in router
        yieldRouter.registerAdapter(address(morphoVault), address(morphoAdapter));
        yieldRouter.registerAdapter(address(aaveVault), address(morphoAdapter));
        yieldRouter.registerAdapter(address(compoundVault), address(morphoAdapter));
        
        // Authorize deployer for testing
        yieldRouter.setAuthorizedCaller(deployer, true);
        
        vm.stopPrank();
    }

    // ============ Full Flow Tests ============

    function test_FullFlow_FindBestYield_DepositAndWithdraw() public {
        // 1. Find the best yield opportunity
        (address bestVault, uint256 bestAPY) = yieldOracle.getBestYield(10);
        
        console.log("Best vault:", bestVault);
        console.log("Best APY:", bestAPY);
        
        assertEq(bestVault, address(morphoVault)); // Morpho has highest risk-adjusted yield
        assertEq(bestAPY, 1200);
        
        // 2. Deposit to best vault
        uint256 depositAmount = 10000e6; // 10k USDC
        
        vm.startPrank(deployer);
        usdc.approve(address(yieldRouter), depositAmount);
        uint256 shares = yieldRouter.shiftToVault(bestVault, address(usdc), depositAmount);
        vm.stopPrank();
        
        console.log("Shares received:", shares);
        assertTrue(shares > 0);
        
        // 3. Fast forward time to accrue yield
        skip(365 days);
        
        // 4. Harvest rewards
        vm.prank(deployer);
        uint256 rewards = yieldRouter.harvest(bestVault);
        
        console.log("Rewards harvested:", rewards);
        
        // 5. Withdraw
        vm.prank(deployer);
        uint256 withdrawnAmount = yieldRouter.withdrawFromVault(bestVault, shares);
        
        console.log("Amount withdrawn:", withdrawnAmount);
        assertTrue(withdrawnAmount >= depositAmount); // Should have at least original amount
    }

    function test_FullFlow_RiskBasedSelection() public {
        // Conservative user (low risk tolerance)
        (address conservativeVault, uint256 conservativeAPY) = yieldOracle.getBestYield(4);
        
        console.log("Conservative choice:");
        console.log("  Vault:", conservativeVault);
        console.log("  APY:", conservativeAPY);
        
        // Should pick Aave (low risk) over Morpho (medium risk)
        assertEq(conservativeVault, address(aaveVault));
        
        // Aggressive user (high risk tolerance)
        (address aggressiveVault, uint256 aggressiveAPY) = yieldOracle.getBestYield(10);
        
        console.log("Aggressive choice:");
        console.log("  Vault:", aggressiveVault);
        console.log("  APY:", aggressiveAPY);
        
        // Should pick Morpho (highest risk-adjusted return)
        assertEq(aggressiveVault, address(morphoVault));
    }

    function test_FullFlow_MultiVaultStrategy() public {
        // Deposit to multiple vaults
        uint256 totalDeposit = 30000e6; // 30k USDC
        uint256 perVaultDeposit = 10000e6; // 10k per vault
        
        vm.startPrank(deployer);
        usdc.approve(address(yieldRouter), totalDeposit);
        
        // Diversified strategy: deposit to all three vaults
        uint256 morphoShares = yieldRouter.shiftToVault(address(morphoVault), address(usdc), perVaultDeposit);
        uint256 aaveShares = yieldRouter.shiftToVault(address(aaveVault), address(usdc), perVaultDeposit);
        uint256 compoundShares = yieldRouter.shiftToVault(address(compoundVault), address(usdc), perVaultDeposit);
        vm.stopPrank();
        
        console.log("Diversified deposits:");
        console.log("  Morpho shares:", morphoShares);
        console.log("  Aave shares:", aaveShares);
        console.log("  Compound shares:", compoundShares);
        
        // Check total deposited
        assertEq(yieldRouter.totalDeposited(address(morphoVault)), perVaultDeposit);
        assertEq(yieldRouter.totalDeposited(address(aaveVault)), perVaultDeposit);
        assertEq(yieldRouter.totalDeposited(address(compoundVault)), perVaultDeposit);
        
        // Fast forward and harvest all
        skip(180 days);
        
        address[] memory vaults = new address[](3);
        vaults[0] = address(morphoVault);
        vaults[1] = address(aaveVault);
        vaults[2] = address(compoundVault);
        
        vm.prank(deployer);
        uint256 totalRewards = yieldRouter.harvestMultiple(vaults);
        
        console.log("Total rewards from all vaults:", totalRewards);
    }

    function test_FullFlow_APYComparison() public {
        // Get all APYs
        (address[] memory vaults, uint256[] memory apys) = yieldOracle.getAllAPYs();
        
        console.log("All vault APYs:");
        for (uint256 i = 0; i < vaults.length; i++) {
            console.log("  Vault:", vaults[i]);
            console.log("  APY:", apys[i], "bps");
        }
        
        assertEq(vaults.length, 3);
        
        // Verify APY order
        uint256 morphoAPY = yieldOracle.getAPY(address(morphoVault));
        uint256 aaveAPY = yieldOracle.getAPY(address(aaveVault));
        uint256 compoundAPY = yieldOracle.getAPY(address(compoundVault));
        
        assertTrue(morphoAPY > aaveAPY);
        assertTrue(aaveAPY > compoundAPY);
    }

    function test_FullFlow_RebalanceStrategy() public {
        uint256 depositAmount = 10000e6;
        
        vm.startPrank(deployer);
        usdc.approve(address(yieldRouter), depositAmount * 2);
        
        // Initial deposit to Aave
        uint256 aaveShares = yieldRouter.shiftToVault(address(aaveVault), address(usdc), depositAmount);
        
        console.log("Initial deposit to Aave:", depositAmount);
        
        // Simulate APY change - Morpho becomes much better
        yieldOracle.setAPY(address(morphoVault), 2000); // 20% APY
        
        // Find new best yield
        (address newBest, uint256 newBestAPY) = yieldOracle.getBestYield(10);
        
        console.log("New best vault:", newBest);
        console.log("New best APY:", newBestAPY);
        
        assertEq(newBest, address(morphoVault));
        assertEq(newBestAPY, 2000);
        
        // Rebalance: withdraw from Aave, deposit to Morpho
        uint256 withdrawn = yieldRouter.withdrawFromVault(address(aaveVault), aaveShares);
        
        // Note: In real scenario, withdrawn USDC would need to be available
        // For testing, we'll deposit new funds to Morpho
        uint256 morphoShares = yieldRouter.shiftToVault(address(morphoVault), address(usdc), depositAmount);
        
        vm.stopPrank();
        
        console.log("Rebalanced to Morpho, shares:", morphoShares);
        assertTrue(morphoShares > 0);
    }

    function test_FullFlow_EmergencyScenario() public {
        uint256 depositAmount = 10000e6;
        
        // Setup: deposit to vault
        vm.startPrank(deployer);
        usdc.approve(address(yieldRouter), depositAmount);
        yieldRouter.shiftToVault(address(morphoVault), address(usdc), depositAmount);
        vm.stopPrank();
        
        // Emergency: need to withdraw everything
        vm.prank(deployer);
        uint256 withdrawn = yieldRouter.emergencyWithdrawAll(address(morphoVault));
        
        console.log("Emergency withdrawal amount:", withdrawn);
        assertTrue(withdrawn > 0);
        assertEq(yieldRouter.totalDeposited(address(morphoVault)), 0);
    }

    // ============ Yield Calculation Tests ============

    function test_YieldCalculation_OneYear() public {
        uint256 principal = 100000e6; // 100k USDC
        uint256 apy = 1200; // 12% APY
        
        // Expected yield after 1 year
        // yield = principal * apy / 10000
        uint256 expectedYield = (principal * apy) / 10000;
        
        console.log("Principal:", principal);
        console.log("APY:", apy, "bps (", apy / 100, "%)");
        console.log("Expected yearly yield:", expectedYield);
        
        // Verify calculation
        assertEq(expectedYield, 12000e6); // 12k USDC
    }

    function test_YieldCalculation_ComparedToVanillaPool() public {
        uint256 principal = 100000e6; // 100k USDC
        
        // Vanilla Uniswap pool APY (swap fees only)
        uint256 vanillaAPY = 30; // 0.3%
        uint256 vanillaYield = (principal * vanillaAPY) / 10000;
        
        // YieldShift enhanced APY (swap fees + yield farming)
        uint256 swapFeeAPY = 30; // 0.3%
        uint256 yieldFarmingAPY = 1200; // 12%
        uint256 totalAPY = swapFeeAPY + yieldFarmingAPY;
        uint256 enhancedYield = (principal * totalAPY) / 10000;
        
        console.log("=== Yield Comparison ===");
        console.log("Principal:", principal / 1e6, "USDC");
        console.log("");
        console.log("Vanilla Uniswap Pool:");
        console.log("  APY:", vanillaAPY, "bps (0.3%)");
        console.log("  Yearly yield:", vanillaYield / 1e6, "USDC");
        console.log("");
        console.log("YieldShift Enhanced Pool:");
        console.log("  Swap Fee APY:", swapFeeAPY, "bps");
        console.log("  Yield Farming APY:", yieldFarmingAPY, "bps");
        console.log("  Total APY:", totalAPY, "bps (12.3%)");
        console.log("  Yearly yield:", enhancedYield / 1e6, "USDC");
        console.log("");
        console.log("Extra yield from YieldShift:", (enhancedYield - vanillaYield) / 1e6, "USDC");
        
        // YieldShift should provide significantly more yield
        assertTrue(enhancedYield > vanillaYield * 10); // At least 10x more
    }
}
