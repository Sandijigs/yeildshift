// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {YieldRouter} from "../src/YieldRouter.sol";
import {YieldCompound} from "../src/YieldCompound.sol";
import {YieldShiftHook} from "../src/YieldShiftHook.sol";
import {YieldShiftFactory} from "../src/YieldShiftFactory.sol";
import {AaveAdapter} from "../src/adapters/AaveAdapter.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";
import {CompoundAdapter} from "../src/adapters/CompoundAdapter.sol";
import {EigenLayerAdapter} from "../src/adapters/EigenLayerAdapter.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

/// @title DeployBase
/// @notice Deployment script for Base network (Sepolia and Mainnet)
contract DeployBase is Script {
    
    // ============ Base Sepolia Addresses ============
    // Note: These are placeholder addresses - replace with actual deployed addresses
    
    // Uniswap v4 on Base Sepolia (update with actual address)
    address constant POOL_MANAGER_SEPOLIA = address(0);
    
    // Yield protocols on Base (update with actual addresses)
    address constant AAVE_POOL_BASE = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address constant MORPHO_BLUE_BASE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant COMPOUND_COMET_USDC_BASE = 0xb125E6687d4313864e53df431d5425969c15Eb2F;
    
    // Tokens on Base
    address constant WETH_BASE = 0x4200000000000000000000000000000000000006;
    address constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    
    // LRT tokens (may not exist on Base yet)
    address constant WEETH_BASE = address(0);
    address constant EZETH_BASE = address(0);
    address constant METH_BASE = address(0);

    // Deployed contracts
    YieldOracle public yieldOracle;
    YieldRouter public yieldRouter;
    YieldCompound public yieldCompound;
    YieldShiftHook public yieldShiftHook;
    YieldShiftFactory public yieldShiftFactory;
    AaveAdapter public aaveAdapter;
    MorphoAdapter public morphoAdapter;
    CompoundAdapter public compoundAdapter;
    EigenLayerAdapter public eigenLayerAdapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get pool manager address from env or use default
        address poolManager = vm.envOr("UNISWAP_V4_POOL_MANAGER", POOL_MANAGER_SEPOLIA);
        
        console.log("=== YieldShift Base Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Pool Manager:", poolManager);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ============ 1. Deploy Core Infrastructure ============
        console.log("Step 1: Deploying core infrastructure...");
        
        yieldOracle = new YieldOracle();
        console.log("  YieldOracle:", address(yieldOracle));
        
        yieldRouter = new YieldRouter();
        console.log("  YieldRouter:", address(yieldRouter));
        
        // Deploy YieldCompound with pool manager
        if (poolManager != address(0)) {
            yieldCompound = new YieldCompound(poolManager);
            console.log("  YieldCompound:", address(yieldCompound));
        } else {
            console.log("  YieldCompound: SKIPPED (no pool manager)");
        }

        // ============ 2. Deploy Adapters ============
        console.log("");
        console.log("Step 2: Deploying adapters...");
        
        // Aave Adapter
        if (AAVE_POOL_BASE != address(0)) {
            aaveAdapter = new AaveAdapter(AAVE_POOL_BASE);
            console.log("  AaveAdapter:", address(aaveAdapter));
        }
        
        // Morpho Adapter
        morphoAdapter = new MorphoAdapter();
        console.log("  MorphoAdapter:", address(morphoAdapter));
        
        // Compound Adapter
        compoundAdapter = new CompoundAdapter();
        console.log("  CompoundAdapter:", address(compoundAdapter));
        
        // EigenLayer Adapter
        if (WEETH_BASE != address(0) || EZETH_BASE != address(0) || METH_BASE != address(0)) {
            eigenLayerAdapter = new EigenLayerAdapter(
                WETH_BASE,
                WEETH_BASE,
                EZETH_BASE,
                METH_BASE
            );
            console.log("  EigenLayerAdapter:", address(eigenLayerAdapter));
        } else {
            console.log("  EigenLayerAdapter: SKIPPED (no LRTs on Base)");
        }

        // ============ 3. Register Adapters with Router ============
        console.log("");
        console.log("Step 3: Registering adapters...");
        
        if (AAVE_POOL_BASE != address(0) && address(aaveAdapter) != address(0)) {
            yieldRouter.registerAdapter(AAVE_POOL_BASE, address(aaveAdapter));
            console.log("  Registered Aave adapter");
        }
        
        if (MORPHO_BLUE_BASE != address(0)) {
            yieldRouter.registerAdapter(MORPHO_BLUE_BASE, address(morphoAdapter));
            console.log("  Registered Morpho adapter");
        }
        
        if (COMPOUND_COMET_USDC_BASE != address(0)) {
            yieldRouter.registerAdapter(COMPOUND_COMET_USDC_BASE, address(compoundAdapter));
            console.log("  Registered Compound adapter");
        }

        // ============ 4. Configure Oracle with Vaults ============
        console.log("");
        console.log("Step 4: Configuring oracle...");
        
        if (AAVE_POOL_BASE != address(0)) {
            yieldOracle.addVault(AAVE_POOL_BASE, address(0), 3); // Low risk
            yieldOracle.setAPY(AAVE_POOL_BASE, 600); // 6% APY estimate
            console.log("  Added Aave vault (risk: 3, APY: 6%)");
        }
        
        if (MORPHO_BLUE_BASE != address(0)) {
            yieldOracle.addVault(MORPHO_BLUE_BASE, address(0), 6); // Medium risk
            yieldOracle.setAPY(MORPHO_BLUE_BASE, 1200); // 12% APY estimate
            console.log("  Added Morpho vault (risk: 6, APY: 12%)");
        }
        
        if (COMPOUND_COMET_USDC_BASE != address(0)) {
            yieldOracle.addVault(COMPOUND_COMET_USDC_BASE, address(0), 4); // Low-medium risk
            yieldOracle.setAPY(COMPOUND_COMET_USDC_BASE, 400); // 4% APY estimate
            console.log("  Added Compound vault (risk: 4, APY: 4%)");
        }

        // ============ 5. Deploy Hook and Factory (if pool manager available) ============
        if (poolManager != address(0) && address(yieldCompound) != address(0)) {
            console.log("");
            console.log("Step 5: Deploying hook and factory...");
            
            yieldShiftHook = new YieldShiftHook(
                IPoolManager(poolManager),
                address(yieldOracle),
                address(yieldRouter),
                address(yieldCompound)
            );
            console.log("  YieldShiftHook:", address(yieldShiftHook));
            
            yieldShiftFactory = new YieldShiftFactory(
                poolManager,
                address(yieldShiftHook)
            );
            console.log("  YieldShiftFactory:", address(yieldShiftFactory));
            
            // Authorize hook to use router
            yieldRouter.setAuthorizedCaller(address(yieldShiftHook), true);
            console.log("  Authorized hook in router");
            
            // Authorize hook to use compounder
            yieldCompound.setAuthorizedCaller(address(yieldShiftHook), true);
            console.log("  Authorized hook in compounder");
        } else {
            console.log("");
            console.log("Step 5: SKIPPED - No pool manager configured");
        }

        vm.stopBroadcast();

        // ============ Print Summary ============
        _printSummary(deployer);
    }

    function _printSummary(address deployer) internal view {
        console.log("");
        console.log("========================================");
        console.log("        DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("");
        console.log("Core Contracts:");
        console.log("  YieldOracle:      ", address(yieldOracle));
        console.log("  YieldRouter:      ", address(yieldRouter));
        console.log("  YieldCompound:    ", address(yieldCompound));
        console.log("");
        console.log("Adapters:");
        console.log("  AaveAdapter:      ", address(aaveAdapter));
        console.log("  MorphoAdapter:    ", address(morphoAdapter));
        console.log("  CompoundAdapter:  ", address(compoundAdapter));
        console.log("  EigenLayerAdapter:", address(eigenLayerAdapter));
        console.log("");
        
        if (address(yieldShiftHook) != address(0)) {
            console.log("Hook & Factory:");
            console.log("  YieldShiftHook:   ", address(yieldShiftHook));
            console.log("  YieldShiftFactory:", address(yieldShiftFactory));
        }
        
        console.log("");
        console.log("========================================");
        console.log("");
        console.log("Next Steps:");
        console.log("1. Verify contracts on Basescan");
        console.log("2. Update frontend with contract addresses");
        console.log("3. Run SetupPool.s.sol to create initial pools");
        console.log("");
        
        // Output env format for easy copy
        console.log("Environment variables for .env:");
        console.log("YIELD_ORACLE_ADDRESS=", address(yieldOracle));
        console.log("YIELD_ROUTER_ADDRESS=", address(yieldRouter));
        console.log("YIELD_COMPOUND_ADDRESS=", address(yieldCompound));
        if (address(yieldShiftHook) != address(0)) {
            console.log("YIELD_SHIFT_HOOK_ADDRESS=", address(yieldShiftHook));
            console.log("YIELD_SHIFT_FACTORY_ADDRESS=", address(yieldShiftFactory));
        }
    }
}
