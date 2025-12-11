# YieldShift Deployed Contracts

**Network:** Base Sepolia Testnet
**Chain ID:** 84532
**Deployment Date:** December 9, 2025
**Deployer:** `0xeEA4353FE0641fA7730e1c9Bc7cC0f969ECd5914`

---

## 🎯 Core Contracts

| Contract | Address | Explorer |
|----------|---------|----------|
| **YieldOracle** | `0x554dc44df2AA9c718F6388ef057282893f31C04C` | [View on Basescan](https://sepolia.basescan.org/address/0x554dc44df2AA9c718F6388ef057282893f31C04C) |
| **YieldRouter** | `0xEe1fFe183002c22607E84A335d29fa2E94538ffc` | [View on Basescan](https://sepolia.basescan.org/address/0xEe1fFe183002c22607E84A335d29fa2E94538ffc) |
| **YieldCompound** | `0x4E0C6E13eAee2C879D075c285b31272AE6b3967C` | [View on Basescan](https://sepolia.basescan.org/address/0x4E0C6E13eAee2C879D075c285b31272AE6b3967C) |

## 🪝 Hook & Factory

| Contract | Address | Explorer |
|----------|---------|----------|
| **YieldShiftHook** ⭐ | `0x4f2cD1d5Af1C5bf691133A8560eab1ACCF90C0c0` | [View on Basescan](https://sepolia.basescan.org/address/0x4f2cD1d5Af1C5bf691133A8560eab1ACCF90C0c0) |
| **YieldShiftFactory** | `0xD81BAd11a4710d3038E8753FF229e760E21aAE0E` | [View on Basescan](https://sepolia.basescan.org/address/0xD81BAd11a4710d3038E8753FF229e760E21aAE0E) |

## 🔌 Adapters

| Protocol | Adapter Address | Explorer |
|----------|----------------|----------|
| **Aave v3** | `0x605F80DcFd708465474E9D130b5c06202e79e2c6` | [View](https://sepolia.basescan.org/address/0x605F80DcFd708465474E9D130b5c06202e79e2c6) |
| **Morpho Blue** | `0xCB5d6d80535a5F50f33C457eEf4ca2E9F712E864` | [View](https://sepolia.basescan.org/address/0xCB5d6d80535a5F50f33C457eEf4ca2E9F712E864) |
| **Compound v3** | `0x99907915Ef1836a00ce88061B75B2cfC4537B5A6` | [View](https://sepolia.basescan.org/address/0x99907915Ef1836a00ce88061B75B2cfC4537B5A6) |

---

## 📋 Configuration Details

### Registered Vaults

1. **Aave Pool**
   - Address: `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5`
   - APY: 6.00% (600 bps)
   - Risk Score: 3 (Low)

2. **Morpho Blue**
   - Address: `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb`
   - APY: 12.00% (1200 bps)
   - Risk Score: 6 (Medium)

3. **Compound Comet USDC**
   - Address: `0xb125E6687d4313864e53df431d5425969c15Eb2F`
   - APY: 4.00% (400 bps)
   - Risk Score: 4 (Low-Medium)

### Authorizations

- ✅ YieldShiftHook authorized in YieldRouter
- ✅ YieldShiftHook authorized in YieldCompound
- ✅ Universal Router (`0x492E6456D9528771018DeB9E87ef7750EF184104`) configured for swaps

---

## 🔐 CREATE2 Deployment Details

- **Salt:** `4667`
- **CREATE2 Deployer:** `0x4e59b44847b379578588920cA78FbF26c0B4956C`
- **Hook Permissions:** beforeSwap + afterSwap (flags: 192)
- **Mined Address:** `0x4f2cD1d5Af1C5bf691133A8560eab1ACCF90C0c0` ✅

---

## 🧪 Testing the Deployment

### Check Oracle APYs
```bash
cast call 0x554dc44df2AA9c718F6388ef057282893f31C04C \
  "getAllAPYs()" \
  --rpc-url https://sepolia.base.org
```

### Check Router Adapters
```bash
cast call 0xEe1fFe183002c22607E84A335d29fa2E94538ffc \
  "getVaultCount()" \
  --rpc-url https://sepolia.base.org
```

### Get Best Yield (Risk Tolerance: 10)
```bash
cast call 0x554dc44df2AA9c718F6388ef057282893f31C04C \
  "getBestYield(uint256)(address,uint256)" \
  10 \
  --rpc-url https://sepolia.base.org
```

---

## 📝 Contract Verification

Verify contracts on Basescan using:

```bash
# Example for YieldOracle
forge verify-contract \
  0x554dc44df2AA9c718F6388ef057282893f31C04C \
  src/YieldOracle.sol:YieldOracle \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY \
  --watch
```

---

## 🚀 Next Steps

1. ✅ **Deployment Complete**
2. ⏳ **Verify Contracts** on Basescan
3. ⏳ **Test Contract Interactions**
4. ⏳ **Update Frontend** with these addresses
5. ⏳ **Create Initial Pool** using YieldShiftFactory
6. ⏳ **Monitor Performance** on testnet

---

## 📊 Gas Usage

| Operation | Gas Used | USD Cost (est) |
|-----------|----------|----------------|
| Total Deployment | ~19,706,821 gas | ~$0.03 |

---

## ⚠️ Important Notes

- This is a **testnet deployment** on Base Sepolia
- All contracts use official Uniswap V4 addresses
- Hook address was mined using CREATE2 to match permission flags
- All adapters are registered and vaults configured
- System is ready for testing

---

**Deployment Status:** ✅ **SUCCESSFUL**

For mainnet deployment, see [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
