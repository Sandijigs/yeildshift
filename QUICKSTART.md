# 🚀 YieldShift Quick Start Guide

**Status:** ✅ All contracts deployed & verified on Base Sepolia
**Date:** December 10, 2025

---

## ✅ What's Already Done

### 1. Smart Contracts - DEPLOYED & VERIFIED ✅

All contracts are live on Base Sepolia and verified on Basescan:

| Contract | Address | Status |
|----------|---------|--------|
| **YieldOracle** | `0xCB5d6d80535a5F50f33C457eEf4ca2E9F712E864` | ✅ Verified |
| **YieldRouter** | `0x99907915Ef1836a00ce88061B75B2cfC4537B5A6` | ✅ Verified |
| **YieldCompound** | `0x35b95450Eaab790de5a8067064B9ce75a57d4d8f` | ✅ Verified |
| **YieldShiftHook** | `0xE0122CF1AbC59977a8F1DC1A02B36c678d5F40C0` | ✅ Verified |
| **YieldShiftFactory** | `0x3a07Ba4489d9aB8BFdc750C0cf0e41cD1f9baf46` | ✅ Verified |

**View on Basescan:** https://sepolia.basescan.org/

### 2. Frontend Integration - READY ✅

- ✅ All contract addresses configured
- ✅ WalletConnect integrated (Project ID: `6b87a3c69cbd8b52055d7aef763148d6`)
- ✅ Custom React hooks created (3 files, 15+ hooks)
- ✅ Environment files configured
- ✅ Components ready

**Active Yield Sources Configured:**
- 🟢 **Morpho Blue** - 12.00% APY (Risk: 6/10)
- 🟢 **Aave v3 USDC** - 6.00% APY (Risk: 3/10)
- 🟢 **Compound v3 USDC** - 4.00% APY (Risk: 4/10)

---

## 🎯 Run the Frontend (3 Steps)

### Step 1: Navigate to Frontend Directory

Open your terminal and run:

```bash
cd /Users/idjighereoghenerukevwesandra/Desktop/yieldshift/frontend
```

### Step 2: Install Dependencies

```bash
npm install
```

This will install:
- React 18
- Wagmi v2 (Ethereum React hooks)
- RainbowKit (wallet connection UI)
- Viem (Ethereum library)
- TanStack Query (data fetching)
- Recharts (charts)
- Tailwind CSS (styling)

**Expected output:**
```
added 1500+ packages in ~30s
```

### Step 3: Start Development Server

```bash
npm start
```

**Expected output:**
```
Compiled successfully!

You can now view yieldshift-frontend in the browser.

  Local:            http://localhost:3000
  On Your Network:  http://192.168.x.x:3000
```

The app will automatically open in your browser at **http://localhost:3000**

---

## 🎨 What You'll See

### Landing Page (Not Connected)
- YieldShift branding
- "Connect Wallet" button
- Feature showcase

### Dashboard (After Connecting Wallet)

**1. Yield Sources Panel**
```
┌─────────────────────────────────────┐
│  Active Yield Sources (3)           │
├─────────────────────────────────────┤
│  🟢 Morpho Blue        12.00% APY   │
│     Risk: Medium (6/10)              │
│     0xBBBBBb...FFCb                  │
├─────────────────────────────────────┤
│  🟢 Aave v3 (USDC)      6.00% APY   │
│     Risk: Low (3/10)                 │
│     0xA238Dd...1c5                   │
├─────────────────────────────────────┤
│  🟢 Compound v3 (USDC)  4.00% APY   │
│     Risk: Low-Medium (4/10)          │
│     0xb125E6...2F                    │
└─────────────────────────────────────┘
```

**2. Real-Time Activity Feed**
- Live YieldShifted events
- Rewards harvested notifications
- Timestamps and amounts

**3. Pool Statistics**
- Total value shifted
- Total rewards harvested
- Swap count
- Last harvest time

