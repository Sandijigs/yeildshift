// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {YieldOracle} from "../src/YieldOracle.sol";
import {YieldRouter} from "../src/YieldRouter.sol";
import {YieldCompound} from "../src/YieldCompound.sol";
import {AaveAdapter} from "../src/adapters/AaveAdapter.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";
import {CompoundAdapter} from "../src/adapters/CompoundAdapter.sol";
import {EigenLayerAdapter} from "../src/adapters/EigenLayerAdapter.sol";

/// @title Deploy
/// @notice Main deployment script for YieldShift core contracts
contract Deploy is Script {
    
    // Deployed contract addresses
    YieldOracle public yieldOracle;
    YieldRouter public yieldRouter;
    YieldCompound public yieldCompound;
    AaveAdapter public aaveAdapter;
    MorphoAdapter public morphoAdapter;
    CompoundAdapter public compoundAdapter;
    EigenLayerAdapter public eigenLayerAdapter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== YieldShift Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Core Infrastructure
        console.log("Deploying core infrastructure...");
        
        yieldOracle = new YieldOracle();
        console.log("YieldOracle deployed at:", address(yieldOracle));
        
        yieldRouter = new YieldRouter();
        console.log("YieldRouter deployed at:", address(yieldRouter));

        // 2. Deploy Adapters
        console.log("");
        console.log("Deploying adapters...");
        
        morphoAdapter = new MorphoAdapter();
        console.log("MorphoAdapter deployed at:", address(morphoAdapter));
        
        compoundAdapter = new CompoundAdapter();
        console.log("CompoundAdapter deployed at:", address(compoundAdapter));

        // Note: AaveAdapter and EigenLayerAdapter require constructor arguments
        // They will be deployed in network-specific scripts

        vm.stopBroadcast();

        // Log summary
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("YieldOracle:", address(yieldOracle));
        console.log("YieldRouter:", address(yieldRouter));
        console.log("MorphoAdapter:", address(morphoAdapter));
        console.log("CompoundAdapter:", address(compoundAdapter));
        console.log("");
        console.log("Next steps:");
        console.log("1. Run DeployBase.s.sol for Base-specific contracts");
        console.log("2. Configure vaults in YieldOracle");
        console.log("3. Register adapters in YieldRouter");
    }
}
