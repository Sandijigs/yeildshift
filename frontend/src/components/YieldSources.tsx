import React from 'react';

interface YieldSource {
  name: string;
  protocol: string;
  apy: number;
  deployed: number;
  status: 'active' | 'available' | 'paused';
  riskScore: number;
}

// Mock data - in production, fetch from YieldOracle contract
const mockSources: YieldSource[] = [
  { 
    name: 'Morpho Blue (USDC)', 
    protocol: 'morpho',
    apy: 11.2, 
    deployed: 45230, 
    status: 'active',
    riskScore: 6,
  },
  { 
    name: 'EigenLayer weETH', 
    protocol: 'eigenlayer',
    apy: 8.7, 
    deployed: 28100, 
    status: 'active',
    riskScore: 7,
  },
  { 
    name: 'Aave v3 (USDC)', 
    protocol: 'aave',
    apy: 6.1, 
    deployed: 12450, 
    status: 'active',
    riskScore: 3,
  },
  { 
    name: 'Compound v3 (USDC)', 
    protocol: 'compound',
    apy: 4.2, 
    deployed: 0, 
    status: 'available',
    riskScore: 4,
  },
];

const protocolLogos: Record<string, string> = {
  morpho: '🔵',
  eigenlayer: '🟣',
  aave: '👻',
  compound: '🌿',
};

const getRiskLabel = (score: number): { label: string; color: string } => {
  if (score <= 3) return { label: 'Low Risk', color: 'text-green-400' };
  if (score <= 6) return { label: 'Medium Risk', color: 'text-yellow-400' };
  return { label: 'High Risk', color: 'text-red-400' };
};

export const YieldSources: React.FC = () => {
  return (
    <div className="bg-gray-800/50 rounded-xl border border-gray-700 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-700 flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white">Active Yield Sources</h2>
          <p className="text-sm text-gray-400 mt-1">Real-time APY monitoring</p>
        </div>
        <div className="flex items-center space-x-2">
          <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
          <span className="text-sm text-gray-400">Live</span>
        </div>
      </div>

      {/* Source List */}
      <div className="divide-y divide-gray-700">
        {mockSources.map((source, idx) => (
          <YieldSourceRow key={idx} source={source} />
        ))}
      </div>

      {/* Footer */}
      <div className="px-6 py-3 bg-gray-900/30 border-t border-gray-700">
        <p className="text-xs text-gray-500">
          APYs update every 60 seconds • Capital is shifted to highest risk-adjusted yield
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
