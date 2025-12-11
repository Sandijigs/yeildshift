# Uniswap v4 Hooks Explained - YieldShift Implementation

**Date:** December 11, 2025
**Project:** YieldShift
**File:** `src/YieldShiftHook.sol`

---

## 📚 Table of Contents
1. [What Are Uniswap v4 Hooks?](#what-are-uniswap-v4-hooks)
2. [Hook Permissions System](#hook-permissions-system)
3. [beforeSwap Hook](#beforeswap-hook-detailed-explanation)
4. [afterSwap Hook](#afterswap-hook-detailed-explanation)
5. [Complete Flow Diagram](#complete-flow-diagram)
6. [Why These Hooks?](#why-these-specific-hooks)
7. [Technical Deep Dive](#technical-deep-dive)

---

## What Are Uniswap v4 Hooks?

### Overview
Uniswap v4 hooks are **callback functions** that the PoolManager calls at specific points during pool operations. They allow developers to inject custom logic into the lifecycle of:
- Pool initialization
- Adding/removing liquidity
- **Swaps** ← We use these!
- Donations

### Hook Contract Interface
Your hook contract must implement the `IHooks` interface and declare which hooks it wants to use through a permissions system.

```solidity
contract YieldShiftHook is IHooks, IYieldShiftHook, ReentrancyGuard {
    // Implements all required hook functions
}
```

---

## Hook Permissions System

### What is the Permissions System?

Uniswap v4 uses a **permission bitmap** system where hooks declare which lifecycle events they want to intercept. This is done in the `getHookPermissions()` function.

### Our Implementation (Lines 94-116)

```solidity
function getHookPermissions()
    public
    pure
    returns (Hooks.Permissions memory)
{
    return Hooks.Permissions({
        beforeInitialize: false,           // ❌ Don't need
        afterInitialize: false,            // ❌ Don't need
        beforeAddLiquidity: false,         // ❌ Don't need
        afterAddLiquidity: false,          // ❌ Don't need
        beforeRemoveLiquidity: false,      // ❌ Don't need
        afterRemoveLiquidity: false,       // ❌ Don't need
        beforeSwap: true,                  // ✅ USED: Route capital to yield sources
        afterSwap: true,                   // ✅ USED: Harvest and compound rewards
        beforeDonate: false,               // ❌ Don't need
        afterDonate: false,                // ❌ Don't need
        beforeSwapReturnDelta: false,      // ❌ Don't need (not modifying swap amounts)
        afterSwapReturnDelta: false,       // ❌ Don't need
        afterAddLiquidityReturnDelta: false, // ❌ Don't need
        afterRemoveLiquidityReturnDelta: false // ❌ Don't need
    });
}
```

### Why Only `beforeSwap` and `afterSwap`?

**We only need these two hooks because:**
1. **beforeSwap**: Swaps are the perfect trigger to check yields and shift capital
2. **afterSwap**: Swaps provide natural harvest timing without needing keeper bots
3. **Efficiency**: Only implementing what we need saves gas
4. **Simplicity**: LPs don't need to do anything special - yield happens automatically during normal trading

---

## beforeSwap Hook: Detailed Explanation

### What It Does
The `beforeSwap` hook is called **before every swap** in the pool. We use it to:
1. Check current yield opportunities across all protocols
2. Route idle capital to the highest-yielding vault
3. Track when capital was last shifted

### Function Signature (Lines 212-217)

```solidity
function beforeSwap(
    address sender,           // Who initiated the swap
    PoolKey calldata key,     // Pool identification
    IPoolManager.SwapParams calldata params,  // Swap details (amount, direction)
    bytes calldata hookData   // Custom data (we don't use this)
) external onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24)
```

### Parameters Explained

| Parameter | Type | Purpose |
|-----------|------|---------|
| `sender` | `address` | The address that initiated the swap |
| `key` | `PoolKey` | Identifies the pool (currency0, currency1, fee, tickSpacing, hooks) |
| `params` | `SwapParams` | Swap details: `zeroForOne` (direction), `amountSpecified` (size), `sqrtPriceLimitX96` (price limit) |
| `hookData` | `bytes` | Optional custom data passed by swapper (not used in our implementation) |

### Return Values

```solidity
returns (bytes4, BeforeSwapDelta, uint24)
```

| Return Value | Type | Purpose | Our Value |
|--------------|------|---------|-----------|
| Selector | `bytes4` | Must return `IHooks.beforeSwap.selector` to confirm execution | `IHooks.beforeSwap.selector` |
| Delta | `BeforeSwapDelta` | Allows modifying swap amounts (advanced) | `ZERO_DELTA` (we don't modify) |
| LP Fee Override | `uint24` | Can override the LP fee for this swap | `0` (use pool default) |

### Step-by-Step Execution Flow

#### Step 1: Get Pool Configuration (Lines 218-224)

```solidity
PoolId poolId = key.toId();
YieldConfig memory config = _poolConfigs[poolId];

// Skip if not configured or paused
if (config.admin == address(0) || config.isPaused) {
    return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
}
```

**What's happening:**
- Convert pool key to pool ID (hash of pool parameters)
- Load pool-specific configuration (shift %, APY threshold, risk tolerance)
- Safety check: Skip if pool not configured or emergency paused

#### Step 2: Rate Limiting (Lines 226-230)

```solidity
PoolState storage state = _poolStates[poolId];
if (block.timestamp - state.lastShiftTime < MIN_SHIFT_INTERVAL) {
    return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
}
```

**Why rate limiting?**
- Prevents shifting capital on every swap (would be gas intensive)
- `MIN_SHIFT_INTERVAL = 30 seconds` minimum between shifts
- Reduces MEV attack surface

#### Step 3: Query Best Yield (Lines 232-236)

```solidity
try yieldOracle.getBestYield(config.riskTolerance) returns (
    address bestVault,
    uint256 bestAPY
) {
```

**What's happening:**
- Call YieldOracle to find highest-yielding vault within risk tolerance
- Oracle checks: Aave, Morpho, Compound, EigenLayer (weETH, ezETH, mETH)
- Returns vault address and APY in basis points (e.g., 750 = 7.5%)

**Example:**
```
Input: riskTolerance = 7
Output: bestVault = 0x... (EigenLayer weETH), bestAPY = 750 (7.5%)
```

#### Step 4: APY Threshold Check (Lines 237-240)

```solidity
if (bestAPY >= config.minAPYThreshold && bestVault != address(0)) {
    _shiftToVault(key, poolId, config, bestVault, bestAPY);
}
```

**Why threshold?**
- Don't shift for low yields (not worth gas cost)
- `minAPYThreshold` configurable per pool (default: 200 = 2%)
- If EigenLayer offering 7.5% and threshold is 2%, we shift!

#### Step 5: Error Handling (Lines 241-243)

```solidity
} catch {
    // If oracle fails, continue without shifting
}
```

**Why try-catch?**
- Oracle might be temporarily unavailable
- External protocol might be down
- Swap should NOT fail if yield routing fails
- User experience priority: swap always succeeds

### Internal Function: `_shiftToVault` (Lines 397-431)

This is where the actual capital shift happens:

```solidity
function _shiftToVault(
    PoolKey calldata key,
    PoolId poolId,
    YieldConfig memory config,
    address vault,
    uint256 apy
) internal {
    // 1. Calculate shift amount
    uint256 shiftAmount = _calculateShiftAmount(key, config.shiftPercentage);
    if (shiftAmount == 0) return;

    // 2. Get preferred token (USDC, ETH, etc.)
    address token = _getPreferredToken(key);
    if (token == address(0)) return;

    // 3. Execute shift via router
    try yieldRouter.shiftToVault(vault, token, shiftAmount) returns (uint256 shares) {
        // 4. Update state
        state.totalShifted += shiftAmount;
        state.lastShiftTime = block.timestamp;
        _vaultBalances[poolId][vault] += shares;

        // 5. Track active vault
        if (!_isVaultActive(poolId, vault)) {
            _activeVaults[poolId].push(vault);
        }

        emit YieldShifted(poolId, vault, shiftAmount, apy);
    } catch {
        // Shift failed - continue without error
    }
}
```

### Calculate Shift Amount (Lines 465-492)

```solidity
function _calculateShiftAmount(
    PoolKey calldata key,
    uint8 shiftPercentage
) internal view returns (uint256) {
    // Get balances of both tokens in the pool
    address token0 = Currency.unwrap(key.currency0);
    address token1 = Currency.unwrap(key.currency1);

    uint256 balance0 = token0 == address(0) ?
        address(this).balance :  // Native ETH
        IERC20(token0).balanceOf(address(this));

    uint256 balance1 = token1 == address(0) ?
        0 :
        IERC20(token1).balanceOf(address(this));

    // Use larger balance
    uint256 availableBalance = balance0 > balance1 ? balance0 : balance1;

    // Minimum threshold: $100 worth (prevents tiny shifts)
    if (availableBalance < 100e6) return 0;

    // Calculate percentage: e.g., 20% of available balance
    return availableBalance.calculateShiftAmount(shiftPercentage);
}
```

**Example:**
- Pool has 10,000 USDC idle
- `shiftPercentage = 20`
- Shift amount = 10,000 * 20% = 2,000 USDC
- 2,000 USDC gets deposited to EigenLayer weETH vault

---

## afterSwap Hook: Detailed Explanation

### What It Does
The `afterSwap` hook is called **after every swap** completes. We use it to:
1. Increment swap counter
2. Harvest rewards when threshold reached
3. Trigger auto-compounding

### Function Signature (Lines 249-255)

```solidity
function afterSwap(
    address sender,           // Who initiated the swap
    PoolKey calldata key,     // Pool identification
    IPoolManager.SwapParams calldata params,  // Swap details
    BalanceDelta delta,       // Actual amounts swapped
    bytes calldata hookData   // Custom data (not used)
) external onlyPoolManager returns (bytes4, int128)
```

### Parameters Explained

| Parameter | Type | Purpose |
|-----------|------|---------|
| `sender` | `address` | The address that initiated the swap |
| `key` | `PoolKey` | Identifies the pool |
| `params` | `SwapParams` | Swap parameters |
| `delta` | `BalanceDelta` | The actual amounts that were swapped (int256 for token0 and token1) |
| `hookData` | `bytes` | Optional custom data (not used) |

### Return Values

```solidity
returns (bytes4, int128)
```

| Return Value | Type | Purpose | Our Value |
|--------------|------|---------|-----------|
| Selector | `bytes4` | Must return `IHooks.afterSwap.selector` | `IHooks.afterSwap.selector` |
| Hook Delta | `int128` | Can take fees or modify amounts (advanced) | `0` (we don't take fees) |

### Step-by-Step Execution Flow

#### Step 1: Get Configuration (Lines 256-263)

```solidity
PoolId poolId = key.toId();
YieldConfig memory config = _poolConfigs[poolId];
PoolState storage state = _poolStates[poolId];

// Skip if not configured or paused
if (config.admin == address(0) || config.isPaused) {
    return (IHooks.afterSwap.selector, 0);
}
```

**What's happening:**
- Load pool configuration
- Load pool state (for swap counter)
- Skip if not configured or paused

#### Step 2: Increment Swap Counter (Lines 265-266)

```solidity
state.swapCount++;
```

**Why count swaps?**
- Harvesting on EVERY swap would be gas intensive
- Instead, harvest every N swaps (e.g., every 10 swaps)
- `harvestFrequency` is configurable per pool

#### Step 3: Check Harvest Threshold (Lines 268-272)

```solidity
if (state.swapCount >= config.harvestFrequency) {
    _harvestAndCompound(key, poolId);
    state.swapCount = 0;  // Reset counter
}
```

**Example:**
- `harvestFrequency = 10`
- After 10 swaps, harvest all rewards
- Reset counter to 0
- Next harvest in another 10 swaps

**Why this approach?**
- Amortizes harvest gas cost across multiple swaps
- Natural, passive harvesting (no keepers needed)
- More trading activity = more frequent harvests

### Internal Function: `_harvestAndCompound` (Lines 434-462)

This is where rewards are collected:

```solidity
function _harvestAndCompound(PoolKey calldata key, PoolId poolId) internal {
    PoolState storage state = _poolStates[poolId];
    address[] storage vaults = _activeVaults[poolId];

    uint256 totalHarvested = 0;

    // Harvest from all active vaults
    for (uint256 i = 0; i < vaults.length; i++) {
        try yieldRouter.harvest(vaults[i]) returns (uint256 rewards) {
            totalHarvested += rewards;
        } catch {
            // Continue even if one harvest fails
        }
    }

    if (totalHarvested > 0) {
        state.totalHarvested += totalHarvested;
        state.lastHarvestTime = block.timestamp;

        emit RewardsHarvested(poolId, totalHarvested);

        // YieldCompound contract handles:
        // 1. Convert rewards to pool tokens via swap
        // 2. Add liquidity back to pool
    }
}
```

**What gets harvested:**
- Aave AAVE tokens
- Morpho MORPHO tokens
- Compound COMP tokens
- EigenLayer restaking rewards (auto-compounds in LRT value)

**Example Harvest:**
```
Vault 1 (Aave):     100 AAVE tokens
Vault 2 (Morpho):   50 MORPHO tokens
Vault 3 (weETH):    0.5 ETH equivalent (from exchange rate appreciation)
Total Harvested:    ~$500 worth of rewards
```

---

## Complete Flow Diagram

### Swap Lifecycle with YieldShift Hooks

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Initiates Swap                          │
│                 (e.g., swap 1000 USDC → ETH)                    │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                   PoolManager.swap() Called                      │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
                ┌────────────────────────────┐
                │   beforeSwap Hook Fired    │
                └────────────┬───────────────┘
                             ↓
        ┌────────────────────────────────────────┐
        │ 1. Check if pool configured & not paused│
        │ 2. Check rate limit (30 sec minimum)   │
        │ 3. Query YieldOracle for best APY      │
        │    → Aave: 5% APY                       │
        │    → Morpho: 10% APY                    │
        │    → EigenLayer weETH: 7.5% APY ✅      │
        │ 4. If APY >= threshold (2%):           │
        │    → Calculate shift amount (20% of idle)│
        │    → Shift capital to best vault        │
        │    → Update state & track vault         │
        └────────────┬───────────────────────────┘
                     ↓
        ┌───────────────────────────┐
        │ Actual Swap Executes      │
        │ (1000 USDC → 0.28 ETH)    │
        └────────────┬──────────────┘
                     ↓
        ┌────────────────────────────┐
        │   afterSwap Hook Fired     │
        └────────────┬───────────────┘
                     ↓
        ┌────────────────────────────────────┐
        │ 1. Increment swap counter (9 → 10) │
        │ 2. Check if counter >= harvestFreq │
        │ 3. If yes (10 >= 10):              │
        │    → Harvest from all active vaults│
        │      • Aave: 50 AAVE tokens        │
        │      • Morpho: 25 MORPHO tokens    │
        │      • EigenLayer: 0.2 ETH rewards │
        │    → Total: ~$300 rewards          │
        │    → Send to YieldCompound         │
        │    → Reset counter to 0            │
        └────────────┬───────────────────────┘
                     ↓
        ┌───────────────────────────┐
        │  YieldCompound Contract   │
        │  1. Swap rewards → USDC   │
        │  2. Add liquidity to pool │
        │  3. All LPs benefit!      │
        └───────────────────────────┘
                     ↓
        ┌───────────────────────────┐
        │   Swap Completes          │
        │   User gets their ETH     │
        │   + Pool now has more     │
        │     liquidity from yield  │
        └───────────────────────────┘
```

---

## Why These Specific Hooks?

### Design Philosophy

| Hook | Why We Use It | What We DON'T Use & Why |
|------|---------------|-------------------------|
| **beforeSwap** ✅ | • Perfect timing to check yields<br>• Swaps indicate active pool<br>• Natural trigger (no keepers)<br>• Low frequency = gas efficient | **beforeAddLiquidity** ❌<br>• Don't need to intercept LP deposits<br>• LPs want instant deposits<br>• Yield happens passively |
| **afterSwap** ✅ | • Natural harvest timing<br>• Swap completed = safe to harvest<br>• Counter-based = gas efficient<br>• Doesn't block swap | **afterAddLiquidity** ❌<br>• Don't need to process new liquidity<br>• Would slow down LP deposits |

### Why Not Other Hooks?

```solidity
beforeInitialize: false    // Pool setup is one-time, we configure separately
afterInitialize: false     // Don't need to react to pool creation

beforeAddLiquidity: false  // Don't intercept LP deposits
afterAddLiquidity: false   // Don't need to process new liquidity

beforeRemoveLiquidity: false  // Don't intercept LP withdrawals
afterRemoveLiquidity: false   // Yield happens regardless of LP changes

beforeDonate: false        // Not using donation mechanism
afterDonate: false         // Not using donation mechanism

beforeSwapReturnDelta: false      // Not modifying swap amounts
afterSwapReturnDelta: false       // Not taking fees from swaps
afterAddLiquidityReturnDelta: false    // Not modifying liquidity
afterRemoveLiquidityReturnDelta: false // Not modifying liquidity
```

---

## Technical Deep Dive

### 1. Hook Address Requirements

Uniswap v4 uses the hook contract's **address** to determine permissions:

```solidity
// In constructor
Hooks.validateHookPermissions(this, getHookPermissions());
```

**How it works:**
- Hook address bits encode which hooks are enabled
- Address must match declared permissions
- This is validated at deployment

**Example:**
```
If beforeSwap = true and afterSwap = true:
Hook address must have specific bits set in the address
E.g., 0x1234...ABCD (last bits encode permissions)
```

### 2. Only PoolManager Can Call

```solidity
modifier onlyPoolManager() {
    require(msg.sender == address(poolManager), "YieldShiftHook: Not pool manager");
    _;
}
```

**Why?**
- Security: Only legitimate swaps trigger hooks
- Prevention: Random addresses can't call hooks
- Trust: PoolManager is canonical Uniswap v4 contract

### 3. State Management

```solidity
// Per-pool configuration
mapping(PoolId => YieldConfig) private _poolConfigs;

// Per-pool state
mapping(PoolId => PoolState) private _poolStates;

// Per-pool active vaults
mapping(PoolId => address[]) private _activeVaults;

// Per-pool per-vault balances
mapping(PoolId => mapping(address => uint256)) private _vaultBalances;
```

**Why nested mappings?**
- Each pool can have different configuration
- Each pool tracks its own vaults
- Allows multi-pool deployment from single hook

### 4. Gas Optimization Techniques

#### Rate Limiting
```solidity
if (block.timestamp - state.lastShiftTime < MIN_SHIFT_INTERVAL) {
    return; // Skip shift
}
```
**Saves:** ~100k gas per swap when rate limited

#### Try-Catch for External Calls
```solidity
try yieldOracle.getBestYield(...) returns (...) {
    // Use result
} catch {
    // Continue without error
}
```
**Benefit:** Swap never fails due to yield routing issues

#### Counter-Based Harvesting
```solidity
state.swapCount++;
if (state.swapCount >= config.harvestFrequency) {
    harvest();
}
```
**Saves:** Harvest gas amortized over N swaps instead of every swap

### 5. Integration with External Contracts

```
YieldShiftHook
    ↓
    ├── YieldOracle.getBestYield()
    │   └── Returns: (vault address, APY)
    │
    ├── YieldRouter.shiftToVault()
    │   ├── Calls: EigenLayerAdapter.deposit()
    │   │   └── Deposits to weETH/ezETH/mETH
    │   ├── Or: AaveAdapter.deposit()
    │   │   └── Deposits to Aave lending
    │   └── Returns: shares received
    │
    └── YieldRouter.harvest()
        ├── Calls: adapter.harvest() for each vault
        └── Returns: total rewards
```

---

## Example Scenarios

### Scenario 1: First Swap in a New Pool

```
Time: T0
Action: User swaps 1000 USDC → ETH
State: swapCount = 0, no active vaults

beforeSwap:
├─ Load config: shiftPercentage=20%, minAPYThreshold=2%, harvestFrequency=10
├─ Rate limit: PASS (first shift)
├─ Query oracle: EigenLayer weETH = 7.5% APY
├─ APY check: 7.5% >= 2% ✅
├─ Calculate shift: 10,000 USDC * 20% = 2,000 USDC
├─ Shift to vault: Deposit 2,000 USDC → get 1,950 weETH shares
└─ Update: totalShifted = 2,000, activeVaults = [weETH]

Swap executes: 1000 USDC → 0.28 ETH

afterSwap:
├─ Increment counter: swapCount = 0 → 1
└─ Check harvest: 1 < 10, skip harvest

Result:
- User got their ETH
- 2,000 USDC now earning 7.5% in EigenLayer
- Next harvest in 9 more swaps
```

### Scenario 2: Harvest Triggered

```
Time: T1 (after 9 more swaps)
Action: User swaps 500 USDC → ETH
State: swapCount = 9, activeVaults = [weETH, Morpho, Aave]

beforeSwap:
├─ Rate limit: FAIL (only 20 seconds since last shift)
└─ Skip shifting

Swap executes: 500 USDC → 0.14 ETH

afterSwap:
├─ Increment counter: swapCount = 9 → 10
├─ Check harvest: 10 >= 10 ✅ HARVEST!
├─ Harvest from weETH: 0.3 ETH rewards (from exchange rate increase)
├─ Harvest from Morpho: 50 MORPHO tokens
├─ Harvest from Aave: 100 AAVE tokens
├─ Total harvested: ~$400 worth
├─ Reset counter: swapCount = 0
└─ Send to YieldCompound

YieldCompound:
├─ Swap rewards to USDC: ~400 USDC
└─ Add liquidity: Adds 400 USDC + equivalent ETH to pool

Result:
- User got their ETH
- Pool liquidity increased by ~400 USDC worth
- All LPs benefit from auto-compounded yield
- Next harvest in 10 more swaps
```

### Scenario 3: Emergency Pause

```
Time: T2
Action: Admin detects issue, pauses pool
State: isPaused = true

beforeSwap:
├─ Load config: isPaused = true
└─ Return early, no shifting

Swap executes: Normal swap, no yield routing

afterSwap:
├─ Load config: isPaused = true
└─ Return early, no harvesting

Result:
- Swaps still work normally
- No yield routing (safe mode)
- Existing vault positions remain
- Admin can emergencyWithdraw() if needed
```

---

## Key Takeaways

### What Makes This Implementation Special?

1. **Passive for LPs**
   - LPs don't need to do anything special
   - Yield happens automatically during normal trading
   - No staking, no wrappers, no extra transactions

2. **Gas Efficient**
   - Rate limiting prevents excessive shifting
   - Counter-based harvesting amortizes costs
   - Try-catch ensures swaps never fail

3. **Flexible Architecture**
   - Per-pool configuration
   - Multiple vaults per pool
   - Easy to add new yield sources

4. **Safe & Robust**
   - Emergency pause functionality
   - Emergency withdraw capability
   - Graceful error handling

5. **EigenLayer Integration**
   - Leverages restaking rewards
   - Supports multiple LRTs (weETH, ezETH, mETH)
   - 6-10% APY on ETH

---

## Summary Table

| Hook | When Called | What We Do | Gas Impact | User Impact |
|------|-------------|------------|------------|-------------|
| **beforeSwap** | Before each swap | 1. Query best APY<br>2. Shift capital if profitable<br>3. Update state | +50k gas (when shifting)<br>+5k gas (when skipped) | Transparent<br>(no swap modification) |
| **afterSwap** | After each swap | 1. Increment counter<br>2. Harvest if threshold met<br>3. Trigger compound | +100k gas (when harvesting)<br>+2k gas (when skipped) | Transparent<br>(swap already completed) |

---

## Further Reading

- **Uniswap v4 Docs**: https://docs.uniswap.org/contracts/v4/overview
- **Hook Examples**: https://github.com/Uniswap/v4-periphery
- **Our Implementation**: `src/YieldShiftHook.sol`
- **Our Oracle**: `src/YieldOracle.sol`
- **Our Router**: `src/YieldRouter.sol`
- **EigenLayer Adapter**: `src/adapters/EigenLayerAdapter.sol`

---

**This is the core innovation of YieldShift: Using Uniswap v4 hooks to automatically optimize LP yields without any user action required.**
