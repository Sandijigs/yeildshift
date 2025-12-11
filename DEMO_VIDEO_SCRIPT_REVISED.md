# YieldShift Demo Video Script (REVISED)

**Duration:** 5 minutes maximum
**Format:** Screen recording + voiceover
**Tone:** Natural, conversational, enthusiastic
**Purpose:** Show judges why YieldShift is a game-changer for LPs

---

## 🎬 Revised Script - Natural & Human

### [0:00 - 0:35] Introduction - The Problem & Solution (35 seconds)

**Visual:** Show README.md header

**Script (speak naturally, like explaining to a friend):**

> "Hey! So I built YieldShift for this Hookathon, and I'm pretty excited about it. Here's the problem I wanted to solve:
>
> Right now, if you're providing liquidity on Uniswap, you're only earning swap fees. That's it. All that idle capital just sitting there in the pool? Not doing anything for you.
>
> YieldShift changes that completely. It's a 'set and forget' system that automatically routes your idle liquidity to the best-earning protocols - like EigenLayer's restaking vaults, Morpho, Aave, Compound - and then auto-compounds everything back into your position.
>
> The best part? You don't have to do anything. No staking. No wrapper tokens. You stay 100% liquid. It all happens automatically through Uniswap v4 hooks."

**Key phrases to emphasize naturally:**
- "set and forget"
- "automatically"
- "you don't have to do anything"
- "100% liquid"

---

### [0:35 - 1:45] How It Works - The Magic Behind the Scenes (70 seconds)

**Visual:** Show architecture diagram, then YieldShiftHook.sol

**Script:**

> "So how does this actually work? It's pretty clever, honestly.
>
> I'm using two Uniswap v4 hooks - beforeSwap and afterSwap. Every time someone makes a swap in your pool, these hooks kick in automatically.
>
> **Before the swap happens**, my hook checks: 'Hey, what's the best yield out there right now?' Maybe Morpho is offering 10%, or EigenLayer's restaking is at 7.5%. If it beats my threshold - let's say 2% - I automatically shift a portion of idle capital to that vault. Could be 20%, could be 30%, whatever the pool is configured for.
>
> **After the swap completes**, I'm counting swaps. After every 10 swaps, the hook automatically harvests all the rewards that have accumulated - from EigenLayer, from Morpho, from all active vaults - and compounds them right back into the pool's liquidity.
>
> Here's what's cool: this all happens in the background, triggered by normal trading activity. LPs don't lift a finger. They just provide liquidity like normal, and boom - they're earning an extra 3 to 14% APY on top of their swap fees."

**Visual cues:**
- Point to beforeSwap function
- Point to afterSwap function
- Circle the key numbers when mentioning percentages

**Speak naturally:**
- "pretty clever, honestly"
- "Here's what's cool"
- "boom"
- Use hand gestures if on camera

---

### [1:45 - 2:45] EigenLayer Integration - The Secret Sauce (60 seconds)

**Visual:** Open src/adapters/EigenLayerAdapter.sol

**Script:**

> "Now let me show you the EigenLayer integration because this is where things get really interesting.
>
> EigenLayer is our Hookathon partner, and I've integrated their Liquid Restaking Tokens - weETH from Ether.fi, ezETH from Renzo, and mETH from Mantle. These are giving us 6 to 10% APY through restaking rewards.
>
> Look at this adapter right here. It handles everything automatically - converts WETH to these LRT tokens, deposits them, tracks the exchange rates, calculates the real-time APY. As these LRTs appreciate from restaking rewards, my system captures that yield for the pool.
>
> The beautiful thing is, LPs don't even know this is happening. They just see their positions growing. No extra steps, no claiming, no managing different protocols. It's all under the hood, working for them 24/7."

**Visual cues:**
- Show the deposit function (lines 99-125)
- Show APY calculation (lines 167-179)
- Highlight the supported LRTs (lines 29-31)

**Emphasize:**
- "automatically"
- "LPs don't even know this is happening"
- "working for them 24/7"

