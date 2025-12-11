# 🧪 YieldShift Testing Guide

**Status:** Frontend Running ✅ | Contracts Need Initialization ⏳

---

## 📊 Current Status (What's Working)

### ✅ Frontend (100% Complete)
- [x] UI loads correctly
- [x] Wallet connection works (RainbowKit)
- [x] Network detection (Base Sepolia)
- [x] All components render
- [x] Navigation works
- [x] Configuration panel functional

### ⏳ Smart Contracts (Deployed but Empty)
- [x] Contracts deployed to Base Sepolia
- [x] Contracts verified on Basescan
- [ ] **Vaults not added yet** ← We need to do this
- [ ] **APYs not set** ← We need to do this
- [ ] **Adapters not registered** ← We need to do this

---

## 🎯 Testing Plan

### **Phase 1: Browser Console Testing** (Do this NOW)

#### Test 1: Check for JavaScript Errors

1. **Open Developer Tools:**
   - Press `F12` or `Cmd+Option+I` (Mac)
   - Go to **Console** tab

2. **Look for:**
   ```
   ✅ GOOD SIGNS:
   - "Wagmi: Connected to..."
   - "useReadContract: polling..."
   - No red errors

   ❌ BAD SIGNS:
   - Contract read failed
   - RPC error
   - Network mismatch
   ```

3. **Tell me:** What do you see? Any errors?

---

#### Test 2: Check Network Connection

**In Console, run:**
```javascript
// Check current network
await window.ethereum.request({ method: 'eth_chainId' })
```

**Should show:** `"0x14a34"` (which is 84532 in hex - Base Sepolia)

---

#### Test 3: Test Contract Calls

**In Console, run:**
```javascript
// This tests if frontend can reach contracts
console.log("Testing contract calls...");
```

**Look at Network tab (F12 → Network):**
- Should see requests to `https://sepolia.base.org`
- Filter by "XHR" or "Fetch"

---

### **Phase 2: Initialize Contracts** (I'll help you)

Your contracts are deployed but empty! We need to add vault data.

#### Option A: Using Foundry (Recommended)

```bash
# Navigate to project
cd /Users/idjighereoghenerukevwesandra/Desktop/yieldshift

# Make sure you have .env file with DEPLOYER_PRIVATE_KEY
# Run initialization script
forge script script/InitializeContracts.s.sol:InitializeContracts \
    --rpc-url https://sepolia.base.org \
    --broadcast \
    -vvv
```

This will:
1. Add 3 vaults to YieldOracle (Morpho, Aave, Compound)
2. Set initial APYs (12%, 6%, 4%)
3. Authorize YieldShiftHook to use YieldRouter

---

#### Option B: Manual via Basescan (Slower but works)

**Step 1: Add Morpho Vault**

