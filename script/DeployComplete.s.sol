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
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

/// @title DeployComplete
/// @notice Complete YieldShift deployment with CREATE2 hook mining
contract DeployComplete is Script {

    // CREATE2 Deployer (standard across chains)
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // Base Sepolia addresses
    address constant POOL_MANAGER_SEPOLIA = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    address constant UNIVERSAL_ROUTER_SEPOLIA = 0x492E6456D9528771018DeB9E87ef7750EF184104;
    address constant AAVE_POOL_BASE = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address constant MORPHO_BLUE_BASE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant COMPOUND_COMET_USDC_BASE = 0xb125E6687d4313864e53df431d5425969c15Eb2F;

    // Base Mainnet addresses
    address constant POOL_MANAGER_MAINNET = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    address constant UNIVERSAL_ROUTER_MAINNET = 0x6fF5693b99212Da76ad316178A184AB56D299b43;

    struct DeploymentAddresses {
        address oracle;
        address router;
        address compound;
        address hook;
        address factory;
        address aaveAdapter;
        address morphoAdapter;
        address compoundAdapter;
    }

    function run() external {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");

        console.log("========================================");
        console.log("  YieldShift Deployment");
        console.log("========================================");
        console.log("Chain:", block.chainid);

        // Get network config
        (address pm, address ur) = _getNetworkConfig();

        // Deploy infrastructure
        DeploymentAddresses memory addrs = _deployInfrastructure(pk, pm);

        // Deploy hook
        (address hookAddr, bytes32 salt) = _deployHook(pk, pm, addrs);
        addrs.hook = hookAddr;

        // Deploy factory and configure
        addrs.factory = _deployFactoryAndConfigure(pk, pm, ur, addrs);

        // Print summary
        _printFinalSummary(addrs, salt);
    }

    function _getNetworkConfig() internal view returns (address pm, address ur) {
        if (block.chainid == 84532) {
            return (POOL_MANAGER_SEPOLIA, UNIVERSAL_ROUTER_SEPOLIA);
        } else if (block.chainid == 8453) {
            return (POOL_MANAGER_MAINNET, UNIVERSAL_ROUTER_MAINNET);
        }
        revert("Unsupported chain");
    }

    function _deployInfrastructure(uint256 pk, address pm) internal returns (DeploymentAddresses memory addrs) {
        vm.startBroadcast(pk);

        console.log("Deploying infrastructure...");
        addrs.oracle = address(new YieldOracle());
        addrs.router = address(new YieldRouter());
        addrs.compound = address(new YieldCompound(pm));

        console.log("Deploying adapters...");
        addrs.aaveAdapter = address(new AaveAdapter(AAVE_POOL_BASE));
        addrs.morphoAdapter = address(new MorphoAdapter());
        addrs.compoundAdapter = address(new CompoundAdapter());

        console.log("Registering adapters...");
        YieldRouter(addrs.router).registerAdapter(AAVE_POOL_BASE, addrs.aaveAdapter);
        YieldRouter(addrs.router).registerAdapter(MORPHO_BLUE_BASE, addrs.morphoAdapter);
        YieldRouter(addrs.router).registerAdapter(COMPOUND_COMET_USDC_BASE, addrs.compoundAdapter);

        console.log("Configuring oracle...");
        YieldOracle(addrs.oracle).addVault(AAVE_POOL_BASE, address(0), 3);
        YieldOracle(addrs.oracle).setAPY(AAVE_POOL_BASE, 600);
        YieldOracle(addrs.oracle).addVault(MORPHO_BLUE_BASE, address(0), 6);
        YieldOracle(addrs.oracle).setAPY(MORPHO_BLUE_BASE, 1200);
        YieldOracle(addrs.oracle).addVault(COMPOUND_COMET_USDC_BASE, address(0), 4);
        YieldOracle(addrs.oracle).setAPY(COMPOUND_COMET_USDC_BASE, 400);

        vm.stopBroadcast();
    }

    function _deployHook(uint256 pk, address pm, DeploymentAddresses memory addrs)
        internal
        returns (address hookAddr, bytes32 salt)
    {
        console.log("Mining hook address...");

        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory creationCode = type(YieldShiftHook).creationCode;
        bytes memory constructorArgs = abi.encode(
            IPoolManager(pm),
            addrs.oracle,
            addrs.router,
            addrs.compound
        );

        (hookAddr, salt) = HookMiner.find(CREATE2_DEPLOYER, flags, creationCode, constructorArgs);
        console.log("Found address:", hookAddr);

        vm.startBroadcast(pk);
        YieldShiftHook hook = new YieldShiftHook{salt: salt}(
            IPoolManager(pm),
            addrs.oracle,
            addrs.router,
            addrs.compound
        );
        require(address(hook) == hookAddr, "Address mismatch");
        vm.stopBroadcast();
    }

    function _deployFactoryAndConfigure(
        uint256 pk,
        address pm,
        address ur,
        DeploymentAddresses memory addrs
    ) internal returns (address) {
        vm.startBroadcast(pk);

        console.log("Deploying factory...");
        address factory = address(new YieldShiftFactory(pm, addrs.hook));

        console.log("Configuring authorizations...");
        YieldRouter(addrs.router).setAuthorizedCaller(addrs.hook, true);
        YieldCompound(payable(addrs.compound)).setAuthorizedCaller(addrs.hook, true);
        YieldCompound(payable(addrs.compound)).setSwapRouter(ur);

        vm.stopBroadcast();
        return factory;
    }

    function _printFinalSummary(DeploymentAddresses memory addrs, bytes32 salt) internal view {
        console.log("");
        console.log("========================================");
        console.log("  DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("Oracle:", addrs.oracle);
        console.log("Router:", addrs.router);
        console.log("Compound:", addrs.compound);
        console.log("Hook:", addrs.hook);
        console.log("Factory:", addrs.factory);
        console.log("Salt:", uint256(salt));
    }

}