---

### [2:45 - 3:45] Live Dashboard - What LPs Actually See (60 seconds)

**Visual:** Open frontend dashboard

**Script:**

> "Alright, so here's what LPs actually see on the dashboard.
>
> Top of the screen - total APY. This combines their normal swap fees plus all the extra yield my system is generating. Let's say swap fees are 2%, and we're pulling in another 8% from yield routing - that's 10% total APY, all passive.
>
> Down here you can see where the capital is working. EigenLayer's weETH at 7.5%, Morpho at 10%, Aave at 5%. My system automatically picks the best one based on the pool's risk tolerance.
>
> This activity feed is live on-chain events. See these? Capital shifted to Morpho. Rewards harvested from EigenLayer. Everything compounded back into the pool. It's all transparent, all automatic.
>
> LPs literally just deposit their liquidity once and walk away. That's the 'set and forget' part. The pool does all the work."

**Visual cues:**
- Mouse over each section as you mention it
- Scroll through the activity feed
- Highlight the total APY number

**Natural phrases:**
- "Alright, so"
- "Let's say"
- "See these?"
- "literally just"

---

### [3:45 - 4:35] The Real Value - Why This Matters (50 seconds)

**Visual:** Back to README, show features section

**Script:**

> "So why does this matter? Let me break down what makes YieldShift special:
>
> **Number one**: LPs earn 3 to 14% extra APY. Automatically. While staying 100% liquid. That's huge.
>
> **Number two**: No staking, no wrapper tokens, no weird derivatives. Your position is yours. You can exit any time, just like normal Uniswap.
>
> **Number three**: It's powered by EigenLayer restaking plus the best lending protocols - Morpho, Aave, Compound. Multi-protocol diversification built-in.
>
> **Number four**: Everything is triggered by normal trading activity. No keepers, no bots you have to run, no extra gas you have to pay. Traders are already swapping, and we piggyback on that.
>
> This is what I mean by 'set and forget' - it's truly passive yield that works while you sleep."

**Delivery tips:**
- Count on your fingers for each point
- Emphasize percentages
- Pause after "That's huge" for impact
- End with confidence on "works while you sleep"

---

### [4:35 - 5:00] Closing - The Vision (25 seconds)

**Visual:** Show README header with GitHub link

**Script:**

> "So that's YieldShift. I think this is what Uniswap v4 hooks were made for - giving LPs more value without adding complexity.
>
> By integrating EigenLayer's restaking alongside traditional lending, we're opening up revenue streams that just weren't possible before. And it's all automatic, all passive, all working in the background.
>
> Everything's on GitHub - the code, the docs, deployment guides, security audit. Check it out. Thanks for watching!"

**Visual:** Fade to GitHub link

**Delivery:**
- End on a high note
- Smile (it comes through in voice)
- Sound confident but not cocky

---

## 🎯 KEY MESSAGING - Repeat These Throughout

Say these phrases naturally, multiple times:

✅ **"Set and forget"** - Use this exact phrase at least 3 times
✅ **"Automatically"** - Emphasize this is passive
✅ **"3 to 14% extra APY"** - Real numbers matter
✅ **"100% liquid"** - LPs keep full control
✅ **"No staking, no wrappers"** - Emphasize simplicity
✅ **"Triggered by normal trading"** - No extra work
✅ **"EigenLayer restaking"** - Partner integration
✅ **"Working in the background"** - Truly passive

---

## 💬 How to Sound Natural

### Do This:
- ✅ Use contractions: "don't", "that's", "here's", "it's"
- ✅ Say "pretty cool", "honestly", "alright", "boom"
- ✅ Pause naturally between thoughts
- ✅ Emphasize key numbers with your voice
- ✅ Sound enthusiastic (you built something awesome!)
- ✅ Vary your pace - slow down for important parts
- ✅ Smile while recording (seriously, it changes your voice)

