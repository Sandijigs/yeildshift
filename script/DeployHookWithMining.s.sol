// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {YieldShiftHook} from "../src/YieldShiftHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

/// @title DeployHookWithMining
/// @notice Mines for a valid hook address and deploys YieldShiftHook
/// @dev Uniswap V4 requires hook addresses to have specific permission flags
contract DeployHookWithMining is Script {

    // Required addresses from .env
    address constant POOL_MANAGER_SEPOLIA = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    address constant POOL_MANAGER_MAINNET = 0x498581fF718922c3f8e6A244956aF099B2652b2b;

    /// @notice Deploy hook with address mining
    /// @param poolManager PoolManager address
    /// @param yieldOracle YieldOracle address
    /// @param yieldRouter YieldRouter address
    /// @param yieldCompound YieldCompound address
    /// @return hook The deployed hook address
    /// @return salt The salt used for CREATE2
    function deployWithMining(
        address poolManager,
        address yieldOracle,
        address yieldRouter,
        address yieldCompound
    ) public returns (YieldShiftHook hook, bytes32 salt) {

        // Get hook permissions
        uint160 permissions = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        console.log("Mining for valid hook address with permissions:", permissions);
        console.log("This may take a moment...");

        // Get deployer address
        address deployer = msg.sender;

        // Mine for valid address
        bytes memory creationCode = type(YieldShiftHook).creationCode;
        bytes memory constructorArgs = abi.encode(
            poolManager,
            yieldOracle,
            yieldRouter,
            yieldCompound
        );
        bytes memory initCode = abi.encodePacked(creationCode, constructorArgs);
        bytes32 initCodeHash = keccak256(initCode);

        // Try different salts
        uint256 attempts = 0;
        uint256 maxAttempts = 100000;

        for (uint256 i = 0; i < maxAttempts; i++) {
            salt = keccak256(abi.encodePacked("YieldShiftHook", i));

            // Calculate CREATE2 address
            address predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
                bytes1(0xff),
                deployer,
                salt,
                initCodeHash
            )))));

            attempts++;

            // Check if address has correct permissions
            uint160 addressFlags = uint160(predictedAddress) & Hooks.ALL_HOOK_MASK;

            if (addressFlags == permissions) {
                console.log("Found valid address after", attempts, "attempts!");
                console.log("Predicted address:", predictedAddress);
                console.log("Salt:", uint256(salt));

                // Deploy using CREATE2
                hook = new YieldShiftHook{salt: salt}(
                    IPoolManager(poolManager),
                    yieldOracle,
                    yieldRouter,
                    yieldCompound
                );

                require(address(hook) == predictedAddress, "Address mismatch");
                console.log("Hook deployed at:", address(hook));

                return (hook, salt);
            }
        }

        revert("Could not find valid hook address");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Get addresses from environment or previous deployment
        address yieldOracle = vm.envAddress("YIELD_ORACLE_ADDRESS");
        address yieldRouter = vm.envAddress("YIELD_ROUTER_ADDRESS");
        address yieldCompound = vm.envAddress("YIELD_COMPOUND_ADDRESS");

        // Auto-detect pool manager
        address poolManager;
        if (block.chainid == 84532) {
            poolManager = POOL_MANAGER_SEPOLIA;
        } else if (block.chainid == 8453) {
            poolManager = POOL_MANAGER_MAINNET;
        } else {
            revert("Unsupported chain ID");
        }

        console.log("=== YieldShift Hook Mining & Deployment ===");
        console.log("Chain ID:", block.chainid);
        console.log("Pool Manager:", poolManager);
        console.log("YieldOracle:", yieldOracle);
        console.log("YieldRouter:", yieldRouter);
        console.log("YieldCompound:", yieldCompound);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        (YieldShiftHook hook, bytes32 salt) = deployWithMining(
            poolManager,
            yieldOracle,
            yieldRouter,
            yieldCompound
        );

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("  HOOK DEPLOYMENT SUCCESSFUL!");
        console.log("========================================");
        console.log("YieldShiftHook:", address(hook));
        console.log("Salt:", uint256(salt));
        console.log("");
        console.log("Add to your .env:");
        console.log("YIELD_SHIFT_HOOK_ADDRESS=", address(hook));
    }
}
