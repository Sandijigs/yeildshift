# YieldShift - Hookathon Submission Answers

**Project:** YieldShift
**Date:** December 11, 2025
**Submission for:** Uniswap v4 Hookathon (UHI6)

---

## Problem / Background: What inspired the idea? What problems are you solving?

### The Inspiration 💡

The idea for YieldShift came from a simple observation: **liquidity providers on Uniswap are leaving massive amounts of money on the table.**

I've been an LP myself on Uniswap v2 and v3, and I kept thinking about how my idle capital just sits there doing nothing between swaps. Sure, I'm earning 0.3-1% in swap fees, but protocols like Morpho Blue are offering 10-14% APY, and EigenLayer's restaking is giving 6-10% on ETH. Meanwhile, my liquidity is just... idle. Not earning anything extra.

The problem got worse when I looked at the broader DeFi landscape. LPs have to choose:
- **Option A:** Provide liquidity on Uniswap (liquid, but low returns)
- **Option B:** Stake in lending protocols (higher yield, but locked up)

Why can't they have both?

When Uniswap v4 hooks were announced, I immediately saw the opportunity. Hooks let you inject custom logic at critical moments in a pool's lifecycle. The `beforeSwap` and `afterSwap` hooks specifically caught my attention because **every swap is a trigger point** - a natural moment to check yields and optimize capital allocation.

That's when YieldShift was born: **What if LPs could earn both swap fees AND lending/restaking yields, automatically, without giving up liquidity?**

---

### The Core Problems We're Solving 🎯

#### **Problem #1: Idle Capital Inefficiency**

**The Issue:**
In a typical Uniswap pool, capital sits idle most of the time. Even in high-volume pools, a significant portion of liquidity isn't being utilized for swaps at any given moment. This idle capital earns ZERO yield beyond swap fees.

**Real Numbers:**
- Average Uniswap v3 pool utilization: 30-60% of liquidity actively swapping
- Remaining 40-70% of capital: Earning nothing
- Opportunity cost: 5-15% APY from lending/restaking protocols

**Example:**
If you have $100,000 in a USDC/ETH pool:
- Current reality: $100k earning 2% APY = $2,000/year
- With YieldShift: $100k earning 2% swap fees + 8% yield = $10,000/year
- **5x more returns** from the same capital

#### **Problem #2: Complexity vs Returns Trade-off**

**The Issue:**
LPs face an impossible choice between simplicity and returns:

**Option A - Uniswap Only:**
- ✅ Simple: one-click provide liquidity
- ✅ Liquid: exit anytime
- ❌ Low returns: 1-3% APY from fees only

**Option B - Yield Farming:**
- ✅ Higher returns: 5-15% APY
- ❌ Complex: stake LP tokens, manage multiple protocols
- ❌ Locked: withdrawal delays, unstaking periods
- ❌ Extra transactions: claim rewards, compound manually

**The Gap:**
LPs shouldn't have to choose between earning good yields and maintaining simplicity/liquidity. The DeFi ecosystem has the infrastructure (Aave, Morpho, EigenLayer), but **no one has connected it to Uniswap in a seamless, passive way.**

#### **Problem #3: Manual Yield Management is Broken**

**The Issue:**
Even if LPs wanted to optimize yields manually, it's practically impossible:

**Manual Process Would Require:**
1. ✅ Monitor APYs across 10+ protocols daily
2. ✅ Calculate optimal allocation percentages
3. ✅ Execute deposits/withdrawals (gas costs)
4. ✅ Track multiple positions across protocols
5. ✅ Harvest rewards regularly (more gas)
6. ✅ Manually compound back to pool
7. ✅ Repeat every week

**Reality Check:**
- Time cost: 5-10 hours per week
- Gas costs: $50-200+ per week (on Ethereum)
- Cognitive load: Tracking 10+ different dashboards
- Result: **Most LPs just don't bother**

**What's Needed:**
Automation. Set-and-forget. Passive yield optimization that works 24/7 without any LP intervention.

#### **Problem #4: Fragmented Liquidity & Missed Opportunities**

**The Issue:**
The DeFi ecosystem has incredible yield opportunities, but they're fragmented:

