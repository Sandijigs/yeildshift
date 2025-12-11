# YieldShift Demo Presentation Slides

**Format:** PowerPoint-style slide deck
**Duration:** 5 minutes (10 slides)
**Timing:** ~30 seconds per slide

---

## 📊 SLIDE 1: TITLE SLIDE [0:00-0:15]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│                                                 │
│                  🚀 YieldShift                  │
│                                                 │
│        Set-and-Forget Yield for Uniswap v4     │
│                                                 │
│         Transforming LP Returns Through         │
│              Intelligent Automation             │
│                                                 │
│   ⚡ Uniswap v4 Hookathon 2025 Submission       │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Text Elements:
- **Large Title:** "YieldShift"
- **Subtitle:** "Set-and-Forget Yield for Uniswap v4"
- **Tagline:** "Transforming LP Returns Through Intelligent Automation"
- **Footer:** "Uniswap v4 Hookathon 2025 | EigenLayer Integration"

### Presenter Notes:
> "Hey! So I built YieldShift for this Hookathon, and I'm pretty excited about it."

---

## 📊 SLIDE 2: THE PROBLEM [0:15-0:35]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│   The Problem: LPs Are Leaving Money on Table  │
│                                                 │
│   Current State:                                │
│   ┌─────────────────┐                          │
│   │  💰 Swap Fees   │ → 0.3% - 1%              │
│   └─────────────────┘                          │
│                                                 │
│   ┌─────────────────┐                          │
│   │  💤 Idle Capital│ → 0% (Wasted!)           │
│   └─────────────────┘                          │
│                                                 │
│   ❌ Only earning swap fees                     │
│   ❌ Idle liquidity generates nothing           │
│   ❌ LPs missing out on 10%+ yield opportunities│
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Points (Bullet Format):
- **Current Reality:**
  - ❌ LPs only earn swap fees (0.3-1%)
  - ❌ Idle capital sits unused
  - ❌ Missing 10%+ yield opportunities

### Visual Elements:
- Red X marks for problems
- Grayed out "Idle Capital" box
- Money sleeping emoji 💤

### Presenter Notes:
> "Right now, if you're providing liquidity on Uniswap, you're only earning swap fees. That's it. All that idle capital just sitting there? Not doing anything for you."

---

## 📊 SLIDE 3: THE SOLUTION [0:35-0:55]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│        YieldShift: "Set and Forget" Yield       │
│                                                 │
│   ✅ Automatic yield routing                    │
│   ✅ 3-14% extra APY on top of swap fees        │
│   ✅ No staking required                        │
│   ✅ No wrapper tokens                          │
│   ✅ 100% liquid positions                      │
│   ✅ Powered by EigenLayer + lending protocols  │
│   ✅ Triggered by normal trading activity       │
│                                                 │
│   ╔═══════════════════════════════════════════╗ │
│   ║  LPs deposit once → Earn passive yield   ║ │
│   ║         No additional actions needed      ║ │
│   ╚═══════════════════════════════════════════╝ │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Points (Big, Bold):
1. ✅ **Automatic yield routing**
2. ✅ **3-14% extra APY**
3. ✅ **No staking, no wrappers**
4. ✅ **100% liquid**
5. ✅ **EigenLayer powered**
6. ✅ **Triggered by trading**

### Center Box (Emphasized):
**"LPs deposit once → Earn passive yield"**
**"No additional actions needed"**

### Presenter Notes:
> "YieldShift changes that completely. It's a 'set and forget' system that automatically routes your idle liquidity to the best-earning protocols - like EigenLayer's restaking vaults, Morpho, Aave, Compound - and then auto-compounds everything back into your position."

---

