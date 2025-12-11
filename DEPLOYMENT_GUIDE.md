# YieldShift Deployment Guide

**Last Updated:** December 9, 2025
**Target Network:** Base Sepolia / Base Mainnet
**Status:** ✅ Ready for Deployment

---

## 🎯 Pre-Deployment Checklist

### ✅ **Completed**

- [x] All contracts compile successfully
- [x] 97.8% test pass rate (45/46 tests)
- [x] Security audit completed (9.2/10 score)
- [x] Uniswap V4 PoolManager addresses obtained
- [x] Deployment scripts configured
- [x] Universal Router integration configured
- [x] Documentation updated

### ⚠️ **Required Before Deployment**

- [ ] Create `.env` file with private key
- [ ] Fund deployer wallet with ETH (for gas)
- [ ] Verify RPC endpoint connectivity
- [ ] (Optional) Obtain Basescan API key for verification

---

## 📋 Step-by-Step Deployment

### **Step 1: Environment Setup**

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit .env and add your private key
# DEPLOYER_PRIVATE_KEY=your_private_key_here

# 3. Verify your setup
forge build
```

### **Step 2: Fund Deployer Wallet**

**Estimated Gas Costs:**
- Base Sepolia: ~0.05 ETH (testnet)
- Base Mainnet: ~0.1-0.2 ETH (depending on gas prices)

**Get Testnet ETH:**
- Base Sepolia Faucet: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet
- Bridge from Ethereum Sepolia: https://bridge.base.org

### **Step 3: Deploy to Base Sepolia (Testnet)**

```bash
# Deploy all contracts
forge script script/DeployBase.s.sol:DeployBase \
    --rpc-url base_sepolia \
    --broadcast \
    --verify \
    -vvvv

# The script will automatically:
# ✅ Deploy YieldOracle
# ✅ Deploy YieldRouter
# ✅ Deploy YieldCompound (with PoolManager)
# ✅ Deploy all Adapters (Aave, Morpho, Compound, EigenLayer)
# ✅ Register adapters with router
# ✅ Add vaults to oracle with APY estimates
# ✅ Deploy YieldShiftHook
# ✅ Deploy YieldShiftFactory
# ✅ Configure authorizations
# ✅ Set Universal Router for swaps
```

**Expected Output:**
```
=== YieldShift Base Deployment ===
Deployer: 0x...
Chain ID: 84532
Pool Manager: 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
Universal Router: 0x492E6456D9528771018DeB9E87ef7750EF184104

Step 1: Deploying core infrastructure...
  YieldOracle: 0x...
  YieldRouter: 0x...
  YieldCompound: 0x...

Step 2: Deploying adapters...
  AaveAdapter: 0x...
  MorphoAdapter: 0x...
  CompoundAdapter: 0x...

Step 3: Registering adapters...
  Registered Aave adapter
  Registered Morpho adapter
  Registered Compound adapter

Step 4: Configuring oracle...
  Added Aave vault (risk: 3, APY: 6%)
  Added Morpho vault (risk: 6, APY: 12%)
  Added Compound vault (risk: 4, APY: 4%)

Step 5: Deploying hook and factory...
  YieldShiftHook: 0x...
  YieldShiftFactory: 0x...
  Authorized hook in router
  Authorized hook in compounder
  Configured swap router: 0x492E6456D9528771018DeB9E87ef7750EF184104

========================================
        DEPLOYMENT SUMMARY
========================================

Core Contracts:
  YieldOracle:       0x...
  YieldRouter:       0x...
  YieldCompound:     0x...

Adapters:
  AaveAdapter:       0x...
  MorphoAdapter:     0x...
  CompoundAdapter:   0x...

Hook & Factory:
  YieldShiftHook:    0x...
  YieldShiftFactory: 0x...
```

### **Step 4: Save Contract Addresses**

Copy the deployed addresses to your `.env` file:

```bash
# Update .env with deployed addresses
YIELD_ORACLE_ADDRESS=0x...
YIELD_ROUTER_ADDRESS=0x...
YIELD_COMPOUND_ADDRESS=0x...
YIELD_SHIFT_HOOK_ADDRESS=0x...
YIELD_SHIFT_FACTORY_ADDRESS=0x...
```

### **Step 5: Verify Contracts (if auto-verify failed)**

```bash
# Verify each contract individually if needed
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
    --chain-id 84532 \
    --etherscan-api-key $BASESCAN_API_KEY \
    --watch
```

---

## 🧪 Post-Deployment Testing

### **Test 1: Verify Oracle APYs**

```bash
cast call $YIELD_ORACLE_ADDRESS "getAllAPYs()" --rpc-url base_sepolia
```

### **Test 2: Check Router Adapters**

```bash
cast call $YIELD_ROUTER_ADDRESS "getVaultCount()" --rpc-url base_sepolia
```

### **Test 3: Test Best Yield Selection**

```bash
# Get best yield with risk tolerance 10
cast call $YIELD_ORACLE_ADDRESS "getBestYield(uint256)(address,uint256)" 10 --rpc-url base_sepolia
```

### **Test 4: Create Test Pool**

```bash
# Use SetupPool script to create initial pool
forge script script/SetupPool.s.sol:SetupPool \
    --rpc-url base_sepolia \
    --broadcast
```

---

## 🚀 Mainnet Deployment

**⚠️ IMPORTANT: Only deploy to mainnet after thorough testnet validation**

### **Pre-Mainnet Checklist**

- [ ] Complete testnet testing for at least 1 week
- [ ] Test all user flows (deposit, withdraw, harvest, compound)
- [ ] Monitor gas costs and optimize if needed
- [ ] Consider professional security audit
- [ ] Set up monitoring/alerting infrastructure
- [ ] Prepare incident response plan

### **Mainnet Deployment Command**

```bash
# Deploy to Base Mainnet (Chain ID: 8453)
forge script script/DeployBase.s.sol:DeployBase \
    --rpc-url base \
    --broadcast \
    --verify \
    -vvvv