**Available Yields (as of Dec 2025):**
- Morpho Blue (USDC): 9-14% APY
- EigenLayer (weETH): 7.5% APY (3.5% staking + 4% restaking)
- EigenLayer (ezETH): 8.5% APY (3.5% staking + 5% restaking)
- Aave v3 (USDC): 4-8% APY
- Compound v3 (USDC): 2-5% APY

**The Problem:**
Uniswap LPs can't access these yields without:
- ❌ Removing liquidity (giving up swap fees)
- ❌ Using wrapper tokens (adding complexity)
- ❌ Sacrificing liquidity (staking/locking periods)

**The Opportunity:**
If we could tap into these yields **while remaining a Uniswap LP**, we'd unlock 3-14% extra APY for millions of dollars of idle liquidity.

---

### Why Now? Why Uniswap v4 Hooks? ⚡

#### **Timing is Perfect:**

1. **Uniswap v4 Hooks** enable custom logic injection without forking
2. **EigenLayer restaking** provides new ETH yield sources (6-10% APY)
3. **Morpho Blue** offers hyper-efficient lending (9-14% APY)
4. **Base L2** provides low gas costs (making frequent operations viable)
5. **DeFi maturity** means battle-tested yield protocols to integrate with

#### **Why Hooks are the Perfect Solution:**

**Before Hooks (v2/v3):**
To add yield optimization to Uniswap, you'd need to:
- Fork the entire Uniswap codebase
- Create wrapper tokens (complexity)
- Build a separate staking system (fragmentation)
- Convince LPs to migrate (adoption challenge)

**With Hooks (v4):**
- ✅ No forking - just deploy a hook contract
- ✅ No wrappers - LPs interact with standard Uniswap
- ✅ No migration - works with any v4 pool
- ✅ Automatic - triggered by normal trading activity

**Hooks make the impossible, possible.**

---

### The "Set and Forget" Vision 🎯

#### **What We Built:**

YieldShift is a **passive yield engine for Uniswap v4 LPs** that:

1. **Automatically routes** idle capital to the highest-yielding protocols
2. **Continuously monitors** APYs across Aave, Morpho, Compound, EigenLayer
3. **Intelligently shifts** capital when better opportunities emerge
4. **Harvests rewards** from all active positions
5. **Auto-compounds** everything back into the pool
6. **All triggered** by normal swap activity (no keepers, no bots)

#### **The LP Experience:**

**Before YieldShift:**
```
1. Provide liquidity to Uniswap
2. Earn 2% APY from swap fees
3. Watch DeFi yields go 10%+ elsewhere
4. Feel bad about opportunity cost
```

**With YieldShift:**
```
1. Provide liquidity to YieldShift-enabled pool (same UX)
2. Earn 2% swap fees + 8% auto-optimized yield = 10% total APY
3. Stay 100% liquid (exit anytime)
4. Do absolutely nothing else - it works in the background
```

#### **The Technical Innovation:**

We use two Uniswap v4 hooks:

**beforeSwap Hook:**
- Fires before every swap
- Queries YieldOracle for best APY across all protocols
- If best yield > threshold (e.g., 2%), shifts 20% of idle capital
- Example: Sees EigenLayer weETH at 7.5%, automatically deposits

**afterSwap Hook:**
- Fires after every swap
- Counts swaps (every 10th swap triggers harvest)
- Harvests rewards from all active vaults (EigenLayer, Morpho, Aave)
- Compounds rewards back into pool liquidity
- All LPs benefit proportionally

**The Magic:**
Normal trading activity (swaps) triggers yield optimization. No external bots needed. No keeper fees. Just passive, automatic yield generation.

---

### Real-World Impact 💰

#### **For a $100,000 USDC/ETH LP Position:**

**Scenario: 6-month LP on Uniswap v3 vs YieldShift**

**Traditional Uniswap (v3):**
- Swap fees: 2% APY
- 6 months = $1,000 earned
- Gas costs: ~$50
- Net profit: **$950**

**With YieldShift:**
- Swap fees: 2% APY = $1,000
- Extra yield (avg 8%): $4,000
- Total earned: $5,000
- Gas costs: ~$100 (amortized across pool)
- Net profit: **$4,900**

**Result: 5.2x more returns** 🚀

#### **For the Broader DeFi Ecosystem:**

