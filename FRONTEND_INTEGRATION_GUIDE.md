# YieldShift Frontend Integration Guide
Quick reference for frontend developers integrating with YieldShift contracts

---

## 🚀 Quick Start

### 1. Contract Addresses (Update after deployment)

```typescript
export const CONTRACTS = {
  YieldShiftHook: "0x...",
  YieldOracle: "0x...",
  YieldRouter: "0x...",
  YieldShiftFactory: "0x...",
  // Adapters
  AaveAdapter: "0x...",
  MorphoAdapter: "0x...",
  CompoundAdapter: "0x...",
};
```

### 2. Import ABIs

```typescript
import YieldShiftHookABI from './abi/YieldShiftHook.json';
import YieldOracleABI from './abi/YieldOracle.json';
import YieldRouterABI from './abi/YieldRouter.json';
```

ABIs are located in: `out/{ContractName}.sol/{ContractName}.json`

---

## 📖 Common Use Cases

### Use Case 1: Display Pool Information

```typescript
// Get pool state for UI display
async function getPoolInfo(poolId: string) {
  const hook = new ethers.Contract(CONTRACTS.YieldShiftHook, YieldShiftHookABI, provider);

  // Get current state
  const state = await hook.getPoolState(poolId);

  // Get best yield
  const [bestVault, bestAPY] = await hook.getCurrentBestYield(poolId);

  return {
    totalShifted: ethers.formatUnits(state.totalShifted, 6), // USDC has 6 decimals
    totalHarvested: ethers.formatUnits(state.totalHarvested, 6),
    swapCount: state.swapCount.toString(),
    lastHarvestTime: new Date(state.lastHarvestTime.toNumber() * 1000),
    bestVault,
    bestAPY: (bestAPY.toNumber() / 100).toFixed(2) + '%', // Convert bps to %
  };
}
```

### Use Case 2: Display Available Vaults & APYs

```typescript
// Get all available yield sources
async function getAllYieldSources() {
  const oracle = new ethers.Contract(CONTRACTS.YieldOracle, YieldOracleABI, provider);

  const result = await oracle.getAllAPYs();
  const vaults = result[0];
  const apys = result[1];

  return vaults.map((vault, i) => ({
    address: vault,
    apy: (apys[i].toNumber() / 100).toFixed(2) + '%',
  }));
}
```

### Use Case 3: Configure a Pool (Admin Only)

```typescript
// Admin configuration form submission
async function configurePool(poolId: string, config: PoolConfig) {
  const hook = new ethers.Contract(
    CONTRACTS.YieldShiftHook,
    YieldShiftHookABI,
    signer
  );

  const tx = await hook.configurePool(poolId, {
    admin: config.adminAddress,
    shiftPercentage: config.shiftPercentage, // 10-50
    harvestFrequency: config.harvestFrequency, // Number of swaps
    minAPYThreshold: config.minAPY * 100, // Convert % to bps (5% → 500)
    riskTolerance: config.riskTolerance, // 1-10
    isPaused: config.isPaused || false,
  });

  await tx.wait();
  return tx.hash;
}
```

### Use Case 4: Emergency Pause (Admin Only)

```typescript
// Emergency stop button
async function pausePool(poolId: string) {
  const hook = new ethers.Contract(
    CONTRACTS.YieldShiftHook,
    YieldShiftHookABI,
    signer
  );

  const tx = await hook.pauseShifting(poolId);
  await tx.wait();

  // Optionally listen for event
  hook.once('EmergencyPause', (emittedPoolId, isPaused) => {
    console.log(`Pool ${emittedPoolId} paused: ${isPaused}`);
  });
}
```

---

## 🎧 Event Listeners

### Real-time Updates

```typescript
const hook = new ethers.Contract(
  CONTRACTS.YieldShiftHook,
  YieldShiftHookABI,
  provider
);

// Listen for pool configuration changes
hook.on('PoolConfigured', (poolId, admin) => {
  console.log(`Pool ${poolId} configured by ${admin}`);
  // Update UI
});

// Listen for vault deposits
hook.on('VaultDeposit', (vault, amount, shares) => {
  console.log(`Deposited ${ethers.formatUnits(amount, 6)} USDC to ${vault}`);
  // Show notification
});

// Listen for harvests
hook.on('Harvested', (vault, rewards) => {
  console.log(`Harvested ${ethers.formatUnits(rewards, 6)} USDC from ${vault}`);
  // Update rewards display
});

// Listen for emergencies
hook.on('EmergencyPause', (poolId, isPaused) => {
  if (isPaused) {
    // Show warning banner
    alert(`Pool ${poolId} has been paused!`);
  }
});
```

