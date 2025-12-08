// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {YieldOracle} from "../src/YieldOracle.sol";
import {YieldRouter} from "../src/YieldRouter.sol";
import {YieldCompound} from "../src/YieldCompound.sol";
import {MorphoAdapter} from "../src/adapters/MorphoAdapter.sol";
import {MockERC4626Vault} from "./mocks/MockERC4626Vault.sol";

/// @title MockERC20
/// @notice Simple ERC20 token for testing
contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/// @title BaseTest
/// @notice Base test contract with common setup for all YieldShift tests
abstract contract BaseTest is Test {
    // ============ Test Tokens ============
    MockERC20 public usdc;
    MockERC20 public weth;
    MockERC20 public dai;

    // ============ Mock Vaults ============
    MockERC4626Vault public morphoVault;
    MockERC4626Vault public aaveVault;
    MockERC4626Vault public compoundVault;

    // ============ Core Contracts ============
    YieldOracle public yieldOracle;
    YieldRouter public yieldRouter;
    YieldCompound public yieldCompound;
    MorphoAdapter public morphoAdapter;

    // ============ Test Accounts ============
    address public deployer;
    address public lpProvider;
    address public swapper;
    address public admin;

    // ============ Constants ============
    uint256 public constant INITIAL_BALANCE = 1_000_000e18;
    uint256 public constant USDC_INITIAL = 1_000_000e6;

    // ============ Setup ============

    function setUp() public virtual {
        // Create test accounts
        deployer = makeAddr("deployer");
        lpProvider = makeAddr("lpProvider");
        swapper = makeAddr("swapper");
        admin = makeAddr("admin");

        vm.startPrank(deployer);

        // Deploy mock tokens
        usdc = new MockERC20("USD Coin", "USDC", 6);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        dai = new MockERC20("Dai Stablecoin", "DAI", 18);

        // Mint tokens to test accounts
        usdc.mint(lpProvider, USDC_INITIAL);
        usdc.mint(swapper, USDC_INITIAL);
        usdc.mint(deployer, USDC_INITIAL);
        
        weth.mint(lpProvider, INITIAL_BALANCE);
        weth.mint(swapper, INITIAL_BALANCE);
        weth.mint(deployer, INITIAL_BALANCE);

        dai.mint(lpProvider, INITIAL_BALANCE);
        dai.mint(swapper, INITIAL_BALANCE);

        // Deploy mock vaults with different APYs
        morphoVault = new MockERC4626Vault(
            address(usdc),
            "Morpho USDC Vault",
            "mUSDC",
            1200 // 12% APY
        );

        aaveVault = new MockERC4626Vault(
            address(usdc),
            "Aave USDC Vault", 
            "aUSDC",
            600 // 6% APY
        );

        compoundVault = new MockERC4626Vault(
            address(usdc),
            "Compound USDC Vault",
            "cUSDC",
            400 // 4% APY
        );

        // Deploy core contracts
        yieldOracle = new YieldOracle();
        yieldRouter = new YieldRouter();
        
        // For YieldCompound, we need a mock pool manager
        // Using address(0) for now since we're not testing full v4 integration
        yieldCompound = new YieldCompound(address(1)); // Placeholder

        // Deploy adapter
        morphoAdapter = new MorphoAdapter();

        vm.stopPrank();
    }

    // ============ Helper Functions ============

    /// @notice Setup vault in oracle and router
    function _setupVault(
        address vault,
        address adapter,
        uint256 riskScore
    ) internal {
        vm.startPrank(deployer);
        
        // Add to oracle
        yieldOracle.addVault(vault, address(0), riskScore);
        
        // Register adapter in router
        yieldRouter.registerAdapter(vault, adapter);
        
        vm.stopPrank();
    }

    /// @notice Approve tokens for spending
    function _approveTokens(
        address token,
        address spender,
        address owner,
        uint256 amount
    ) internal {
        vm.prank(owner);
        MockERC20(token).approve(spender, amount);
    }

    /// @notice Get token balance
    function _getBalance(address token, address account) internal view returns (uint256) {
        return MockERC20(token).balanceOf(account);
    }

    /// @notice Fast forward time
    function _skipTime(uint256 seconds_) internal {
        skip(seconds_);
    }

    /// @notice Create labeled address
    function _createUser(string memory label) internal returns (address) {
        return makeAddr(label);
    }
}
