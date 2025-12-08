import React, { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { PoolStats } from './PoolStats';
import { YieldSources } from './YieldSources';
import { ActivityFeed } from './ActivityFeed';
import { ConfigPanel } from './ConfigPanel';

export const Dashboard: React.FC = () => {
  const { address, isConnected } = useAccount();
  const [selectedPool, setSelectedPool] = useState<string>('eth-usdc');

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-gray-900">
      {/* Header */}
      <header className="border-b border-gray-700 bg-gray-900/50 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-xl">Y</span>
            </div>
            <div>
              <h1 className="text-2xl font-bold text-white">YieldShift</h1>
              <p className="text-xs text-gray-400">Uniswap v4 Yield Optimizer</p>
            </div>
          </div>
          <div className="flex items-center space-x-4">
            <div className="hidden md:flex items-center space-x-2 bg-gray-800 rounded-lg px-3 py-2">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span className="text-sm text-gray-300">Base Sepolia</span>
            </div>
            <ConnectButton />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8">
        {!isConnected ? (
          <div className="text-center py-20">
            <div className="mb-8">
              <div className="w-20 h-20 mx-auto bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center mb-6">
                <span className="text-white font-bold text-4xl">Y</span>
              </div>
              <h2 className="text-3xl font-bold text-white mb-4">
                Welcome to YieldShift
              </h2>
              <p className="text-gray-400 max-w-md mx-auto mb-8">
                The first Uniswap v4 hook that transforms every liquidity pool into an 
                intelligent yield optimizer. Connect your wallet to get started.
              </p>
            </div>
            
            <div className="flex justify-center mb-12">
              <ConnectButton />
            </div>

            {/* Feature Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-4xl mx-auto">
              <FeatureCard
                title="Auto-Compound"
                description="Harvested rewards are automatically reinvested into the pool"
                icon="🔄"
              />
              <FeatureCard
                title="Best Yield Routing"
                description="Capital is routed to Aave, Morpho, Compound based on real-time APYs"
                icon="📈"
              />
              <FeatureCard
                title="Zero Lockups"
                description="Maintain full liquidity - exit anytime with no restrictions"
                icon="🔓"
              />
            </div>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Pool Selector */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <select
                  value={selectedPool}
                  onChange={(e) => setSelectedPool(e.target.value)}
                  className="bg-gray-800 text-white rounded-lg px-4 py-2 border border-gray-700 focus:outline-none focus:border-blue-500"
                >
                  <option value="eth-usdc">ETH/USDC 0.3%</option>
                  <option value="eth-dai">ETH/DAI 0.3%</option>
                </select>
                <span className="text-sm text-gray-400">
                  Connected: {address?.slice(0, 6)}...{address?.slice(-4)}
                </span>
              </div>
            </div>

            {/* Pool Stats */}
            <PoolStats poolId={selectedPool} />

            {/* Two Column Layout */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Active Yield Sources */}
              <YieldSources />
              
              {/* Activity Feed */}
              <ActivityFeed poolId={selectedPool} />
            </div>

            {/* Configuration Panel */}
            <ConfigPanel poolId={selectedPool} />
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-700 bg-gray-900/50 mt-12">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <p className="text-gray-500 text-sm">
              YieldShift - Built for Uniswap v4 Hackathon 2025
            </p>
            <div className="flex space-x-6 mt-4 md:mt-0">
              <a href="#" className="text-gray-400 hover:text-white text-sm">Docs</a>
              <a href="#" className="text-gray-400 hover:text-white text-sm">GitHub</a>
              <a href="#" className="text-gray-400 hover:text-white text-sm">Twitter</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};

// Feature Card Component
const FeatureCard: React.FC<{
  title: string;
  description: string;
  icon: string;
}> = ({ title, description, icon }) => (
  <div className="bg-gray-800/50 rounded-xl p-6 border border-gray-700">
    <div className="text-4xl mb-4">{icon}</div>
    <h3 className="text-lg font-semibold text-white mb-2">{title}</h3>
    <p className="text-gray-400 text-sm">{description}</p>
  </div>
);
