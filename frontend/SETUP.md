# YieldShift Frontend Setup Guide

This guide will help you set up and run the YieldShift frontend dashboard.

## 📋 Prerequisites

- Node.js v18+ installed
- npm or yarn package manager
- A Web3 wallet (MetaMask, Rainbow, Coinbase Wallet, etc.)
- Base Sepolia testnet ETH (for testing)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Environment Setup

The `.env` file is already configured with:
- ✅ WalletConnect Project ID
- ✅ Deployed contract addresses
- ✅ Base Sepolia RPC URL

**No additional configuration needed!**

### 3. Start Development Server

```bash
npm start
```

The app will open at `http://localhost:3000`

## 🔧 What's Included

### Installed Packages

- **React 18** - UI framework
- **Wagmi v2** - React hooks for Ethereum
- **RainbowKit** - Beautiful wallet connection
- **TanStack Query** - Data fetching and caching
- **Viem** - TypeScript Ethereum library
- **Recharts** - Charts for APY visualization
- **Tailwind CSS** - Utility-first styling

### Custom Hooks

**`useYieldOracle.ts`**
- `useAllAPYs()` - Get all vault APYs
- `useBestYield(riskTolerance)` - Get best yield source
- `useVaultAPY(address)` - Get specific vault APY
- `useAllVaultDetails()` - Get comprehensive vault data

**`useYieldRouter.ts`**
- `useAllVaults()` - Get all registered vaults
- `useTotalDeposited(vault)` - Get total deposited
- `useTotalHarvested(vault)` - Get total harvested
- `useAllVaultStats()` - Get stats for all vaults

**`useYieldShiftHook.ts`**
- `usePoolState(poolId)` - Get pool state data
- `usePoolConfig(poolId)` - Get pool configuration
- `useYieldShiftedEvents()` - Watch yield shift events
- `useRewardsHarvestedEvents()` - Watch harvest events
- `useActivityFeed()` - Combined activity feed

## 📱 Features

### Dashboard Components

1. **Connection Status**
   - Network indicator (Base Sepolia)
   - Wallet connection via RainbowKit
   - Address display

2. **Pool Stats**
   - Total value shifted
   - Total rewards harvested
   - Swap count
   - Last harvest time

3. **Yield Sources**
   - Real-time APY display
   - Risk scores
   - Active/inactive status
   - Vault addresses with explorer links

4. **Activity Feed**
   - Live event monitoring
   - Yield shifted events
   - Rewards harvested events
   - Real-time updates

5. **Configuration Panel**
   - Pool settings
   - Admin controls (if connected as admin)

## 🧪 Testing the Frontend

### With Deployed Contracts

The frontend is pre-configured to connect to the verified contracts on Base Sepolia:

```
Oracle:   0xCB5d6d80535a5F50f33C457eEf4ca2E9F712E864
Router:   0x99907915Ef1836a00ce88061B75B2cfC4537B5A6
Compound: 0x35b95450Eaab790de5a8067064B9ce75a57d4d8f
Hook:     0xE0122CF1AbC59977a8F1DC1A02B36c678d5F40C0
Factory:  0x3a07Ba4489d9aB8BFdc750C0cf0e41cD1f9baf46
```

### Test Steps

1. **Connect Wallet**
   - Click "Connect Wallet"
   - Select your wallet (MetaMask, Rainbow, etc.)
   - Approve connection
   - Ensure you're on Base Sepolia network

2. **View Yield Sources**
   - Should see 3 active vaults
   - Morpho Blue: ~12% APY
   - Aave v3: ~6% APY
   - Compound v3: ~4% APY

3. **Monitor Activity**
   - Activity feed shows real-time events
   - Watch for YieldShifted events
   - Watch for RewardsHarvested events

## 🎨 Customization

### Update Contract Addresses

Edit `src/contracts/index.ts`:

```typescript
export const CONTRACTS = {
  yieldOracle: 'YOUR_ORACLE_ADDRESS',
  yieldRouter: 'YOUR_ROUTER_ADDRESS',
  // ... etc
};
```

### Change Network

Edit `src/App.tsx`:

```typescript
import { baseSepolia, base } from 'wagmi/chains';

// For mainnet:
chains: [base],
transports: {
  [base.id]: http('https://mainnet.base.org'),
}
```

### Styling

The app uses Tailwind CSS. Customize in:
- `tailwind.config.js` - Theme configuration
- `src/index.css` - Global styles
- Component files - Component-specific styles

## 📊 Data Flow

```
User Wallet
    ↓
RainbowKit (Wallet Connection)
    ↓
Wagmi Hooks (Contract Interaction)
    ↓
Custom Hooks (Data Processing)
    ↓
React Components (UI Display)
```

## 🔍 Debugging

### Check Contract Connection

Open browser console and check for:
- Network connection errors
- RPC endpoint issues
- Contract read failures

### Common Issues

**Issue: "Network mismatch"**
- Solution: Switch to Base Sepolia in your wallet

**Issue: "Contract read failed"**
- Solution: Check RPC URL in App.tsx
- Ensure contracts are deployed and verified

**Issue: "No data displaying"**
- Solution: Check browser console for errors
- Verify contract addresses are correct
- Ensure wallet is connected

## 📚 Additional Resources

- [Wagmi Documentation](https://wagmi.sh)
- [RainbowKit Docs](https://www.rainbowkit.com)
- [Base Network Docs](https://docs.base.org)
- [Uniswap V4 Docs](https://docs.uniswap.org/contracts/v4)

## 🚀 Production Build

```bash
npm run build
```

Outputs optimized build to `build/` directory.

### Deploy Options

- **Vercel**: `vercel deploy`
- **Netlify**: `netlify deploy`
- **IPFS**: Use Fleek or similar
- **Traditional hosting**: Upload `build/` folder

## 🎯 Next Steps

1. ✅ Install dependencies: `npm install`
2. ✅ Start dev server: `npm start`
3. ✅ Connect wallet
4. ✅ View live APY data
5. 🔄 Create your first pool (coming soon)
6. 🔄 Add liquidity and test swaps

---

**Ready to run!** The frontend is fully configured and ready to connect to your deployed contracts.

```bash
cd frontend
npm install
npm start
```

Enjoy YieldShift! 🚀