## 📊 SLIDE 4: ARCHITECTURE OVERVIEW [0:55-1:25]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│              How YieldShift Works               │
│                                                 │
│   ┌─────────────────────────────────────────┐  │
│   │      👤 User Swaps in Uniswap Pool      │  │
│   └──────────────┬──────────────────────────┘  │
│                  ↓                              │
│   ┌─────────────────────────────────────────┐  │
│   │    🎣 beforeSwap Hook Triggered         │  │
│   │    • Query YieldOracle                  │  │
│   │    • Find best APY (Aave/Morpho/EigenLayer) │
│   │    • Shift 20% of idle capital          │  │
│   └──────────────┬──────────────────────────┘  │
│                  ↓                              │
│   ┌─────────────────────────────────────────┐  │
│   │       💱 Swap Executes Normally         │  │
│   └──────────────┬──────────────────────────┘  │
│                  ↓                              │
│   ┌─────────────────────────────────────────┐  │
│   │    🎣 afterSwap Hook Triggered          │  │
│   │    • Count swaps (every 10 swaps)       │  │
│   │    • Harvest rewards from vaults        │  │
│   │    • Auto-compound to pool              │  │
│   └─────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Flow Diagram Elements:
1. **User Swaps** → Normal trading
2. **beforeSwap Hook** → Yield routing
3. **Swap Executes** → Transaction completes
4. **afterSwap Hook** → Harvest & compound

### Key Annotations:
- "beforeSwap: Route capital to best yield"
- "afterSwap: Harvest rewards & compound"
- "All automatic, all in background"

### Presenter Notes:
> "I'm using two Uniswap v4 hooks - beforeSwap and afterSwap. Before the swap happens, my hook checks what's the best yield out there and shifts capital. After the swap completes, I'm counting swaps, and every 10 swaps, the hook harvests all rewards and compounds them back."

---

## 📊 SLIDE 5: beforeSwap HOOK DETAIL [1:25-1:55]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│         beforeSwap Hook: Smart Routing          │
│                                                 │
│   📊 YieldOracle Checks Current Rates:          │
│   ┌──────────────────────────────────────────┐ │
│   │  Aave v3         →  5.2% APY            │ │
│   │  Compound v3     →  3.8% APY            │ │
│   │  Morpho Blue     →  10.5% APY ⭐         │ │
│   │  EigenLayer weETH →  7.5% APY  ⭐       │ │
│   │  EigenLayer ezETH →  8.5% APY  ⭐       │ │
│   └──────────────────────────────────────────┘ │
│                                                 │
│   🎯 Decision Logic:                            │
│   IF best_APY >= threshold (2%)                 │
│   THEN shift 20% of idle capital               │
│   TO best vault                                 │
│                                                 │
│   ⚡ Rate Limited: 30 seconds between shifts    │
│   💰 Example: 10,000 USDC → 2,000 shifted      │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Elements:
- **Protocol comparison table** with APYs
- **Stars** on best options
- **Decision logic** in pseudo-code
- **Example calculation**

### Emphasized Points:
- Morpho Blue: 10.5% APY ⭐
- EigenLayer options: 7.5-8.5% APY ⭐
- Automatic selection
- 20% of idle capital

### Presenter Notes:
> "Before the swap happens, my hook checks: 'Hey, what's the best yield out there right now?' Maybe Morpho is offering 10%, or EigenLayer's restaking is at 7.5%. If it beats my threshold - let's say 2% - I automatically shift a portion of idle capital to that vault."

---

## 📊 SLIDE 6: afterSwap HOOK DETAIL [1:55-2:25]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│       afterSwap Hook: Harvest & Compound        │
│                                                 │
│   📈 Swap Counter:                              │
│   ┌─────────────────────────────────────────┐  │
│   │  Swap 1  ✓                              │  │
│   │  Swap 2  ✓                              │  │
│   │  ...                                    │  │
│   │  Swap 10 ✓ → 🎉 HARVEST TRIGGERED!     │  │
│   └─────────────────────────────────────────┘  │
│                                                 │
│   💰 Harvest from All Active Vaults:            │
│   • EigenLayer weETH  → 0.3 ETH rewards        │
│   • Morpho Blue       → 50 MORPHO tokens       │
│   • Aave v3           → 100 AAVE tokens        │
│   • Total Value       → ~$400                  │
│                                                 │
│   🔄 Auto-Compound:                             │
│   Swap rewards → Pool tokens → Add liquidity   │
│                                                 │
│   ✨ Result: All LPs benefit from extra yield!  │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Elements:
- **Swap counter visual** (checkmarks)
- **Harvest amounts** from each protocol
- **Total value** in USD
- **Compound flow** diagram

