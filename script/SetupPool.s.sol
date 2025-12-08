// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
import {YieldShiftFactory} from "../src/YieldShiftFactory.sol";
import {IYieldShiftHook} from "../src/interfaces/IYieldShiftHook.sol";

/// @title SetupPool
/// @notice Script to create initial YieldShift-enabled pools
contract SetupPool is Script {
    
    // Token addresses on Base
    address constant WETH_BASE = 0x4200000000000000000000000000000000000006;
    address constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    
    // Initial sqrt price for ETH/USDC pool
    // Assuming ETH = $2000 USDC
    // sqrtPriceX96 = sqrt(2000) * 2^96 = ~3.54e30
    uint160 constant INITIAL_SQRT_PRICE = 3543191142285914205922034323214;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Get factory address from env
        address factoryAddress = vm.envAddress("YIELD_SHIFT_FACTORY_ADDRESS");
        YieldShiftFactory factory = YieldShiftFactory(factoryAddress);
        
        console.log("=== YieldShift Pool Setup ===");
        console.log("Deployer:", deployer);
        console.log("Factory:", factoryAddress);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ============ Create ETH/USDC Pool ============
        console.log("Creating ETH/USDC 0.3% pool...");
        
        // Sort currencies (ETH is address(0), USDC is higher)
        Currency currency0 = Currency.wrap(address(0)); // Native ETH
        Currency currency1 = Currency.wrap(USDC_BASE);
        
        // Ensure correct ordering
        if (Currency.unwrap(currency0) > Currency.unwrap(currency1)) {
            (currency0, currency1) = (currency1, currency0);
        }
        
        // Pool configuration
        uint24 fee = 3000; // 0.3%
        int24 tickSpacing = 60;
        
        // YieldShift configuration
        IYieldShiftHook.YieldConfig memory config = IYieldShiftHook.YieldConfig({
            shiftPercentage: 30,      // 30% of idle capital
            minAPYThreshold: 500,     // 5% minimum APY
            harvestFrequency: 10,     // Harvest every 10 swaps
            riskTolerance: 7,         // Accept medium risk
            isPaused: false,
            admin: deployer
        });
        
        // Deploy pool
        PoolId poolId = factory.deployPoolWithConfig(
            currency0,
            currency1,
            fee,
            tickSpacing,
            INITIAL_SQRT_PRICE,
            config
        );
        
        console.log("Pool created!");
        console.log("  Pool ID:", uint256(PoolId.unwrap(poolId)));
        console.log("  Fee:", fee);
        console.log("  Tick spacing:", tickSpacing);
        console.log("  Shift percentage:", config.shiftPercentage, "%");
        console.log("  Min APY threshold:", config.minAPYThreshold, "bps");
        console.log("  Risk tolerance:", config.riskTolerance);

        vm.stopBroadcast();

        // ============ Summary ============
        console.log("");
        console.log("=== Pool Setup Complete ===");
        console.log("");
        console.log("ETH/USDC 0.3% pool is ready for:");
        console.log("  - Liquidity provision");
        console.log("  - Swapping");
        console.log("  - Automatic yield optimization");
        console.log("");
        console.log("The hook will automatically:");
        console.log("  1. Route 30% of idle USDC to best yield source");
        console.log("  2. Harvest rewards every 10 swaps");
        console.log("  3. Compound rewards back to pool");
    }
}

/// @title SetupTestPools
/// @notice Script to create test pools with mock tokens
contract SetupTestPools is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        
        console.log("=== Test Pool Setup ===");
        console.log("This script creates pools with test tokens");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // For testing, we would:
        // 1. Deploy mock tokens
        // 2. Create pools with those tokens
        // 3. Add initial liquidity
        
        console.log("Test pools would be created here...");
        console.log("Use DeployBase.s.sol for mainnet/testnet deployments");
        
        vm.stopBroadcast();
    }
}
