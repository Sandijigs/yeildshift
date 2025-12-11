import React from 'react';
import { useAllVaultDetails, formatAPY } from '../hooks/useYieldOracle';
import { VAULT_NAMES } from '../contracts';

interface YieldSource {
  name: string;
  protocol: string;
  apy: number;
  deployed: number;
  status: 'active' | 'available' | 'paused';
  riskScore: number;
  address: string;
}

const protocolMapping: Record<string, string> = {
  '0xa238dd80c259a72e81d7e4664a9801593f98d1c5': 'aave',
  '0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb': 'morpho',
  '0xb125e6687d4313864e53df431d5425969c15eb2f': 'compound',
  '0x76db26de9e92730c24c69717741937d084858960': 'eigenlayer', // weETH
  '0xa15e05954e22f795205a14f58c04c23a6bdf872e': 'eigenlayer', // ezETH
};

const protocolLogos: Record<string, string> = {
  morpho: '🔵',
  eigenlayer: '🟣',
  aave: '👻',
  compound: '🌿',
  unknown: '❓',
};

const getRiskLabel = (score: number): { label: string; color: string } => {
  if (score <= 3) return { label: 'Low Risk', color: 'text-green-400' };
  if (score <= 6) return { label: 'Medium Risk', color: 'text-yellow-400' };
  return { label: 'High Risk', color: 'text-red-400' };
};

export const YieldSources: React.FC = () => {
  const { vaults, isLoading } = useAllVaultDetails();

  // Transform vault data to YieldSource format
  const sources: YieldSource[] = vaults.map((vault) => {
    const vaultAddress = vault.address.toLowerCase();
    const protocol = protocolMapping[vaultAddress] || 'unknown';
    const name = VAULT_NAMES[vaultAddress] || `Unknown Vault (${vaultAddress.slice(0, 6)})`;

    return {
      name,
      protocol,
      apy: parseFloat(formatAPY(vault.apy)),
      deployed: 0, // Will be fetched separately if needed
      status: vault.isWhitelisted ? 'active' : 'available',
      riskScore: Number(vault.riskScore),
      address: vault.address,
    };
  });

  return (
    <div className="bg-gray-800/50 rounded-xl border border-gray-700 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-700 flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white">Active Yield Sources</h2>
          <p className="text-sm text-gray-400 mt-1">Real-time APY monitoring</p>
        </div>
        <div className="flex items-center space-x-2">
          <div className={`w-2 h-2 rounded-full ${isLoading ? 'bg-yellow-500' : 'bg-green-500 animate-pulse'}`}></div>
          <span className="text-sm text-gray-400">{isLoading ? 'Loading...' : 'Live'}</span>
        </div>
      </div>

      {/* Source List */}
      <div className="divide-y divide-gray-700">
        {isLoading ? (
          <div className="px-6 py-8 text-center text-gray-400">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
            <p className="mt-2">Loading yield sources...</p>
          </div>
        ) : sources.length === 0 ? (
          <div className="px-6 py-8 text-center text-gray-400">
            <p>No yield sources configured yet.</p>
            <p className="text-sm mt-2">Initialize contracts to add vault data.</p>
          </div>
        ) : (
          sources.map((source, idx) => (
            <YieldSourceRow key={idx} source={source} />
          ))
        )}
      </div>

      {/* Footer */}
      <div className="px-6 py-3 bg-gray-900/30 border-t border-gray-700">
        <p className="text-xs text-gray-500">
          APYs update every 30 seconds • Capital is shifted to highest risk-adjusted yield
        </p>
      </div>
    </div>
  );
};

const YieldSourceRow: React.FC<{ source: YieldSource }> = ({ source }) => {
  const risk = getRiskLabel(source.riskScore);

  return (
    <div className={`flex items-center justify-between px-6 py-4 transition-colors ${
      source.status === 'active'
        ? 'bg-gray-800/30'
        : 'bg-transparent opacity-60'
    }`}>
      <div className="flex items-center space-x-4">
        {/* Status Indicator */}
        <div className={`w-3 h-3 rounded-full ${
          source.status === 'active'
            ? 'bg-green-500 animate-pulse'
            : source.status === 'available'
              ? 'bg-gray-500'
              : 'bg-yellow-500'
        }`} />

        {/* Protocol Info */}
        <div className="flex items-center space-x-3">
          <span className="text-2xl">{protocolLogos[source.protocol]}</span>
          <div>
            <p className="font-medium text-white">{source.name}</p>
            <div className="flex items-center space-x-2 mt-1">
              <span className={`text-xs ${risk.color}`}>{risk.label}</span>
              {source.deployed > 0 && (
                <span className="text-xs text-gray-500">
                  • ${source.deployed.toLocaleString()} deployed
                </span>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* APY */}
      <div className="text-right">
        <p className="text-2xl font-bold text-white">{source.apy}%</p>
        <p className="text-xs text-gray-500">APY</p>
      </div>
    </div>
  );
};
