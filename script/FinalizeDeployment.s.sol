// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {YieldShiftFactory} from "../src/YieldShiftFactory.sol";
import {YieldRouter} from "../src/YieldRouter.sol";
import {YieldCompound} from "../src/YieldCompound.sol";

/// @title FinalizeDeployment
/// @notice Finalizes deployment by deploying factory and configuring authorizations
contract FinalizeDeployment is Script {

    address constant POOL_MANAGER_SEPOLIA = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    address constant UNIVERSAL_ROUTER_SEPOLIA = 0x492E6456D9528771018DeB9E87ef7750EF184104;

    function run() external {
        // Load environment
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Load deployed addresses
        address yieldRouter = 0xEe1fFe183002c22607E84A335d29fa2E94538ffc;
        address yieldCompound = 0x4E0C6E13eAee2C879D075c285b31272AE6b3967C;
        address yieldShiftHook = 0x4f2cD1d5Af1C5bf691133A8560eab1ACCF90C0c0;

        console.log("=== Finalizing YieldShift Deployment ===");
        console.log("YieldRouter:", yieldRouter);
        console.log("YieldCompound:", yieldCompound);
        console.log("YieldShiftHook:", yieldShiftHook);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy factory
        console.log("Deploying YieldShiftFactory...");
        YieldShiftFactory factory = new YieldShiftFactory(
            POOL_MANAGER_SEPOLIA,
            yieldShiftHook
        );
        console.log("YieldShiftFactory:", address(factory));
        console.log("");

        // Authorize hook in router
        console.log("Authorizing hook in YieldRouter...");
        YieldRouter(yieldRouter).setAuthorizedCaller(yieldShiftHook, true);
        console.log("  Done");

        // Authorize hook in compounder
        console.log("Authorizing hook in YieldCompound...");
        YieldCompound(payable(yieldCompound)).setAuthorizedCaller(yieldShiftHook, true);
        console.log("  Done");

        // Set Universal Router
        console.log("Setting Universal Router...");
        YieldCompound(payable(yieldCompound)).setSwapRouter(UNIVERSAL_ROUTER_SEPOLIA);
        console.log("  Done");

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("  DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("YieldShiftHook:", yieldShiftHook);
        console.log("YieldShiftFactory:", address(factory));
        console.log("");
        console.log("Add to .env:");
        console.log("YIELD_SHIFT_HOOK_ADDRESS=", yieldShiftHook);
        console.log("YIELD_SHIFT_FACTORY_ADDRESS=", address(factory));
    }
}