### Don't Do This:
- ❌ Read like a robot
- ❌ Use overly formal language
- ❌ Rush through technical terms
- ❌ Sound monotone
- ❌ Apologize or hedge ("kind of", "sort of")
- ❌ Say "um" or "uh" (pause instead)

---

## 🎬 Recording Tips

### Before You Start:
1. **Read through the script out loud 2-3 times**
2. **Record a practice run** and listen back
3. **Mark which words to emphasize**
4. **Have water nearby** (for dry mouth)
5. **Stand up while recording** (better voice projection)

### While Recording:
- **Pretend you're explaining to a friend who's technical but hasn't seen your project**
- **Use hand gestures** even if not on camera (helps with energy)
- **Smile** at key moments (especially when saying numbers)
- **Pause between sections** (easier to edit later)
- **Re-record individual sections** if you mess up (no need to start over)

### Energy Level:
Think: **"Excited engineer showing their creation"**
- Not too hyped (not a sales pitch)
- Not too flat (not a lecture)
- Genuinely enthusiastic about the tech
- Confident in what you built

---

## 📊 The "Set and Forget" Checklist

Make sure you clearly communicate:

- [ ] LPs earn **3-14% extra APY**
- [ ] It happens **automatically** (say this word 5+ times)
- [ ] **No staking required** - just provide liquidity normally
- [ ] **No wrapper tokens** - your position is yours
- [ ] **100% liquid** - exit anytime
- [ ] Powered by **EigenLayer restaking** (6-10% APY)
- [ ] Also uses **Morpho, Aave, Compound** (diversification)
- [ ] **Triggered by normal trading** - no keeper bots needed
- [ ] LPs **literally do nothing** after initial deposit
- [ ] Works **24/7 in the background**

---

## 🎥 Visual Flow Summary

```
0:00-0:35  → README header
            Talk about the problem & "set and forget" solution

0:35-1:45  → Architecture diagram → YieldShiftHook.sol
            Show beforeSwap & afterSwap functions
            Explain automatic routing

1:45-2:45  → EigenLayerAdapter.sol
            Show deposit function, LRT support
            Emphasize "under the hood"

2:45-3:45  → Frontend dashboard
            Show total APY, yield sources, activity feed
            Demo "what LPs actually see"

3:45-4:35  → README features section
            Break down the value prop
            Count benefits on fingers

4:35-5:00  → README header → GitHub link
            Strong closing, call to action
```

---

## 🗣️ Sample Natural Transitions

Use these to connect sections smoothly:

- "So here's the thing..."
- "Now check this out..."
- "The cool part is..."
- "Let me show you..."
- "This is where it gets interesting..."
- "Here's what that looks like..."
- "So why does this matter?"
- "The real magic happens when..."

---

## ✨ The Perfect Take

Your ideal delivery:
- **Conversational** like explaining to a friend
- **Confident** because you built something real
- **Enthusiastic** without being over-the-top
- **Clear** on technical details
- **Human** with natural pauses and inflections

Remember: Judges are human. They want to see passion and innovation, not a corporate presentation.

---

## 🎯 Final Checklist Before Recording

- [ ] Understand the script (don't just read it)
- [ ] Know which words to emphasize
- [ ] Practice the "set and forget" key messaging
- [ ] Have all files open and ready
- [ ] Test microphone quality
- [ ] Increase font size in VS Code
- [ ] Close distracting tabs/apps
- [ ] Set timer for 5 minutes (so you don't go over)
- [ ] Take a deep breath
- [ ] Remember: You built something awesome!

---

## 💪 You've Got This!

Your project is technically solid. Now just show the judges:
1. **What problem you solved** (idle LP capital)
2. **How you solved it** (v4 hooks + EigenLayer)
3. **Why it's valuable** (3-14% extra APY, set and forget)
4. **That you're pumped about it** (genuine enthusiasm)

**The "set and forget" yield system is your hook. Make that the star of the show.**

---

**Ready to record? You've got this. Go show them what you built! 🚀**