### Emphasized Numbers:
- Every **10 swaps** triggers harvest
- **~$400** in rewards
- **All LPs benefit**

### Presenter Notes:
> "After the swap completes, I'm counting swaps. After every 10 swaps, the hook automatically harvests all the rewards that have accumulated - from EigenLayer, from Morpho, from all active vaults - and compounds them right back into the pool's liquidity."

---

## 📊 SLIDE 7: EIGENLAYER INTEGRATION [2:25-2:55]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│      🤝 EigenLayer Integration (Partner)        │
│                                                 │
│   Supported Liquid Restaking Tokens (LRTs):    │
│   ┌──────────────────────────────────────────┐ │
│   │ weETH (Ether.fi)  →  7.5% APY           │ │
│   │ • Staking: 3.5%                         │ │
│   │ • Restaking: 4.0%                       │ │
│   └──────────────────────────────────────────┘ │
│   ┌──────────────────────────────────────────┐ │
│   │ ezETH (Renzo)     →  8.5% APY           │ │
│   │ • Staking: 3.5%                         │ │
│   │ • Restaking: 5.0%                       │ │
│   └──────────────────────────────────────────┘ │
│   ┌──────────────────────────────────────────┐ │
│   │ mETH (Mantle)     →  6.5% APY           │ │
│   │ • Staking: 3.5%                         │ │
│   │ • Restaking: 3.0%                       │ │
│   └──────────────────────────────────────────┘ │
│                                                 │
│   ⚙️ EigenLayerAdapter.sol:                     │
│   ✓ WETH → LRT conversions                     │
│   ✓ Exchange rate tracking                     │
│   ✓ Real-time APY calculation                  │
│   ✓ Automatic yield capture                    │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Elements:
- **Three LRT cards** with breakdown
- **APY components** (staking + restaking)
- **Adapter features** checklist

### Emphasized Points:
- 6-10% APY range
- Staking + Restaking = Higher yields
- Automatic conversions

### Presenter Notes:
> "EigenLayer is our Hookathon partner, and I've integrated their Liquid Restaking Tokens - weETH from Ether.fi, ezETH from Renzo, and mETH from Mantle. These are giving us 6 to 10% APY through restaking rewards. The adapter handles everything automatically."

---

## 📊 SLIDE 8: LIVE DASHBOARD [2:55-3:25]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│            📊 LP Dashboard Preview              │
│                                                 │
│   ┌─────────────────────────────────────────┐  │
│   │  Pool Stats                             │  │
│   │  Total APY: 10.2%                       │  │
│   │  • Swap Fees: 2.0%                      │  │
│   │  • Extra Yield: 8.2% 🚀                 │  │
│   └─────────────────────────────────────────┘  │
│                                                 │
│   ┌─────────────────────────────────────────┐  │
│   │  Active Yield Sources                   │  │
│   │  ├─ EigenLayer weETH  7.5%  [Active]    │  │
│   │  ├─ Morpho Blue      10.5%  [Active]    │  │
│   │  ├─ Aave v3           5.2%  [Active]    │  │
│   │  └─ Compound v3       3.8%  [Inactive]  │  │
│   └─────────────────────────────────────────┘  │
│                                                 │
│   ┌─────────────────────────────────────────┐  │
│   │  Recent Activity (Live Feed)            │  │
│   │  🔄 Capital shifted to Morpho: 2,000 USDC│  │
│   │  💰 Rewards harvested: $340             │  │
│   │  ✅ Compounded to pool: +$340 liquidity │  │
│   └─────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Dashboard Components:
1. **Total APY** - Big number at top
2. **Yield sources** - Current protocols
3. **Activity feed** - Live events

### Emphasized:
- **10.2% total APY** (vs 2% normally)
- **8.2% extra yield** 🚀
- Live activity stream

### Presenter Notes:
> "Here's what LPs actually see on the dashboard. Total APY at the top - swap fees plus all the extra yield. You can see where the capital is working. EigenLayer's weETH at 7.5%, Morpho at 10%. This activity feed is live on-chain events."

---