---

## 🎨 UI Components Examples

### Pool Stats Card

```tsx
function PoolStatsCard({ poolId }: { poolId: string }) {
  const [stats, setStats] = useState(null);

  useEffect(() => {
    async function loadStats() {
      const hook = new ethers.Contract(
        CONTRACTS.YieldShiftHook,
        YieldShiftHookABI,
        provider
      );

      const state = await hook.getPoolState(poolId);
      const [vault, apy] = await hook.getCurrentBestYield(poolId);

      setStats({
        totalShifted: ethers.formatUnits(state.totalShifted, 6),
        totalHarvested: ethers.formatUnits(state.totalHarvested, 6),
        bestAPY: (apy.toNumber() / 100).toFixed(2),
        bestVault: vault,
      });
    }

    loadStats();
    const interval = setInterval(loadStats, 30000); // Refresh every 30s
    return () => clearInterval(interval);
  }, [poolId]);

  if (!stats) return <div>Loading...</div>;

  return (
    <div className="stats-card">
      <h3>Pool Performance</h3>
      <div className="stat">
        <label>Total Shifted to Yield:</label>
        <value>{stats.totalShifted} USDC</value>
      </div>
      <div className="stat">
        <label>Total Harvested:</label>
        <value>{stats.totalHarvested} USDC</value>
      </div>
      <div className="stat">
        <label>Best APY Available:</label>
        <value>{stats.bestAPY}%</value>
      </div>
    </div>
  );
}
```

### Vault Comparison Table

```tsx
function VaultComparison() {
  const [vaults, setVaults] = useState([]);

  useEffect(() => {
    async function loadVaults() {
      const oracle = new ethers.Contract(
        CONTRACTS.YieldOracle,
        YieldOracleABI,
        provider
      );

      const result = await oracle.getAllAPYs();
      const vaultAddresses = result[0];
      const apys = result[1];

      setVaults(
        vaultAddresses.map((addr, i) => ({
          address: addr,
          name: getVaultName(addr), // Your mapping function
          apy: (apys[i].toNumber() / 100).toFixed(2),
        }))
      );
    }

    loadVaults();
  }, []);

  return (
    <table>
      <thead>
        <tr>
          <th>Protocol</th>
          <th>APY</th>
          <th>Risk Score</th>
        </tr>
      </thead>
      <tbody>
        {vaults.map((vault) => (
          <tr key={vault.address}>
            <td>{vault.name}</td>
            <td>{vault.apy}%</td>
            <td>{vault.riskScore}/10</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

---

## 🔐 Admin Dashboard Functions

### Admin Panel Component

```tsx
function AdminPanel({ poolId }: { poolId: string }) {
  const [isPaused, setIsPaused] = useState(false);

  async function handlePause() {
    const hook = new ethers.Contract(
      CONTRACTS.YieldShiftHook,
      YieldShiftHookABI,
      signer
    );

    const tx = await hook.pauseShifting(poolId);
    await tx.wait();
    setIsPaused(true);
  }

  async function handleEmergencyWithdraw() {
    if (!confirm('Are you sure? This will withdraw ALL funds from yield sources.')) {
      return;
    }

    const hook = new ethers.Contract(
      CONTRACTS.YieldShiftHook,
      YieldShiftHookABI,
      signer
    );

    const tx = await hook.emergencyWithdraw(poolId);
    await tx.wait();
    alert('Emergency withdrawal complete');
  }

  return (
    <div className="admin-panel">
      <h2>Admin Controls</h2>

      <button onClick={handlePause} disabled={isPaused}>
        {isPaused ? 'Already Paused' : 'Pause Shifting'}
      </button>

      <button
        onClick={handleEmergencyWithdraw}
        className="danger"
      >
        Emergency Withdraw
      </button>
    </div>
  );
}
```

---

## 🧪 Testing with Local Network

### Hardhat Local Setup

```typescript
// Deploy contracts locally
import { ethers } from 'hardhat';

