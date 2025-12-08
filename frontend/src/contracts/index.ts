// Contract addresses - UPDATE AFTER DEPLOYMENT
export const CONTRACTS = {
  // Base Sepolia addresses (update after deployment)
  yieldOracle: '0x0000000000000000000000000000000000000000',
  yieldRouter: '0x0000000000000000000000000000000000000000',
  yieldCompound: '0x0000000000000000000000000000000000000000',
  yieldShiftHook: '0x0000000000000000000000000000000000000000',
  yieldShiftFactory: '0x0000000000000000000000000000000000000000',
};

// Chain configuration
export const CHAIN_ID = 84532; // Base Sepolia

// YieldOracle ABI (simplified for frontend)
export const YIELD_ORACLE_ABI = [
  {
    name: 'getAPY',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'vault', type: 'address' }],
    outputs: [{ name: 'apy', type: 'uint256' }],
  },
  {
    name: 'getBestYield',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'riskTolerance', type: 'uint256' }],
    outputs: [
      { name: 'bestVault', type: 'address' },
      { name: 'bestAPY', type: 'uint256' },
    ],
  },
  {
    name: 'getAllAPYs',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [
      { name: 'vaults', type: 'address[]' },
      { name: 'apys', type: 'uint256[]' },
    ],
  },
  {
    name: 'getActiveVaultsCount',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'getVaultConfig',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'vault', type: 'address' }],
    outputs: [
      {
        name: '',
        type: 'tuple',
        components: [
          { name: 'vaultAddress', type: 'address' },
          { name: 'priceOracle', type: 'address' },
          { name: 'riskScore', type: 'uint256' },
          { name: 'isWhitelisted', type: 'bool' },
        ],
      },
    ],
  },
] as const;

// YieldRouter ABI
export const YIELD_ROUTER_ABI = [
  {
    name: 'totalDeposited',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'vault', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'totalHarvested',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'vault', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'getAllVaults',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'address[]' }],
  },
  {
    name: 'getAPY',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'vault', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
] as const;

// YieldShiftHook ABI
export const YIELD_SHIFT_HOOK_ABI = [
  {
    name: 'getPoolState',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'poolId', type: 'bytes32' }],
    outputs: [
      { name: 'totalShifted', type: 'uint256' },
      { name: 'totalHarvested', type: 'uint256' },
      { name: 'swapCount', type: 'uint256' },
      { name: 'lastHarvestTime', type: 'uint256' },
      { name: 'activeVaults', type: 'address[]' },
    ],
  },
  {
    name: 'poolConfigs',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'poolId', type: 'bytes32' }],
    outputs: [
      {
        name: '',
        type: 'tuple',
        components: [
          { name: 'shiftPercentage', type: 'uint8' },
          { name: 'minAPYThreshold', type: 'uint16' },
          { name: 'harvestFrequency', type: 'uint8' },
          { name: 'riskTolerance', type: 'uint8' },
          { name: 'isPaused', type: 'bool' },
          { name: 'admin', type: 'address' },
        ],
      },
    ],
  },
  {
    name: 'YieldShifted',
    type: 'event',
    inputs: [
      { name: 'poolId', type: 'bytes32', indexed: true },
      { name: 'vault', type: 'address', indexed: true },
      { name: 'amount', type: 'uint256', indexed: false },
      { name: 'apy', type: 'uint256', indexed: false },
    ],
  },
  {
    name: 'RewardsHarvested',
    type: 'event',
    inputs: [
      { name: 'poolId', type: 'bytes32', indexed: true },
      { name: 'amount', type: 'uint256', indexed: false },
    ],
  },
] as const;

// Vault name mapping
export const VAULT_NAMES: Record<string, string> = {
  '0xA238Dd80C259a72e81d7e4664a9801593F98d1c5': 'Aave v3 (USDC)',
  '0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb': 'Morpho Blue',
  '0xb125E6687d4313864e53df431d5425969c15Eb2F': 'Compound v3 (USDC)',
};

// Risk score labels
export const RISK_LABELS: Record<number, string> = {
  1: 'Very Low',
  2: 'Very Low',
  3: 'Low',
  4: 'Low-Medium',
  5: 'Medium',
  6: 'Medium',
  7: 'Medium-High',
  8: 'High',
  9: 'High',
  10: 'Very High',
};