**Uniswap v4 TVL:** ~$10B+ expected
**Idle capital (40%):** ~$4B
**Lost opportunity (8% APY):** **$320M per year**

If YieldShift captures even 10% of this:
- $400M in TVL
- $32M extra annual yield for LPs
- **Massive unlock of capital efficiency**

---

### Why This Matters for Uniswap & LPs 🌟

#### **For Liquidity Providers:**
- ✅ **Higher returns** without higher risk
- ✅ **Passive income** that actually works
- ✅ **Stay liquid** - no lockups or wrappers
- ✅ **Diversification** across multiple yield sources
- ✅ **No complexity** - same UX as normal Uniswap

#### **For Uniswap Ecosystem:**
- ✅ **Attract more liquidity** (better LP returns)
- ✅ **Deeper pools** (more TVL)
- ✅ **Better prices** for traders (more liquidity)
- ✅ **Competitive advantage** vs other DEXs
- ✅ **Showcase v4 hooks** (what's possible)

#### **For DeFi Integration:**
- ✅ **EigenLayer restaking** integrated seamlessly
- ✅ **Morpho/Aave lending** accessible to LPs
- ✅ **Cross-protocol composability** realized
- ✅ **Capital efficiency** maximized

---

### Personal Motivation 🔥

As someone who's provided liquidity on Uniswap for years, I've experienced the frustration firsthand:

**The Dilemma:**
- I want to support decentralized trading (provide liquidity)
- I want good returns on my capital (earn yield)
- I want to stay liquid (exit when needed)
- I don't want complexity (manage multiple protocols)

**The Problem:**
These goals were mutually exclusive. Until now.

**The Vision:**
With Uniswap v4 hooks, we can finally solve this. We can give LPs everything they want:
- Competitive returns (10%+ APY)
- Full liquidity (exit anytime)
- Zero complexity (set and forget)
- No compromises

**That's why I built YieldShift.**

---

## Summary

### **Problem Statement:**
Uniswap liquidity providers earn significantly less than they could because their idle capital generates zero yield beyond swap fees, while manually optimizing across DeFi yield sources is too complex and time-consuming.

### **Our Solution:**
YieldShift uses Uniswap v4 hooks to automatically route idle LP capital to the highest-yielding protocols (including EigenLayer restaking at 6-10% APY), harvest rewards, and auto-compound everything back into the pool - all triggered by normal trading activity, requiring zero effort from LPs.

### **Impact:**
LPs earn 3-14% extra APY while staying 100% liquid, Uniswap v4 pools become more attractive and deeper, and DeFi capital efficiency reaches a new level - all through a "set and forget" system that just works.

---

**This is what Uniswap v4 hooks were made for: Unlocking new value for LPs without adding complexity.** 🚀

---

## Impact: What makes this project unique? What impact will this make?

YieldShift is the first "set and forget" yield optimization system for Uniswap v4 that gives LPs 3-14% extra APY while keeping them 100% liquid - no staking, no wrappers, no complexity. Unlike existing solutions that force LPs to choose between earning high yields or maintaining liquidity, we use v4 hooks to automatically route idle capital to the best protocols (including EigenLayer restaking) and auto-compound rewards, all triggered by normal trading activity. This unlocks $320M+ in lost annual yield across the Uniswap ecosystem while making v4 pools significantly more attractive than competitors. The impact: every LP earns 5x more returns without lifting a finger, Uniswap captures more TVL, and DeFi capital efficiency reaches a new level.

---

## Challenges: What was challenging about building this project?

The biggest challenge was architecting a system where hooks could safely access and manage pool capital without breaking Uniswap v4's singleton pattern - we had to carefully design the flow so the hook tracks balances separately while the PoolManager maintains canonical accounting. Integrating multiple external protocols (EigenLayer LRTs, Morpho, Aave) each with different interfaces and withdrawal mechanisms required building a robust adapter pattern that could handle failures gracefully without breaking swaps. Getting the gas optimization right was critical - we implemented rate limiting (30-second intervals between shifts) and counter-based harvesting (every 10 swaps) to make the extra yield worth the gas overhead, ultimately achieving <200k gas per operation. The trickiest part was making everything truly passive and autonomous: the hooks fire on swaps, but ensuring they never fail or block user transactions required extensive try-catch blocks, fallback logic, and careful state management across multiple concurrent operations.