async function deployContracts() {
  // Deploy oracle
  const Oracle = await ethers.getContractFactory('YieldOracle');
  const oracle = await Oracle.deploy();

  // Deploy router
  const Router = await ethers.getContractFactory('YieldRouter');
  const router = await Router.deploy();

  // Deploy hook
  const Hook = await ethers.getContractFactory('YieldShiftHook');
  const hook = await Hook.deploy(
    poolManager.address,
    oracle.address,
    router.address,
    compound.address
  );

  console.log('Contracts deployed:');
  console.log('Oracle:', oracle.address);
  console.log('Router:', router.address);
  console.log('Hook:', hook.address);

  return { oracle, router, hook };
}
```

---

## 📊 Data Formatting Helpers

```typescript
// Convert basis points to percentage
export function bpsToPercent(bps: number): string {
  return (bps / 100).toFixed(2) + '%';
}

// Format token amounts
export function formatUSDC(amount: bigint): string {
  return ethers.formatUnits(amount, 6);
}

// Format timestamp
export function formatTimestamp(timestamp: number): string {
  return new Date(timestamp * 1000).toLocaleString();
}

// Shorten address
export function shortenAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

// Calculate yield earned
export function calculateYield(
  principal: number,
  apy: number,
  timeInDays: number
): number {
  return (principal * (apy / 100) * timeInDays) / 365;
}
```

---

## ⚠️ Error Handling

### Common Errors & Solutions

```typescript
async function safeContractCall(fn: () => Promise<any>) {
  try {
    return await fn();
  } catch (error: any) {
    // Not authorized
    if (error.message.includes('Not admin')) {
      alert('You must be the pool admin to perform this action');
      return null;
    }

    // Pool not configured
    if (error.message.includes('Not configured')) {
      alert('This pool has not been configured yet');
      return null;
    }

    // Paused
    if (error.message.includes('Paused')) {
      alert('Pool is currently paused');
      return null;
    }

    // User rejected
    if (error.code === 4001) {
      console.log('User rejected transaction');
      return null;
    }

    // Generic error
    console.error('Contract call failed:', error);
    alert('Transaction failed. Please try again.');
    return null;
  }
}

// Usage
const result = await safeContractCall(async () => {
  const tx = await hook.pauseShifting(poolId);
  return await tx.wait();
});
```

---

## 🔄 Polling vs WebSockets

### Polling (Simple, works everywhere)

```typescript
// Update every 30 seconds
useEffect(() => {
  const update = async () => {
    const state = await hook.getPoolState(poolId);
    setPoolState(state);
  };

  update();
  const interval = setInterval(update, 30000);
  return () => clearInterval(interval);
}, [poolId]);
```

### WebSocket (Real-time, better UX)

```typescript
// Listen for events
useEffect(() => {
  const provider = new ethers.WebSocketProvider(WS_RPC_URL);
  const hook = new ethers.Contract(
    CONTRACTS.YieldShiftHook,
    YieldShiftHookABI,
    provider
  );

  hook.on('VaultDeposit', (vault, amount, shares) => {
    // Update UI immediately
    updatePoolState();
  });

  return () => {
    hook.removeAllListeners();
    provider.destroy();
  };
}, []);
```

---

## 📱 Mobile Responsive Considerations

```typescript
// Check if user is on mobile
const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

// Use appropriate polling interval
const POLL_INTERVAL = isMobile ? 60000 : 30000; // Mobile: 1min, Desktop: 30s

// Simplify UI for mobile
{isMobile ? (
  <SimplifiedStatsView poolId={poolId} />
) : (
  <DetailedDashboard poolId={poolId} />
)}
```

---

## 🎯 Performance Tips

1. **Cache Contract Instances**
   ```typescript
   const hookContract = useMemo(
     () => new ethers.Contract(address, abi, provider),
     [address, provider]
   );
   ```

2. **Batch Multiple Calls**
   ```typescript
   const [state, bestYield] = await Promise.all([
     hook.getPoolState(poolId),
     hook.getCurrentBestYield(poolId),
   ]);
   ```

3. **Use multicall for multiple reads**
   ```typescript
   import { Multicall } from '@ethersproject/providers';
   // Batch read calls to save RPC requests
   ```

4. **Optimize Re-renders**
   ```typescript
   // Use React.memo for expensive components
   const MemoizedChart = React.memo(PerformanceChart);
   ```

---

## 📚 Additional Resources

- **Contract Source:** `src/` directory
- **ABIs:** `out/` directory
- **Tests:** `test/` directory
- **Audit Report:** `AUDIT_REPORT.md`

---

## 💬 Support

For questions or issues:
1. Check the test files for usage examples
2. Review the audit report for security considerations
3. Examine the source code for implementation details

**Last Updated:** December 9, 2025
