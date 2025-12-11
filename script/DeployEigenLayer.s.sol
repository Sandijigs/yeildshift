// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {EigenLayerAdapter} from "../src/adapters/EigenLayerAdapter.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {YieldRouter} from "../src/YieldRouter.sol";

/// @title DeployEigenLayer
/// @notice Deploy and integrate EigenLayer LRTs (weETH, ezETH) into YieldShift
contract DeployEigenLayer is Script {
    // Existing deployed contracts on Base Sepolia
    address constant YIELD_ORACLE = 0x554dc44df2AA9c718F6388ef057282893f31C04C;
    address constant YIELD_ROUTER = 0xEe1fFe183002c22607E84A335d29fa2E94538ffc;

    // Base Sepolia token addresses
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant WEETH = 0x76dB26De9E92730c24C69717741937d084858960; // Ether.fi wrapped eETH
    address constant EZETH = 0xa15E05954E22f795205A14f58C04C23a6BDF872E; // Renzo ezETH

    // State
    EigenLayerAdapter public eigenLayerAdapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("   EigenLayer Integration Deployment");
        console.log("========================================");
        console.log("Network: Base Sepolia (84532)");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH\n");

        vm.startBroadcast(deployerPrivateKey);

        // ============================================
        // 1. Deploy EigenLayerAdapter
        // ============================================
        console.log("Step 1: Deploying EigenLayerAdapter...");
        eigenLayerAdapter = new EigenLayerAdapter(
            WETH,
            WEETH,
            EZETH,
            address(0) // mETH not available on Base Sepolia
        );
        console.log("  Deployed at:", address(eigenLayerAdapter));

        // ============================================
        // 2. Configure APY Estimates
        // ============================================
        console.log("\nStep 2: Configuring APY estimates...");

        // weETH: ~3.5% ETH staking + ~4% EigenLayer = 7.5%
        eigenLayerAdapter.configureLRT(WEETH, 750);
        console.log("  weETH APY: 7.5% (750 bps)");

        // ezETH: ~3.5% ETH staking + ~5% EigenLayer = 8.5%
        eigenLayerAdapter.configureLRT(EZETH, 850);
        console.log("  ezETH APY: 8.5% (850 bps)");

        // ============================================
        // 3. Register in YieldOracle
        // ============================================
        console.log("\nStep 3: Registering vaults in YieldOracle...");
        YieldOracle oracle = YieldOracle(YIELD_ORACLE);

        // Register weETH
        oracle.addVault(
            WEETH,
            address(eigenLayerAdapter),
            5     // Medium risk (restaking adds complexity)
        );
        oracle.setAPY(WEETH, 750);  // 7.5% APY
        console.log("  weETH registered (7.5% APY, Risk: 5)");

        // Register ezETH
        oracle.addVault(
            EZETH,
            address(eigenLayerAdapter),
            6     // Medium-high risk
        );
        oracle.setAPY(EZETH, 850);  // 8.5% APY
        console.log("  ezETH registered (8.5% APY, Risk: 6)");

        // ============================================
        // 4. Register in YieldRouter
        // ============================================
        console.log("\nStep 4: Registering adapters in YieldRouter...");
        YieldRouter router = YieldRouter(payable(YIELD_ROUTER));

        router.registerAdapter(WEETH, address(eigenLayerAdapter));
        console.log("  weETH adapter registered");

        router.registerAdapter(EZETH, address(eigenLayerAdapter));
        console.log("  ezETH adapter registered");

        vm.stopBroadcast();

        // ============================================
        // 5. Deployment Summary
        // ============================================
        console.log("\n========================================");
        console.log("        Deployment Summary");
        console.log("========================================");
        console.log("\nCore Contract:");
        console.log("  EigenLayerAdapter:", address(eigenLayerAdapter));

        console.log("\nIntegrated LRTs:");
        console.log("  weETH (Ether.fi)");
        console.log("    Address:", WEETH);
        console.log("    APY: 7.5%");
        console.log("    Risk: 5");

        console.log("\n  ezETH (Renzo)");
        console.log("    Address:", EZETH);
        console.log("    APY: 8.5%");
        console.log("    Risk: 6");

        // ============================================
        // 6. Verification Commands
        // ============================================
        console.log("\n========================================");
        console.log("     Verification Commands");
        console.log("========================================\n");

        console.log("Check total vault count (should be 5):");
        console.log("cast call 0x554dc44df2AA9c718F6388ef057282893f31C04C \"getVaultCount()\" --rpc-url https://sepolia.base.org\n");

        console.log("Get all APYs:");
        console.log("cast call 0x554dc44df2AA9c718F6388ef057282893f31C04C \"getAllAPYs()(address[],uint256[])\" --rpc-url https://sepolia.base.org\n");

        console.log("Check weETH APY:");
        console.log("cast call 0x554dc44df2AA9c718F6388ef057282893f31C04C \"getAPY(address)\" 0x76dB26De9E92730c24C69717741937d084858960 --rpc-url https://sepolia.base.org\n");

        console.log("Check ezETH APY:");
        console.log("cast call 0x554dc44df2AA9c718F6388ef057282893f31C04C \"getAPY(address)\" 0xa15E05954E22f795205A14f58C04C23a6BDF872E --rpc-url https://sepolia.base.org\n");

        console.log("Get best yield for risk tolerance 10:");
        console.log("cast call 0x554dc44df2AA9c718F6388ef057282893f31C04C \"getBestYield(uint256)(address,uint256)\" 10 --rpc-url https://sepolia.base.org\n");

        // ============================================
        // 7. Next Steps
        // ============================================
        console.log("========================================");
        console.log("          Next Steps");
        console.log("========================================");
        console.log("1. Update frontend/src/contracts/index.ts");
        console.log("   eigenLayerAdapter:", address(eigenLayerAdapter));
        console.log("\n2. Add vault names to VAULT_NAMES:");
        console.log("   '0x76db26de9e92730c24c69717741937d084858960': 'weETH (Ether.fi)'");
        console.log("   '0xa15e05954e22f795205a14f58c04c23a6bdf872e': 'ezETH (Renzo)'");
        console.log("\n3. Redeploy frontend to Vercel");
        console.log("\n4. Update DEPLOYED_ADDRESSES.md");
        console.log("\n========================================");
        console.log("  EigenLayer Integration Complete! ");
        console.log("========================================\n");
    }
}