1. Go to [YieldOracle on Basescan](https://sepolia.basescan.org/address/0xCB5d6d80535a5F50f33C457eEf4ca2E9F712E864#writeContract)
2. Click "Connect to Web3"
3. Find `addVault` function
4. Enter:
   - `vault`: `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb`
   - `priceOracle`: `0x0000000000000000000000000000000000000000`
   - `riskScore`: `6`
5. Click "Write"
6. Confirm transaction in MetaMask

**Step 2: Repeat for Aave Vault**
- `vault`: `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5`
- `priceOracle`: `0x0000000000000000000000000000000000000000`
- `riskScore`: `3`

**Step 3: Repeat for Compound Vault**
- `vault`: `0xb125E6687d4313864e53df431d5425969c15Eb2F`
- `priceOracle`: `0x0000000000000000000000000000000000000000`
- `riskScore`: `4`

---

### **Phase 3: Update Frontend to Use Real Data**

Once contracts are initialized, we need to update `YieldSources.tsx` to fetch real data instead of mock data.

**Current (Mock Data):**
```typescript
const mockSources: YieldSource[] = [
  { name: 'Morpho Blue', apy: 11.2, ... },
  { name: 'EigenLayer', apy: 8.7, ... },
  // ...
];
```

**After (Real Data):**
```typescript
import { useAllVaultDetails } from '../hooks/useYieldOracle';

export const YieldSources = () => {
  const { vaults, isLoading } = useAllVaultDetails();

  // vaults will contain real data from contracts
  return ( ... );
}
```

---

### **Phase 4: End-to-End Testing**

After initialization:

#### Test 1: View Real APY Data

1. **Refresh your browser** (http://localhost:3456)
2. **Check "Active Yield Sources" section**
3. **Should show:**
   - Morpho Blue: 12.0% APY
   - Aave v3: 6.0% APY
   - Compound v3: 4.0% APY

#### Test 2: Check Browser Console

**Should see:**
```
✅ useReadContract: getAllAPYs → Success
✅ useReadContract: getActiveVaultsCount → 3
✅ Contract data loaded
```

#### Test 3: Verify Data Updates

- APYs should auto-refresh every 30 seconds
- Network tab should show periodic RPC calls

---

## 🐛 Troubleshooting

### Issue: "execution reverted" in console

**Cause:** Contracts not initialized with vault data

**Solution:** Run initialization script (Phase 2)

---

### Issue: No data showing in Active Yield Sources

**Possible causes:**

1. **Contracts not initialized:**
   - Run initialization script
   - Check Basescan to verify vaults were added

2. **Frontend using mock data:**
   - Update `YieldSources.tsx` to use `useAllVaultDetails()` hook
   - Check that hooks are being called

3. **RPC connection issue:**
   - Check browser console for RPC errors
   - Verify Base Sepolia RPC is responding:
     ```bash
     curl https://sepolia.base.org -X POST \
       -H "Content-Type: application/json" \
       -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
     ```

---

### Issue: Wallet not connecting

**Solutions:**

1. **Refresh the page**
2. **Check MetaMask:**
   - Make sure it's unlocked
   - Switch to Base Sepolia network
3. **Clear site data:**
   - DevTools → Application → Clear Storage
   - Refresh page

---

### Issue: Wrong network

**Solution:**

1. Open MetaMask
2. Click network dropdown
3. Select "Base Sepolia"
4. If not in list:
   - Click "Add Network"
   - Network Name: Base Sepolia
   - RPC URL: https://sepolia.base.org
   - Chain ID: 84532
   - Currency: ETH
   - Block Explorer: https://sepolia.basescan.org

---

## 📝 Testing Checklist

### Pre-Initialization Tests ✅

- [ ] Browser console shows no critical errors
- [ ] Wallet connects successfully
- [ ] Network shows "Base Sepolia" (green)
- [ ] UI renders all components
- [ ] Mock data displays correctly
- [ ] Configuration sliders work

### Post-Initialization Tests (After running script)

- [ ] Contracts have vault data
- [ ] Frontend loads real APYs
- [ ] Active Yield Sources shows 3 vaults
- [ ] APYs match: Morpho 12%, Aave 6%, Compound 4%
- [ ] Risk scores display correctly
- [ ] Data auto-refreshes every 30s
- [ ] No console errors

### Advanced Tests (For later)

- [ ] Create a test pool using YieldShiftFactory
- [ ] Configure pool parameters
- [ ] Add liquidity to pool
- [ ] Perform test swap
- [ ] Verify beforeSwap hook executes
- [ ] Check capital shifted to vault
- [ ] Wait for harvest (after 10 swaps)
- [ ] Verify rewards compounded

---

## 🎯 What To Do Right Now

### Step 1: Check Browser Console (2 minutes)

Open DevTools (F12) and tell me:
1. Any red errors?
2. What do you see in Console tab?
3. Any contract call errors?

### Step 2: Initialize Contracts (5 minutes)

We need to populate your contracts with test data. You have two options:

**Option A: Quick (via script) - Recommended**
```bash
cd /Users/idjighereoghenerukevwesandra/Desktop/yieldshift
forge script script/InitializeContracts.s.sol:InitializeContracts \
    --rpc-url https://sepolia.base.org \
    --broadcast \
    -vvv
```

**Option B: Manual (via Basescan) - Slower**
- Follow the manual steps in Phase 2 above

### Step 3: Update Frontend (10 minutes)

After contracts are initialized, I'll help you update the frontend components to use real contract data instead of mock data.

### Step 4: Test Everything (15 minutes)

- Refresh browser
- Verify real data loads
- Test all features
- Check for errors

---

## 📊 Success Criteria

### You'll know everything is working when:

✅ Browser console shows no errors
✅ Active Yield Sources displays 3 vaults
✅ APYs show: Morpho 12%, Aave 6%, Compound 4%
✅ Risk scores match: 6, 3, 4
✅ Data refreshes automatically
✅ Pool stats load from contracts
✅ Activity feed shows "Live" indicator
✅ Configuration changes persist

---

## 🚀 Next Steps After Testing

1. **Create a Test Pool:**
   - Use YieldShiftFactory contract
   - Create ETH/USDC pool with YieldShift

2. **Add Test Liquidity:**
   - Provide liquidity to the pool
   - Get LP tokens

3. **Trigger Yield Shifting:**
   - Perform swaps on the pool
   - Watch beforeSwap hook execute
   - See capital shift to Morpho (highest APY)

4. **Monitor Harvesting:**
   - After 10 swaps, harvest should trigger
   - Check Activity Feed for harvest events
   - Verify rewards compounded

---

## 📞 Need Help?

**Share with me:**
1. Screenshots of browser console
2. Any error messages
3. What step you're stuck on

**I can help with:**
- Running initialization script
- Updating frontend code
- Debugging contract calls
- Testing specific features

---

**Ready to start testing! Let's begin with Step 1: Check your browser console and tell me what you see. 🚀**
