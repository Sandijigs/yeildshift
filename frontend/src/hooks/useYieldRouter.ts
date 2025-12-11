import { useReadContract, useReadContracts } from 'wagmi';
import { CONTRACTS, YIELD_ROUTER_ABI } from '../contracts';

/**
 * Hook to get all vaults from the Router
 */
export function useAllVaults() {
  return useReadContract({
    address: CONTRACTS.yieldRouter,
    abi: YIELD_ROUTER_ABI,
    functionName: 'getAllVaults',
    query: {
      refetchInterval: 30000,
    },
  });
}

/**
 * Hook to get total deposited in a vault
 */
export function useTotalDeposited(vaultAddress: string) {
  return useReadContract({
    address: CONTRACTS.yieldRouter,
    abi: YIELD_ROUTER_ABI,
    functionName: 'totalDeposited',
    args: [vaultAddress as `0x${string}`],
    query: {
      enabled: !!vaultAddress && vaultAddress !== '0x0000000000000000000000000000000000000000',
      refetchInterval: 30000,
    },
  });
}

/**
 * Hook to get total harvested from a vault
 */
export function useTotalHarvested(vaultAddress: string) {
  return useReadContract({
    address: CONTRACTS.yieldRouter,
    abi: YIELD_ROUTER_ABI,
    functionName: 'totalHarvested',
    args: [vaultAddress as `0x${string}`],
    query: {
      enabled: !!vaultAddress && vaultAddress !== '0x0000000000000000000000000000000000000000',
      refetchInterval: 30000,
    },
  });
}

/**
 * Hook to get detailed stats for all vaults
 */
export function useAllVaultStats() {
  const { data: vaults, isLoading: vaultsLoading } = useAllVaults();

  const depositCalls = (vaults || []).map((vault) => ({
    address: CONTRACTS.yieldRouter,
    abi: YIELD_ROUTER_ABI,
    functionName: 'totalDeposited',
    args: [vault],
  }));

  const harvestCalls = (vaults || []).map((vault) => ({
    address: CONTRACTS.yieldRouter,
    abi: YIELD_ROUTER_ABI,
    functionName: 'totalHarvested',
    args: [vault],
  }));

  const { data: depositsData, isLoading: depositsLoading } = useReadContracts({
    contracts: depositCalls as any,
    query: {
      enabled: (vaults?.length || 0) > 0,
    },
  });

  const { data: harvestsData, isLoading: harvestsLoading } = useReadContracts({
    contracts: harvestCalls as any,
    query: {
      enabled: (vaults?.length || 0) > 0,
    },
  });

  const stats = (vaults || []).map((vault, index) => ({
    address: vault,
    totalDeposited: (depositsData?.[index]?.result as bigint) || 0n,
    totalHarvested: (harvestsData?.[index]?.result as bigint) || 0n,
  }));

  return {
    stats,
    isLoading: vaultsLoading || depositsLoading || harvestsLoading,
  };
}

/**
 * Utility to format token amounts (assuming 6 decimals for USDC)
 */
export function formatTokenAmount(amount: bigint | undefined, decimals: number = 6): string {
  if (!amount) return '0.00';
  const divisor = BigInt(10 ** decimals);
  const whole = amount / divisor;
  const remainder = amount % divisor;
  const decimal = remainder.toString().padStart(decimals, '0').slice(0, 2);
  return `${whole.toLocaleString()}.${decimal}`;
}

/**
 * Utility to format large numbers with K, M, B suffixes
 */
export function formatCompact(amount: bigint | undefined, decimals: number = 6): string {
  if (!amount) return '$0';

  const num = Number(amount) / 10 ** decimals;

  if (num >= 1_000_000_000) {
    return `$${(num / 1_000_000_000).toFixed(2)}B`;
  }
  if (num >= 1_000_000) {
    return `$${(num / 1_000_000).toFixed(2)}M`;
  }
  if (num >= 1_000) {
    return `$${(num / 1_000).toFixed(2)}K`;
  }
  return `$${num.toFixed(2)}`;
}