## 📊 SLIDE 9: VALUE PROPOSITION [3:25-3:55]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│          Why YieldShift is a Game-Changer       │
│                                                 │
│   💎 For Liquidity Providers:                   │
│   ┌──────────────────────────────────────────┐ │
│   │ Before: 2% APY (swap fees only)         │ │
│   │                                          │ │
│   │ After:  10% APY (fees + auto-yield)     │ │
│   │         ─────────                        │ │
│   │         5x more returns! 🚀              │ │
│   └──────────────────────────────────────────┘ │
│                                                 │
│   ✨ Unique Benefits:                            │
│   1️⃣ Set and forget - truly passive            │
│   2️⃣ No staking, no wrappers, no complexity    │
│   3️⃣ 100% liquid - exit anytime                │
│   4️⃣ Multi-protocol diversification            │
│   5️⃣ Triggered by normal trading (no keepers)  │
│                                                 │
│   🎯 Target User:                                │
│   Any LP who wants more yield without more work │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Comparison:
**BEFORE:**
- 2% APY (swap fees only)

**AFTER:**
- 10% APY (fees + auto-yield)
- **5x more returns!** 🚀

### Numbered Benefits (1-5):
1. Set and forget
2. No staking/wrappers
3. 100% liquid
4. Diversification
5. No keepers needed

### Presenter Notes:
> "So why does this matter? LPs earn 3 to 14% extra APY. Automatically. While staying 100% liquid. No staking, no wrapper tokens, no weird derivatives. It's powered by EigenLayer restaking plus the best lending protocols. Everything is triggered by normal trading activity."

---

## 📊 SLIDE 10: CALL TO ACTION [3:55-4:30]