# The script automatically detects mainnet and uses:
# PoolManager: 0x498581fF718922c3f8e6A244956aF099B2652b2b
# UniversalRouter: 0x6fF5693b99212Da76ad316178A184AB56D299b43
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Deployed System Architecture                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Uniswap V4 PoolManager (0x05E7...3408 on Sepolia)              │
│         ↓                                                        │
│  YieldShiftHook ──→ beforeSwap() → YieldOracle (get best APY)   │
│         │                  │                                     │
│         │                  ↓                                     │
│         │           YieldRouter → Adapters → Yield Protocols    │
│         │                                    (Aave, Morpho, etc)│
│         ↓                                                        │
│   afterSwap() → Harvest → YieldCompound → Universal Router      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Contract Addresses Reference

### **Base Sepolia (Testnet - Chain ID: 84532)**

| Contract | Address | Explorer |
|----------|---------|----------|
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` | [View](https://sepolia.basescan.org/address/0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408) |
| Universal Router | `0x492E6456D9528771018DeB9E87ef7750EF184104` | [View](https://sepolia.basescan.org/address/0x492E6456D9528771018DeB9E87ef7750EF184104) |
| Aave Pool | `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5` | [View](https://sepolia.basescan.org/address/0xA238Dd80C259a72e81d7e4664a9801593F98d1c5) |
| Morpho Blue | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` | [View](https://sepolia.basescan.org/address/0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb) |

### **Base Mainnet (Chain ID: 8453)**

| Contract | Address | Explorer |
|----------|---------|----------|
| PoolManager | `0x498581fF718922c3f8e6A244956aF099B2652b2b` | [View](https://basescan.org/address/0x498581fF718922c3f8e6A244956aF099B2652b2b) |
| Universal Router | `0x6fF5693b99212Da76ad316178A184AB56D299b43` | [View](https://basescan.org/address/0x6fF5693b99212Da76ad316178A184AB56D299b43) |

---

## 🔧 Troubleshooting

### **Issue: "Invalid PoolManager address"**

**Solution:** The script auto-detects based on chain ID. Ensure you're connected to Base Sepolia (84532) or Base Mainnet (8453).

### **Issue: "Insufficient funds for gas"**

**Solution:** Fund your deployer wallet with ETH. Minimum 0.05 ETH for testnet, 0.2 ETH for mainnet.

### **Issue: "Adapter registration failed"**

**Solution:** Check that the vault address is correct for the network you're deploying to. Morpho and Compound addresses may differ between testnet/mainnet.

### **Issue: "Contract verification failed"**

**Solution:**
```bash
# Manual verification
forge verify-contract <ADDRESS> src/YieldOracle.sol:YieldOracle \
    --chain-id 84532 \
    --etherscan-api-key $BASESCAN_API_KEY
```

---

## 📱 Frontend Integration

After deployment, update your frontend with the deployed addresses:

```typescript
// frontend/src/config/contracts.ts
export const CONTRACTS = {
  base_sepolia: {
    YieldOracle: "0x...",
    YieldRouter: "0x...",
    YieldShiftHook: "0x...",
    // ... add all deployed addresses
  }
};
```

See [FRONTEND_INTEGRATION_GUIDE.md](./FRONTEND_INTEGRATION_GUIDE.md) for complete integration instructions.

---

## 🛡️ Security Considerations

### **Before Mainnet:**

1. ✅ **Smart Contract Audit**: Already completed (9.2/10 score)
2. ⚠️ **Testnet Validation**: Run for 1+ week
3. ⚠️ **Bug Bounty**: Consider launching before mainnet
4. ⚠️ **Multi-sig**: Use multi-sig for admin functions on mainnet
5. ⚠️ **Monitoring**: Set up alerts for unusual activity

### **Admin Functions to Secure:**

- `YieldOracle.addVault()` - Only owner
- `YieldRouter.registerAdapter()` - Only owner
- `YieldShiftHook.pauseShifting()` - Pool admin
- `YieldShiftHook.emergencyWithdraw()` - Pool admin

**Recommendation:** Transfer ownership to multi-sig after deployment.

---

## 📈 Monitoring & Maintenance

### **Key Metrics to Track:**

1. **Total Value Locked (TVL)** in yield sources
2. **Harvested Rewards** per vault
3. **Gas costs** per operation
4. **APY changes** across protocols
5. **Error rates** on shifts/harvests

### **Regular Maintenance:**

- **Weekly:** Update APY estimates in oracle
- **Monthly:** Review and optimize gas usage
- **Quarterly:** Audit and update adapter implementations
- **As needed:** Add new yield sources

---

## 🎓 Next Steps After Deployment

1. **Test thoroughly** on Base Sepolia
2. **Monitor performance** for 1-2 weeks
3. **Gather feedback** from test users
4. **Optimize** based on real-world usage
5. **Deploy to mainnet** when ready
6. **Launch frontend** dashboard
7. **Market and grow** TVL

---

## 📞 Support

**Documentation:**
- [README.md](./README.md) - Project overview
- [AUDIT_REPORT.md](./AUDIT_REPORT.md) - Security audit
- [FRONTEND_INTEGRATION_GUIDE.md](./FRONTEND_INTEGRATION_GUIDE.md) - Frontend integration

**Resources:**
- Uniswap V4 Docs: https://docs.uniswap.org/contracts/v4
- Base Network Docs: https://docs.base.org
- Foundry Book: https://book.getfoundry.sh

---

**🚀 Ready to deploy! Good luck!**
