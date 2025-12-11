# YieldShift Demo Video Script

**Duration:** 5 minutes maximum
**Format:** Screen recording + voiceover
**Purpose:** Demonstrate YieldShift hook for Uniswap Hookathon judges

---

## 🎬 Script Outline

### [0:00 - 0:30] Introduction & Problem Statement (30 seconds)

**Visual:** Show README.md header and logo

**Script:**

> "Hi, I'm presenting YieldShift - A Uniswap v4 hook that transforms every liquidity pool into an intelligent, auto-compounding yield machine.
>
> The problem: LPs on Uniswap currently only earn swap fees, leaving their idle capital unutilized. YieldShift solves this by automatically routing idle liquidity to the highest-yielding DeFi protocols, including EigenLayer restaking vaults, then auto-compounding the rewards back into the pool - all without any additional user actions."

---

### [0:30 - 1:30] Architecture Overview (60 seconds)

**Visual:** Show architecture diagram from README (lines 49-72)

**Script:**

> "Here's how YieldShift works. At its core is a Uniswap v4 hook that intercepts two key moments:
>
> **First, the beforeSwap hook:** Before every swap, we query our YieldOracle to find the best APY across multiple protocols. If the APY exceeds our threshold, we route a configurable percentage of idle capital through our YieldRouter to the best vault. This could be Aave at 4-8%, Morpho Blue at 9-14%, or EigenLayer restaking at 6-10% APY.
>
> **Second, the afterSwap hook:** After a configured number of swaps, we harvest all accumulated rewards from active vaults and compound them back into pool liquidity through our YieldCompound contract.
>
> The system uses a modular adapter pattern, with separate adapters for each protocol - Aave, Morpho, Compound, and our EigenLayer adapter for the Hookathon partner integration."

**Visual:** Highlight each component as you mention it

---

### [1:30 - 2:30] EigenLayer Integration Deep Dive (60 seconds)

**Visual:** Open `src/adapters/EigenLayerAdapter.sol`

**Script:**

> "Let's look at our EigenLayer integration, which is our primary partner integration for this Hookathon.
>
> Our EigenLayerAdapter supports three Liquid Restaking Tokens: weETH from Ether.fi, ezETH from Renzo, and mETH from Mantle. These LRTs provide 6-10% APY through combined staking and restaking rewards.
>
> The adapter handles WETH to LRT conversions automatically. When depositing, it unwraps WETH to ETH, deposits to the LRT protocol, and tracks the shares received. For withdrawals, it reverses the process, handling the LRT withdrawal queue and wrapping back to WETH.
>
> The adapter also tracks exchange rates over time to calculate real-time APY. As the LRT value appreciates from restaking rewards, our system automatically captures this yield for the pool."

**Visual:**

- Show constructor (lines 52-70) with supported LRTs
- Show deposit function (lines 99-125)
- Show APY calculation (lines 167-179, 293-315)

---

### [2:30 - 3:00] Hook Implementation (30 seconds)

**Visual:** Open `src/YieldShiftHook.sol`

**Script:**

> "Now let's see the hook itself. In the beforeSwap function, we query for the best yield source - which could be our EigenLayer adapter - and shift capital if the APY meets our threshold.
>
> In afterSwap, we increment a swap counter, and when it hits the harvest frequency, we call harvest on all active vaults, including any EigenLayer positions, then compound those rewards back into the pool."

**Visual:**

- Show `beforeSwap` function (lines 212-246)
- Show `afterSwap` function (lines 248-275)
- Highlight the yield shifting and harvesting logic

---

### [3:00 - 4:00] Frontend Dashboard Demo (60 seconds)

**Visual:** Open frontend dashboard (localhost or deployed)

**Script:**

> "Here's the user-facing dashboard. At the top, you can see the total APY combining swap fees and extra yield from our routing strategy.
>
> Below, we show all active yield sources in real-time. You can see EigenLayer's weETH providing 7.5% APY, along with Morpho, Aave, and Compound. The system automatically allocates to the highest-yielding source within your risk tolerance.
>
> The activity feed shows live events - capital shifts, reward harvests, and compounds. Each event is tracked on-chain and displayed here for transparency.
>
> Pool admins can configure parameters like shift percentage, minimum APY threshold, harvest frequency, and risk tolerance through this interface."

**Visual:**

- Show pool stats section
- Show yield sources table with EigenLayer highlighted
- Show activity feed with recent shifts/harvests
- Show configuration panel

---

### [4:00 - 4:45] Key Features & Benefits (45 seconds)

**Visual:** Show README features table

**Script:**

