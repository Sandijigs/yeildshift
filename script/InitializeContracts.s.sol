// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {YieldRouter} from "../src/YieldRouter.sol";
import {AaveAdapter} from "../src/adapters/AaveAdapter.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";
import {CompoundAdapter} from "../src/adapters/CompoundAdapter.sol";

/// @title InitializeContracts
/// @notice Initialize deployed contracts with test vault data
contract InitializeContracts is Script {
    // Deployed contract addresses (Base Sepolia)
    address constant YIELD_ORACLE = 0x554dc44df2AA9c718F6388ef057282893f31C04C;
    address constant YIELD_ROUTER = 0xEe1fFe183002c22607E84A335d29fa2E94538ffc;
    address constant YIELD_SHIFT_HOOK = 0xE0122CF1AbC59977a8F1DC1A02B36c678d5F40C0;

    // Mock vault addresses (for testing - these are example addresses)
    address constant MORPHO_VAULT = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant AAVE_VAULT = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address constant COMPOUND_VAULT = 0xb125E6687d4313864e53df431d5425969c15Eb2F;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        YieldOracle oracle = YieldOracle(YIELD_ORACLE);
        YieldRouter router = YieldRouter(YIELD_ROUTER);

        console.log("=== Initializing YieldShift Contracts ===");
        console.log("Oracle:", address(oracle));
        console.log("Router:", address(router));
        console.log("");

        // Step 1: Add vaults to YieldOracle
        console.log("Step 1: Adding vaults to YieldOracle...");

        // Add Morpho Blue vault (12% APY, Risk 6)
        try oracle.addVault(
            MORPHO_VAULT,
            address(0), // No price oracle for test
            6 // Risk score
        ) {
            console.log("  - Added Morpho Blue vault");
        } catch {
            console.log("  - Morpho vault already added or error");
        }

        // Add Aave v3 vault (6% APY, Risk 3)
        try oracle.addVault(
            AAVE_VAULT,
            address(0),
            3 // Risk score
        ) {
            console.log("  - Added Aave v3 vault");
        } catch {
            console.log("  - Aave vault already added or error");
        }

        // Add Compound v3 vault (4% APY, Risk 4)
        try oracle.addVault(
            COMPOUND_VAULT,
            address(0),
            4 // Risk score
        ) {
            console.log("  - Added Compound v3 vault");
        } catch {
            console.log("  - Compound vault already added or error");
        }

        console.log("");

        // Step 2: Update APYs (in basis points: 12% = 1200, 6% = 600, 4% = 400)
        console.log("Step 2: Setting initial APYs...");

        try oracle.updateAPY(MORPHO_VAULT) {
            console.log("  - Updated Morpho APY");
        } catch {
            console.log("  - Morpho APY update skipped");
        }

        try oracle.updateAPY(AAVE_VAULT) {
            console.log("  - Updated Aave APY");
        } catch {
            console.log("  - Aave APY update skipped");
        }

        try oracle.updateAPY(COMPOUND_VAULT) {
            console.log("  - Updated Compound APY");
        } catch {
            console.log("  - Compound APY update skipped");
        }

        console.log("");

        // Step 3: Authorize YieldShiftHook to use YieldRouter
        console.log("Step 3: Authorizing YieldShiftHook...");
        try router.setAuthorizedCaller(YIELD_SHIFT_HOOK, true) {
            console.log("  - YieldShiftHook authorized");
        } catch {
            console.log("  - Authorization already set or error");
        }

        console.log("");
        console.log("=== Initialization Complete! ===");
        console.log("");
        console.log("Next steps:");
        console.log("1. Refresh your frontend");
        console.log("2. Data should now load from contracts");
        console.log("3. Check browser console for contract calls");

        vm.stopBroadcast();
    }
}