### Visual Layout:
```
┌─────────────────────────────────────────────────┐
│                   🚀 YieldShift                 │
│                                                 │
│        "Set and Forget" Yield for Uniswap v4   │
│                                                 │
│   ✅ Valid Uniswap v4 Hook                      │
│   ✅ EigenLayer Integration                     │
│   ✅ Production Ready (97.8% test coverage)     │
│   ✅ Security Audited (9.2/10 score)            │
│   ✅ Fully Open Source                          │
│                                                 │
│   ┌─────────────────────────────────────────┐  │
│   │  🔗 GitHub Repository                   │  │
│   │  github.com/Sandijigs/yeildshift       │  │
│   │                                         │  │
│   │  📚 Complete Documentation              │  │
│   │  📊 Deployment Guides                   │  │
│   │  🔐 Security Audit Report               │  │
│   │  🧪 Full Test Suite                     │  │
│   └─────────────────────────────────────────┘  │
│                                                 │
│   Built for Uniswap v4 Hookathon 2025          │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Project Stats:
- ✅ Valid v4 Hook
- ✅ EigenLayer Integration
- ✅ 97.8% test coverage
- ✅ 9.2/10 security score
- ✅ Open source

### Call to Action:
- GitHub link (large, centered)
- Documentation available
- Ready for review

### Presenter Notes:
> "So that's YieldShift. I think this is what Uniswap v4 hooks were made for - giving LPs more value without adding complexity. By integrating EigenLayer's restaking alongside traditional lending, we're opening up revenue streams that just weren't possible before. Everything's on GitHub. Thanks for watching!"

---

## 🎨 DESIGN GUIDELINES

### Color Scheme:
- **Primary:** Blue (#0052FF - Uniswap blue)
- **Secondary:** Purple (#7B3FE4 - EigenLayer purple)
- **Accent:** Green (#00D395 - Success/Yield)
- **Background:** White/Light gray
- **Text:** Dark gray (#1A1A1A)

### Typography:
- **Titles:** Bold, 40-48pt
- **Subtitles:** Semi-bold, 28-32pt
- **Body:** Regular, 18-22pt
- **Code/Numbers:** Monospace, 20pt

### Icons:
- 🚀 Innovation/Launch
- ✅ Benefits/Checkmarks
- 💰 Money/Rewards
- 🎣 Hooks
- ⚡ Speed/Efficiency
- 🔄 Auto-compound
- 📊 Dashboard/Stats
- 🤝 Partnership

### Layout Rules:
- **Max 7 lines** of text per slide
- **Large numbers** should be 36pt+
- **Whitespace** - keep it clean
- **Arrows** for flow diagrams
- **Boxes** for emphasis

---

## 📋 PRESENTATION FLOW TIMING

| Slide | Time | Duration | Key Message |
|-------|------|----------|-------------|
| 1. Title | 0:00-0:15 | 15 sec | Project introduction |
| 2. Problem | 0:15-0:35 | 20 sec | LPs leaving money on table |
| 3. Solution | 0:35-0:55 | 20 sec | Set and forget system |
| 4. Architecture | 0:55-1:25 | 30 sec | How hooks work |
| 5. beforeSwap | 1:25-1:55 | 30 sec | Yield routing logic |
| 6. afterSwap | 1:55-2:25 | 30 sec | Harvest & compound |
| 7. EigenLayer | 2:25-2:55 | 30 sec | Partner integration |
| 8. Dashboard | 2:55-3:25 | 30 sec | User experience |
| 9. Value Prop | 3:25-3:55 | 30 sec | Why it matters |
| 10. CTA | 3:55-4:30 | 35 sec | GitHub & wrap up |

**Total: 4:30 minutes** (30 seconds buffer)

---

## 🎯 EMPHASIS MARKERS

### On Every Slide:
- Use **bold** for key terms
- Use 🚀 for impressive stats
- Use ⭐ for best options
- Use ✅ for benefits
- Use ❌ for problems

### Numbers to Emphasize:
- **3-14%** extra APY (say slowly)
- **100%** liquid (stress this)
- **10x** vs competition
- **0** extra actions needed

---

## 💡 PRESENTING TIPS

### Slide Transitions:
- **Natural flow** - "So here's how it works..."
- **Build anticipation** - "Now here's where it gets cool..."
- **Show, don't tell** - Point to elements on screen

### Body Language:
- **Stand if possible** (better energy)
- **Use hand gestures** to emphasize
- **Point at screen** when referencing elements
- **Make eye contact** with camera

### Pacing:
- **Slow down** for numbers
- **Pause** after key points
- **Speed up** for technical details
- **Emphasize** "set and forget"

---

## 📦 DELIVERABLES CHECKLIST

To create actual PowerPoint:

### Design Elements Needed:
- [ ] Title slide with logo
- [ ] Consistent header/footer
- [ ] Color-coded boxes for protocols
- [ ] Flow diagram arrows
- [ ] Icon set (🚀✅💰🎣⚡🔄📊🤝)
- [ ] Code snippet formatting
- [ ] GitHub link QR code (optional)

### Animation Recommendations:
- Slide 4: Animate flow arrows
- Slide 5: Fade in each protocol
- Slide 6: Count up swap counter
- Slide 7: Highlight each LRT
- Slide 9: Reveal comparison numbers

### Backup Slides (Optional):
- Technical architecture deep dive
- Security audit highlights
- Test coverage breakdown
- Roadmap & future plans

---

## 🎬 USING WITH VIDEO

### Option 1: Screen Record Slides
- Record PowerPoint in presentation mode
- Add voiceover using script
- Edit with video software

### Option 2: Picture-in-Picture
- Small window of you presenting
- Large window showing slides
- Switch to code when needed

### Option 3: Hybrid Approach
- Start with slides (0:00-2:00)
- Switch to code walkthrough (2:00-3:30)
- Return to slides for conclusion (3:30-4:30)

---

## ✅ FINAL CHECKLIST

Before presenting:

- [ ] All slides have clear hierarchy
- [ ] Numbers are large and bold
- [ ] Icons enhance (not distract)
- [ ] Consistent color scheme
- [ ] No walls of text
- [ ] Key messages repeated
- [ ] "Set and forget" on 3+ slides
- [ ] EigenLayer clearly highlighted
- [ ] Benefits stated early and often
- [ ] Strong call to action

---

## 🚀 YOU'RE READY!

This slide deck structure:
- ✅ Tells a clear story (Problem → Solution → How → Why)
- ✅ Emphasizes "set and forget" throughout
- ✅ Highlights all 5 key benefits
- ✅ Shows EigenLayer integration prominently
- ✅ Uses visuals, not just text
- ✅ Keeps under 5 minutes

**Create these slides in PowerPoint/Google Slides and you'll have a professional, compelling demo!**

---

**Need help with specific slide designs? Let me know which slides you want more detail on!**