**4. Configuration Panel**
- Shift percentage
- Risk tolerance
- APY thresholds

---

## 🔌 Wallet Connection

### Supported Wallets
- MetaMask
- Rainbow Wallet
- Coinbase Wallet
- Trust Wallet
- Any WalletConnect-compatible wallet

### Connection Steps
1. Click **"Connect Wallet"** button
2. Select your wallet from the list
3. Approve the connection in your wallet
4. **Important:** Make sure you're on **Base Sepolia** network
   - If on wrong network, wallet will prompt you to switch

### Network Details
- **Network Name:** Base Sepolia
- **Chain ID:** 84532
- **RPC URL:** https://sepolia.base.org
- **Currency Symbol:** ETH
- **Block Explorer:** https://sepolia.basescan.org

---

## 🧪 Testing Checklist

After the app loads, verify:

- [ ] **Wallet connects successfully**
- [ ] **Network shows "Base Sepolia" (green indicator)**
- [ ] **3 yield sources are displayed**
- [ ] **APYs show: 12%, 6%, 4%**
- [ ] **Risk scores are visible**
- [ ] **Vault addresses are clickable** (link to Basescan)
- [ ] **Data refreshes every 30 seconds**
- [ ] **UI is responsive** (resize browser window)

---

## 🐛 Troubleshooting

### Issue: "npm: command not found"

**Solution:**
Node.js v25 is installed but not in PATH. Try:
```bash
# Check where Node.js is installed
which node

# If it shows a path, add it to your PATH
export PATH="/path/to/node/bin:$PATH"

# Or reinstall Node.js and ensure it's in PATH
```

### Issue: "Cannot find module 'wagmi'"

**Solution:**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### Issue: "Network mismatch" warning

**Solution:**
1. Open your wallet (e.g., MetaMask)
2. Click network selector
3. Switch to "Base Sepolia"
4. Refresh the page

### Issue: "Contract read failed"

**Solution:**
1. Verify you're on Base Sepolia (Chain ID: 84532)
2. Check that wallet is connected
3. Refresh the page
4. Check browser console (F12) for specific errors

### Issue: No APY data showing

**Solution:**
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for errors
4. Verify:
   - Wallet is connected
   - Network is Base Sepolia
   - RPC endpoint is responding

---

## 📊 Live Contract Data

Once connected, the frontend will fetch:

### From YieldOracle (0xCB5d...E864)
- `getAllAPYs()` - All vault APYs
- `getBestYield(riskTolerance)` - Best vault for given risk
- `getVaultAPY(vault)` - Specific vault APY
- `getActiveVaultsCount()` - Number of active vaults

### From YieldRouter (0x9990...B5A6)
- `vaults(index)` - Registered vault addresses
- `totalDeposited(vault)` - Total deposited per vault
- `totalHarvested(vault)` - Total harvested per vault

### From YieldShiftHook (0xE012...40C0)
- `getPoolState(poolId)` - Pool statistics
- `poolConfigs(poolId)` - Pool configuration
- **Events:**
  - `YieldShifted` - When capital is moved to yield source
  - `RewardsHarvested` - When rewards are collected

---

## 📦 Production Build (Later)

When ready to deploy to production:

```bash
cd frontend
npm run build
```

This creates an optimized production build in `frontend/build/`

**Deploy to:**
- **Vercel:** `vercel deploy`
- **Netlify:** `netlify deploy --prod --dir=build`
- **IPFS:** `ipd build/`
- **Traditional hosting:** Upload `build/` folder

---

## 📁 Key Files Reference

| File | Purpose |
|------|---------|
| `frontend/src/App.tsx` | Main app, Wagmi config, WalletConnect |
| `frontend/src/contracts/index.ts` | Contract addresses & ABIs |
| `frontend/src/hooks/useYieldOracle.ts` | Oracle data hooks |
| `frontend/src/hooks/useYieldRouter.ts` | Router stats hooks |
| `frontend/src/hooks/useYieldShiftHook.ts` | Event monitoring hooks |
| `frontend/.env` | Environment configuration |
| `frontend/package.json` | Dependencies |

