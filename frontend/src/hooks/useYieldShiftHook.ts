import { useReadContract, useWatchContractEvent } from 'wagmi';
import { useState, useEffect } from 'react';
import { CONTRACTS, YIELD_SHIFT_HOOK_ABI } from '../contracts';

/**
 * Hook to get pool state
 */
export function usePoolState(poolId: string) {
  return useReadContract({
    address: CONTRACTS.yieldShiftHook,
    abi: YIELD_SHIFT_HOOK_ABI,
    functionName: 'getPoolState',
    args: [poolId as `0x${string}`],
    query: {
      enabled: !!poolId && poolId !== '0x0000000000000000000000000000000000000000000000000000000000000000',
      refetchInterval: 15000, // Refetch every 15 seconds
    },
  });
}

/**
 * Hook to get pool configuration
 */
export function usePoolConfig(poolId: string) {
  return useReadContract({
    address: CONTRACTS.yieldShiftHook,
    abi: YIELD_SHIFT_HOOK_ABI,
    functionName: 'poolConfigs',
    args: [poolId as `0x${string}`],
    query: {
      enabled: !!poolId && poolId !== '0x0000000000000000000000000000000000000000000000000000000000000000',
      refetchInterval: 30000,
    },
  });
}

/**
 * Hook to watch YieldShifted events
 */
export function useYieldShiftedEvents() {
  const [events, setEvents] = useState<any[]>([]);

  useWatchContractEvent({
    address: CONTRACTS.yieldShiftHook,
    abi: YIELD_SHIFT_HOOK_ABI,
    eventName: 'YieldShifted',
    onLogs(logs) {
      const newEvents = logs.map((log) => ({
        poolId: log.args.poolId,
        vault: log.args.vault,
        amount: log.args.amount,
        apy: log.args.apy,
        timestamp: new Date(),
        blockNumber: log.blockNumber,
      }));
      setEvents((prev) => [...newEvents, ...prev].slice(0, 50)); // Keep last 50 events
    },
  });

  return events;
}

/**
 * Hook to watch RewardsHarvested events
 */
export function useRewardsHarvestedEvents() {
  const [events, setEvents] = useState<any[]>([]);

  useWatchContractEvent({
    address: CONTRACTS.yieldShiftHook,
    abi: YIELD_SHIFT_HOOK_ABI,
    eventName: 'RewardsHarvested',
    onLogs(logs) {
      const newEvents = logs.map((log) => ({
        poolId: log.args.poolId,
        amount: log.args.amount,
        timestamp: new Date(),
        blockNumber: log.blockNumber,
      }));
      setEvents((prev) => [...newEvents, ...prev].slice(0, 50));
    },
  });

  return events;
}

/**
 * Hook to get combined activity feed
 */
export function useActivityFeed() {
  const yieldShiftedEvents = useYieldShiftedEvents();
  const rewardsHarvestedEvents = useRewardsHarvestedEvents();

  const [combinedEvents, setCombinedEvents] = useState<any[]>([]);

  useEffect(() => {
    const allEvents = [
      ...yieldShiftedEvents.map((e) => ({ ...e, type: 'YieldShifted' })),
      ...rewardsHarvestedEvents.map((e) => ({ ...e, type: 'RewardsHarvested' })),
    ].sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());

    setCombinedEvents(allEvents.slice(0, 20)); // Keep last 20 events
  }, [yieldShiftedEvents, rewardsHarvestedEvents]);

  return combinedEvents;
}

/**
 * Parse pool state data
 */
export interface PoolStateData {
  totalShifted: bigint;
  totalHarvested: bigint;
  swapCount: bigint;
  lastHarvestTime: bigint;
  activeVaults: string[];
}

export function parsePoolState(data: any): PoolStateData | null {
  if (!data) return null;

  return {
    totalShifted: data[0] || 0n,
    totalHarvested: data[1] || 0n,
    swapCount: data[2] || 0n,
    lastHarvestTime: data[3] || 0n,
    activeVaults: data[4] || [],
  };
}

/**
 * Parse pool config data
 */
export interface PoolConfigData {
  shiftPercentage: number;
  minAPYThreshold: number;
  harvestFrequency: number;
  riskTolerance: number;
  isPaused: boolean;
  admin: string;
}

export function parsePoolConfig(data: any): PoolConfigData | null {
  if (!data) return null;

  return {
    shiftPercentage: Number(data.shiftPercentage || 0),
    minAPYThreshold: Number(data.minAPYThreshold || 0),
    harvestFrequency: Number(data.harvestFrequency || 0),
    riskTolerance: Number(data.riskTolerance || 0),
    isPaused: data.isPaused || false,
    admin: data.admin || '0x0000000000000000000000000000000000000000',
  };
}

/**
 * Format timestamp to relative time
 */
export function formatRelativeTime(timestamp: bigint | number): string {
  const now = Math.floor(Date.now() / 1000);
  const ts = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp;
  const diff = now - ts;

  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}
