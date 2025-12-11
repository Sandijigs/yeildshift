// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

import {YieldOracle} from "../src/YieldOracle.sol";
import {YieldRouter} from "../src/YieldRouter.sol";
import {YieldCompound} from "../src/YieldCompound.sol";
import {YieldShiftHook} from "../src/YieldShiftHook.sol";
import {IYieldShiftHook} from "../src/interfaces/IYieldShiftHook.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";
import {MockVault} from "../test/mocks/MockVault.sol";

/// @title LocalDemo
/// @notice Complete local demonstration of YieldShift with Uniswap v4
contract LocalDemo is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Deployed contracts
    PoolManager public poolManager;
    YieldOracle public oracle;
    YieldRouter public router;
    YieldCompound public compound;
    YieldShiftHook public hook;

    // Test tokens
    MockERC20 public token0;
    MockERC20 public token1;
    MockERC20 public usdc;

    // Mock vaults
    MockVault public morphoVault;
    MockVault public aaveVault;
    MockVault public compoundVault;

    // Pool configuration
    PoolKey public poolKey;
    PoolId public poolId;

    // Test accounts (from Anvil)
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant USER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant USER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    uint256 constant DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() external {
        vm.startBroadcast(DEPLOYER_KEY);

        console.log("");
        console.log("==========================================================");
        console.log("  YieldShift Local Demo - Uniswap v4 Hook Integration");
        console.log("==========================================================");
        console.log("");

        // Step 1: Deploy Core Uniswap v4 Infrastructure
        console.log("STEP 1: Deploying Uniswap v4 PoolManager...");
        poolManager = new PoolManager(address(0)); // No initial governance
        console.log("  PoolManager deployed:", address(poolManager));
        console.log("");

        // Step 2: Deploy Test Tokens
        console.log("STEP 2: Deploying test tokens...");
        token0 = new MockERC20("Token A", "TKNA", 18);
        token1 = new MockERC20("Token B", "TKNB", 18);
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Ensure token0 < token1 (Uniswap requirement)
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }

        console.log("  Token0:", address(token0), token0.symbol());
        console.log("  Token1:", address(token1), token1.symbol());
        console.log("  USDC:", address(usdc));
        console.log("");

        // Step 3: Deploy YieldShift Infrastructure
        console.log("STEP 3: Deploying YieldShift contracts...");
        oracle = new YieldOracle();
        router = new YieldRouter(address(oracle));
        compound = new YieldCompound(payable(address(router)));

        console.log("  YieldOracle:", address(oracle));
        console.log("  YieldRouter:", address(router));
        console.log("  YieldCompound:", address(compound));
        console.log("");

        // Step 4: Deploy Mock Vaults
        console.log("STEP 4: Deploying mock yield vaults...");
        morphoVault = new MockVault(address(usdc), "Morpho Blue", 1200); // 12% APY
        aaveVault = new MockVault(address(usdc), "Aave v3", 600);        // 6% APY
        compoundVault = new MockVault(address(usdc), "Compound v3", 400); // 4% APY

        console.log("  Morpho Vault:", address(morphoVault), "- 12% APY");
        console.log("  Aave Vault:", address(aaveVault), "- 6% APY");
        console.log("  Compound Vault:", address(compoundVault), "- 4% APY");
        console.log("");

        // Step 5: Register Vaults in Oracle
        console.log("STEP 5: Registering vaults in YieldOracle...");
        oracle.addVault(address(morphoVault), address(0), 6);  // Medium risk
        oracle.addVault(address(aaveVault), address(0), 3);    // Low risk
        oracle.addVault(address(compoundVault), address(0), 4); // Medium risk

        oracle.updateAPY(address(morphoVault));
        oracle.updateAPY(address(aaveVault));
        oracle.updateAPY(address(compoundVault));

        console.log("  Vaults registered and APYs updated");
        console.log("");

        // Step 6: Deploy YieldShiftHook
        console.log("STEP 6: Deploying YieldShiftHook...");
        hook = new YieldShiftHook(
            poolManager,
            address(oracle),
            address(router),
            address(compound)
        );
        console.log("  YieldShiftHook:", address(hook));
        console.log("  Hook Permissions:", _getPermissionString());
        console.log("");

        // Step 7: Authorize Hook
        console.log("STEP 7: Authorizing hook in router...");
        router.setAuthorizedCaller(address(hook), true);
        console.log("  Hook authorized");
        console.log("");

        // Step 8: Create Pool with Hook
        console.log("STEP 8: Creating Uniswap v4 pool with YieldShiftHook...");

        poolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        poolId = poolKey.toId();

        uint160 sqrtPriceX96 = 79228162514264337593543950336; // Price = 1:1

        poolManager.initialize(poolKey, sqrtPriceX96);

        console.log("  Pool created!");
        console.log("  Pool ID:", uint256(PoolId.unwrap(poolId)));
        console.log("  Currency0:", Currency.unwrap(poolKey.currency0));
        console.log("  Currency1:", Currency.unwrap(poolKey.currency1));
        console.log("  Fee:", poolKey.fee);
        console.log("");

        // Step 9: Configure Hook for Pool
        console.log("STEP 9: Configuring YieldShift parameters for pool...");

        IYieldShiftHook.YieldConfig memory config = IYieldShiftHook.YieldConfig({
            shiftPercentage: 30,      // 30% of idle capital
            minAPYThreshold: 500,     // 5% minimum APY
            harvestFrequency: 5,      // Harvest every 5 swaps
            riskTolerance: 7,         // Accept medium-high risk
            isPaused: false,
            admin: DEPLOYER
        });

        hook.configurePool(poolKey, config);

        console.log("  Configuration:");
        console.log("    Shift Percentage: 30%");
        console.log("    Min APY Threshold: 5%");
        console.log("    Harvest Frequency: Every 5 swaps");
        console.log("    Risk Tolerance: 7/10");
        console.log("");

        // Step 10: Mint tokens to users
        console.log("STEP 10: Minting tokens to test users...");
        token0.mint(USER1, 1000 * 10**18);
        token1.mint(USER1, 1000 * 10**18);
        token0.mint(USER2, 1000 * 10**18);
        token1.mint(USER2, 1000 * 10**18);
        usdc.mint(address(poolManager), 100000 * 10**6); // Fund pool for yield farming

        console.log("  USER1:", USER1);
        console.log("    Token0 balance:", token0.balanceOf(USER1) / 10**18, token0.symbol());
        console.log("    Token1 balance:", token1.balanceOf(USER1) / 10**18, token1.symbol());
        console.log("");
        console.log("  USER2:", USER2);
        console.log("    Token0 balance:", token0.balanceOf(USER2) / 10**18, token0.symbol());
        console.log("    Token1 balance:", token1.balanceOf(USER2) / 10**18, token1.symbol());
        console.log("");

        vm.stopBroadcast();

        // Step 11: Summary
        console.log("==========================================================");
        console.log("  DEPLOYMENT COMPLETE!");
        console.log("==========================================================");
        console.log("");
        console.log("Contract Addresses:");
        console.log("  PoolManager:     ", address(poolManager));
        console.log("  YieldOracle:     ", address(oracle));
        console.log("  YieldRouter:     ", address(router));
        console.log("  YieldShiftHook:  ", address(hook));
        console.log("  Token0:          ", address(token0));
        console.log("  Token1:          ", address(token1));
        console.log("");
        console.log("Pool Details:");
        console.log("  Pool ID:          0x", _bytes32ToString(PoolId.unwrap(poolId)));
        console.log("  Fee:              0.3%");
        console.log("  Hook Enabled:     YES");
        console.log("");
        console.log("Next Steps:");
        console.log("  1. Run: forge script script/LocalSwapDemo.s.sol --rpc-url localhost");
        console.log("  2. This will execute swaps and trigger the hooks");
        console.log("  3. Watch the YieldShifted and RewardsHarvested events!");
        console.log("");
        console.log("==========================================================");
    }

    function _getPermissionString() internal view returns (string memory) {
        Hooks.Permissions memory perms = hook.getHookPermissions();
        if (perms.beforeSwap && perms.afterSwap) {
            return "beforeSwap + afterSwap";
        }
        return "unknown";
    }

    function _bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