---

## 🎓 Custom Hooks Documentation

### useYieldOracle.ts
```typescript
useAllAPYs()              // Get all vault APYs
useBestYield(risk)        // Get best vault for risk tolerance
useVaultAPY(vault)        // Get specific vault APY
useVaultConfig(vault)     // Get vault configuration
useAllVaultDetails()      // Combined vault data
formatAPY(apy)            // Format APY for display
```

### useYieldRouter.ts
```typescript
useAllVaults()            // Get all registered vaults
useTotalDeposited(vault)  // Total deposited in vault
useTotalHarvested(vault)  // Total harvested from vault
useAllVaultStats()        // Combined stats for all vaults
formatCompact(amount)     // Format large numbers (1.5K, 2.3M)
```

### useYieldShiftHook.ts
```typescript
usePoolState(poolId)           // Get pool state
usePoolConfig(poolId)          // Get pool configuration
useYieldShiftedEvents()        // Watch YieldShifted events
useRewardsHarvestedEvents()    // Watch RewardsHarvested events
useActivityFeed()              // Combined activity feed
parsePoolState(data)           // Parse pool state data
parsePoolConfig(data)          // Parse pool config data
formatRelativeTime(timestamp)  // Format timestamp (5m ago)
```

---

## 🔗 Important Links

### Contracts on Basescan
- [YieldOracle](https://sepolia.basescan.org/address/0xCB5d6d80535a5F50f33C457eEf4ca2E9F712E864)
- [YieldRouter](https://sepolia.basescan.org/address/0x99907915Ef1836a00ce88061B75B2cfC4537B5A6)
- [YieldCompound](https://sepolia.basescan.org/address/0x35b95450Eaab790de5a8067064B9ce75a57d4d8f)
- [YieldShiftHook](https://sepolia.basescan.org/address/0xE0122CF1AbC59977a8F1DC1A02B36c678d5F40C0)
- [YieldShiftFactory](https://sepolia.basescan.org/address/0x3a07Ba4489d9aB8BFdc750C0cf0e41cD1f9baf46)

### Resources
- **Base Sepolia Faucet:** https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet
- **WalletConnect Cloud:** https://cloud.walletconnect.com/
- **Base Sepolia Explorer:** https://sepolia.basescan.org/

---

## ✅ Summary - You're Ready!

**What's configured:**
- ✅ 5 contracts deployed & verified on Base Sepolia
- ✅ 3 yield sources active (Morpho, Aave, Compound)
- ✅ Frontend fully integrated with WalletConnect
- ✅ 15+ custom React hooks for contract interactions
- ✅ Real-time event monitoring
- ✅ Responsive UI with Tailwind CSS

**To launch:**
```bash
cd frontend
npm install
npm start
```

**Then:**
1. Visit http://localhost:3000
2. Connect your wallet
3. Switch to Base Sepolia
4. See live APY data from your deployed contracts!

---

## 🎉 Next Steps After Frontend is Running

1. **Test Wallet Connection** - Connect MetaMask/Rainbow
2. **View Live Data** - See APYs, vault stats, activity feed
3. **Create First Pool** - Use YieldShiftFactory to create a pool
4. **Add Liquidity** - Provide liquidity to test yield shifting
5. **Monitor Events** - Watch YieldShifted and RewardsHarvested events
6. **Deploy to Production** - Build and deploy to Vercel/Netlify

---

**Ready to go! Just run the 3 commands above in your terminal.** 🚀

**Support:**
- Documentation: See `FRONTEND_INTEGRATION_COMPLETE.md`
- Setup Guide: See `frontend/SETUP.md`
- Deployment Record: See `FINAL_DEPLOYMENT.md`
- Verification Details: See `VERIFICATION_COMPLETE.md`
