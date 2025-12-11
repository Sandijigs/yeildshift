// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {YieldShiftHook} from "../src/YieldShiftHook.sol";
import {YieldShiftFactory} from "../src/YieldShiftFactory.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

/// @title DeployHookWithCREATE2
/// @notice Deploys YieldShiftHook using CREATE2 with address mining
/// @dev This script continues from where DeployBase.s.sol left off
contract DeployHookWithCREATE2 is Script {

    // CREATE2 Deployer (same address across all chains)
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // Uniswap V4 PoolManager addresses
    address constant POOL_MANAGER_SEPOLIA = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    address constant POOL_MANAGER_MAINNET = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    address constant UNIVERSAL_ROUTER_SEPOLIA = 0x492E6456D9528771018DeB9E87ef7750EF184104;
    address constant UNIVERSAL_ROUTER_MAINNET = 0x6fF5693b99212Da76ad316178A184AB56D299b43;

    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load deployed addresses from previous step
        address yieldOracle = vm.envAddress("YIELD_ORACLE_ADDRESS");
        address yieldRouter = vm.envAddress("YIELD_ROUTER_ADDRESS");
        address yieldCompound = vm.envAddress("YIELD_COMPOUND_ADDRESS");

        // Auto-detect network
        address poolManager;
        address universalRouter;
        if (block.chainid == 84532) {
            poolManager = POOL_MANAGER_SEPOLIA;
            universalRouter = UNIVERSAL_ROUTER_SEPOLIA;
        } else if (block.chainid == 8453) {
            poolManager = POOL_MANAGER_MAINNET;
            universalRouter = UNIVERSAL_ROUTER_MAINNET;
        } else {
            revert("Unsupported chain ID");
        }

        console.log("=== YieldShift Hook Deployment (CREATE2) ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Pool Manager:", poolManager);
        console.log("");
        console.log("Using deployed infrastructure:");
        console.log("  YieldOracle:", yieldOracle);
        console.log("  YieldRouter:", yieldRouter);
        console.log("  YieldCompound:", yieldCompound);
        console.log("");

        // Step 1: Mine for valid hook address
        console.log("Step 1: Mining for valid hook address...");
        console.log("This may take 30-60 seconds...");

        // Calculate hook permissions
        uint160 permissions = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        console.log("Required permissions (flags):", permissions);

        // Prepare creation code
        bytes memory creationCode = type(YieldShiftHook).creationCode;
        bytes memory constructorArgs = abi.encode(
            IPoolManager(poolManager),
            yieldOracle,
            yieldRouter,
            yieldCompound
        );

        // Mine for salt
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            permissions,
            creationCode,
            constructorArgs
        );

        console.log("Found valid address!");
        console.log("  Hook Address:", hookAddress);
        console.log("  Salt:", uint256(salt));
        console.log("");

        // Step 2: Deploy hook using CREATE2
        console.log("Step 2: Deploying hook...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy using CREATE2 with the found salt
        YieldShiftHook hook = new YieldShiftHook{salt: salt}(
            IPoolManager(poolManager),
            yieldOracle,
            yieldRouter,
            yieldCompound
        );

        require(address(hook) == hookAddress, "Hook address mismatch");
        console.log("  YieldShiftHook deployed:", address(hook));

        // Step 3: Deploy factory
        console.log("");
        console.log("Step 3: Deploying factory...");

        YieldShiftFactory factory = new YieldShiftFactory(
            poolManager,
            address(hook)
        );
        console.log("  YieldShiftFactory deployed:", address(factory));

        // Step 4: Configure authorizations
        console.log("");
        console.log("Step 4: Configuring authorizations...");

        // Authorize hook in router
        (bool success1, ) = yieldRouter.call(
            abi.encodeWithSignature("setAuthorizedCaller(address,bool)", address(hook), true)
        );
        require(success1, "Failed to authorize hook in router");
        console.log("  Authorized hook in YieldRouter");

        // Authorize hook in compounder
        (bool success2, ) = yieldCompound.call(
            abi.encodeWithSignature("setAuthorizedCaller(address,bool)", address(hook), true)
        );
        require(success2, "Failed to authorize hook in compounder");
        console.log("  Authorized hook in YieldCompound");

        // Set Universal Router for swaps
        (bool success3, ) = yieldCompound.call(
            abi.encodeWithSignature("setSwapRouter(address)", universalRouter)
        );
        require(success3, "Failed to set swap router");
        console.log("  Configured Universal Router:", universalRouter);

        vm.stopBroadcast();

        // Print summary
        _printSummary(address(hook), address(factory), salt);
    }

    function _printSummary(address hook, address factory, bytes32 salt) internal pure {
        console.log("");
        console.log("========================================");
        console.log("    DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("YieldShiftHook:", hook);
        console.log("YieldShiftFactory:", factory);
        console.log("Salt:", uint256(salt));
        console.log("");
    }
}
