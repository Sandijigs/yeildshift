import { useReadContract, useReadContracts } from 'wagmi';
import { CONTRACTS, YIELD_ORACLE_ABI } from '../contracts';

/**
 * Hook to get all APYs from the YieldOracle
 */
export function useAllAPYs() {
  return useReadContract({
    address: CONTRACTS.yieldOracle,
    abi: YIELD_ORACLE_ABI,
    functionName: 'getAllAPYs',
    query: {
      refetchInterval: 30000, // Refetch every 30 seconds
    },
  });
}

/**
 * Hook to get the best yield for a given risk tolerance
 */
export function useBestYield(riskTolerance: number = 10) {
  return useReadContract({
    address: CONTRACTS.yieldOracle,
    abi: YIELD_ORACLE_ABI,
    functionName: 'getBestYield',
    args: [BigInt(riskTolerance)],
    query: {
      refetchInterval: 30000,
    },
  });
}

/**
 * Hook to get APY for a specific vault
 */
export function useVaultAPY(vaultAddress: string) {
  return useReadContract({
    address: CONTRACTS.yieldOracle,
    abi: YIELD_ORACLE_ABI,
    functionName: 'getAPY',
    args: [vaultAddress as `0x${string}`],
    query: {
      enabled: !!vaultAddress && vaultAddress !== '0x0000000000000000000000000000000000000000',
    },
  });
}

/**
 * Hook to get vault configuration
 */
export function useVaultConfig(vaultAddress: string) {
  return useReadContract({
    address: CONTRACTS.yieldOracle,
    abi: YIELD_ORACLE_ABI,
    functionName: 'getVaultConfig',
    args: [vaultAddress as `0x${string}`],
    query: {
      enabled: !!vaultAddress && vaultAddress !== '0x0000000000000000000000000000000000000000',
    },
  });
}

/**
 * Hook to get active vaults count
 */
export function useActiveVaultsCount() {
  return useReadContract({
    address: CONTRACTS.yieldOracle,
    abi: YIELD_ORACLE_ABI,
    functionName: 'getActiveVaultsCount',
    query: {
      refetchInterval: 60000, // Refetch every minute
    },
  });
}

/**
 * Hook to get all vault details (APYs + Configs)
 */
export function useAllVaultDetails() {
  const { data: apyData, isLoading: apysLoading } = useAllAPYs();

  const vaults = apyData?.[0] || [];
  const apys = apyData?.[1] || [];

  // Get config for each vault
  const configCalls = vaults.map((vault) => ({
    address: CONTRACTS.yieldOracle,
    abi: YIELD_ORACLE_ABI,
    functionName: 'getVaultConfig',
    args: [vault],
  }));

  const { data: configsData, isLoading: configsLoading } = useReadContracts({
    contracts: configCalls as any,
    query: {
      enabled: vaults.length > 0,
    },
  });

  const vaultDetails = vaults.map((vault, index) => {
    const config = configsData?.[index]?.result as any;
    return {
      address: vault,
      apy: apys[index],
      riskScore: config?.riskScore || 0n,
      isWhitelisted: config?.isWhitelisted || false,
    };
  });

  return {
    vaults: vaultDetails,
    isLoading: apysLoading || configsLoading,
  };
}

/**
 * Utility function to format APY from basis points
 */
export function formatAPY(apy: bigint | undefined): string {
  if (!apy) return '0.00';
  return (Number(apy) / 100).toFixed(2);
}

/**
 * Utility function to get risk label
 */
export function getRiskLabel(riskScore: bigint | number): string {
  const score = typeof riskScore === 'bigint' ? Number(riskScore) : riskScore;

  if (score <= 2) return 'Very Low';
  if (score <= 3) return 'Low';
  if (score <= 5) return 'Medium';
  if (score <= 7) return 'Medium-High';
  return 'High';
}

/**
 * Utility function to get risk color
 */
export function getRiskColor(riskScore: bigint | number): string {
  const score = typeof riskScore === 'bigint' ? Number(riskScore) : riskScore;

  if (score <= 3) return 'text-green-600';
  if (score <= 5) return 'text-yellow-600';
  if (score <= 7) return 'text-orange-600';
  return 'text-red-600';
}