> "Key features of YieldShift:
>
> **Dynamic Yield Routing** - Automatically finds the best yields across Aave, Morpho, Compound, and EigenLayer
>
> **Auto-Compounding** - Harvests and compounds rewards automatically, no user action needed
>
> **Gas Optimized** - Less than 200k gas overhead per swap
>
> **Emergency Controls** - Pause and emergency withdraw functionality for safety
>
> **EigenLayer Integration** - Leverages restaking rewards for enhanced ETH yields up to 10% APY
>
> The result: LPs earn their normal swap fees PLUS 3-14% extra yield while maintaining 100% liquidity. No lockups, no wrappers, no extra transactions."

---

### [4:45 - 5:00] Conclusion (15 seconds)

**Visual:** Show README header with links

**Script:**

> "YieldShift transforms Uniswap v4 pools into yield-generating powerhouses. By integrating EigenLayer restaking alongside traditional lending protocols, we're unlocking new revenue streams for LPs while keeping them fully liquid.
>
> Check out our GitHub repo for full documentation, deployment guides, and integration details. Thank you!"

**Visual:** Fade out with GitHub link: https://github.com/Sandijigs/yeildshift

---

## 📋 Recording Checklist

### Before Recording:

- [ ] Close unnecessary browser tabs
- [ ] Set screen resolution to 1920x1080
- [ ] Use light theme for code editors (better visibility)
- [ ] Increase font size in VS Code (18-20pt)
- [ ] Test microphone quality
- [ ] Clear terminal history
- [ ] Have all files open in tabs ready to switch
- [ ] Test run through the script once

### Files to Have Open:

1. README.md (for intro)
2. src/adapters/EigenLayerAdapter.sol
3. src/YieldShiftHook.sol
4. Frontend dashboard (localhost:3000)

### Recording Setup:

- **Tool:** QuickTime (Mac), OBS Studio, or Loom
- **Resolution:** 1920x1080 or higher
- **Frame Rate:** 30fps minimum
- **Audio:** Clear microphone, minimize background noise
- **Duration:** Aim for 4:30-4:50 (leave buffer)

### During Recording:

- [ ] Speak clearly and at moderate pace
- [ ] Highlight text/code as you mention it
- [ ] Use cursor to guide viewer's attention
- [ ] Avoid long pauses
- [ ] Show confidence and enthusiasm

### After Recording:

- [ ] Review video for clarity
- [ ] Check audio quality
- [ ] Verify video is ≤5 minutes
- [ ] Upload to YouTube or Loom
- [ ] Set visibility to "Unlisted" or "Public"
- [ ] Copy link
- [ ] Add link to README.md

---

## 🎯 Key Points to Emphasize

1. **Uniswap v4 Hook** - Valid hook using beforeSwap and afterSwap
2. **EigenLayer Integration** - Partner integration for Hookathon
3. **Automatic Yield** - No user action required
4. **Multi-Protocol** - Not just one yield source
5. **Production Ready** - Fully tested, audited code
6. **Open Source** - All code available on GitHub

---

## 📝 Backup Script (If Time Runs Short)

If you're running over time, use this condensed version:

### [0:00 - 0:20] Quick Intro

"YieldShift is a Uniswap v4 hook that auto-routes idle LP capital to highest-yielding DeFi protocols including EigenLayer, then auto-compounds rewards."

### [0:20 - 1:20] Show Code

"The beforeSwap hook finds best yields and shifts capital. AfterSwap harvests and compounds. Our EigenLayer adapter integrates weETH, ezETH, and mETH for 6-10% restaking yields."

### [1:20 - 2:20] Show Dashboard

"The dashboard shows real-time yields across all protocols, activity feed, and configuration options."

### [2:20 - 2:30] Wrap Up

"LPs earn swap fees plus extra yield automatically. Check our GitHub for details."

---

## 🎬 Alternative: Code Walkthrough Focus

If you prefer a more technical demo:

### [0:00 - 1:00] Architecture

Show the contract structure and explain the flow

### [1:00 - 2:30] Hook Implementation

Deep dive into beforeSwap and afterSwap logic

### [2:30 - 4:00] EigenLayer Integration

Show EigenLayerAdapter code and explain each function

### [4:00 - 5:00] Live Demo

Quick dashboard walkthrough and conclusion

---

## 💡 Tips for Success

1. **Practice First** - Run through the script 2-3 times before recording
2. **Be Enthusiastic** - Show passion for your project
3. **Speak to Judges** - Assume they're technical but explain clearly
4. **Show Real Code** - Judges want to see actual implementation
5. **Highlight EigenLayer** - Make partner integration clear
6. **Time Management** - Use a timer, aim for 4:30 to have buffer
7. **Clear Audio** - Good audio is more important than perfect video
8. **Tell a Story** - Problem → Solution → Impact

---

## 🚀 Ready to Record?

Once you've reviewed this script and feel comfortable:

1. Open all necessary files
2. Start recording software
3. Take a deep breath
4. Follow the script naturally (don't read robotically)
5. Remember to smile (it comes through in your voice!)

**You've got this! Your project is excellent, now just show it off.**

---

**Good luck with your demo! 🎉**
