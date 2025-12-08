import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, Area, AreaChart } from 'recharts';

interface PoolStatsProps {
  poolId: string;
}

// Mock data for demonstration
const generateMockData = () => {
  const data = [];
  const now = Date.now();
  for (let i = 30; i >= 0; i--) {
    const baseYield = 0.3;
    const yieldShiftYield = 8 + Math.random() * 4;
    data.push({
      time: new Date(now - i * 24 * 60 * 60 * 1000).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
      vanilla: baseYield * (30 - i) / 30 * 100,
      yieldshift: yieldShiftYield * (30 - i) / 30 * 100 / 12,
    });
  }
  return data;
};

export const PoolStats: React.FC<PoolStatsProps> = ({ poolId }) => {
  const [historicalData] = useState(generateMockData());
  
  // Mock stats - in production, fetch from contracts
  const stats = {
    vanillaAPY: 0.3,
    extraAPY: 8.1,
    totalAPY: 8.4,
    totalShifted: 125430,
    totalHarvested: 2341,
    swapCount: 47,
    lastHarvest: '2 hours ago',
  };

  return (
    <div className="bg-gray-800/50 rounded-xl border border-gray-700 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-700">
        <h2 className="text-xl font-bold text-white">Pool Performance</h2>
        <p className="text-sm text-gray-400 mt-1">
          ETH/USDC 0.3% with YieldShift optimization
        </p>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-6">
        <MetricCard
          label="Total APY"
          value={`${stats.totalAPY.toFixed(1)}%`}
          gradient="from-blue-500 to-blue-600"
          icon="📊"
        />
        <MetricCard
          label="Extra Yield"
          value={`+${stats.extraAPY.toFixed(1)}%`}
          gradient="from-green-500 to-green-600"
          icon="📈"
        />
        <MetricCard
          label="Capital Shifted"
          value={`$${(stats.totalShifted / 1000).toFixed(1)}k`}
          gradient="from-purple-500 to-purple-600"
          icon="💰"
        />
        <MetricCard
          label="Rewards Harvested"
          value={`$${stats.totalHarvested.toLocaleString()}`}
          gradient="from-orange-500 to-orange-600"
          icon="🌾"
        />
      </div>

      {/* Comparison Chart */}
      <div className="px-6 pb-6">
        <div className="bg-gray-900/50 rounded-lg p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-white font-medium">Cumulative Yield (30 days)</h3>
            <div className="flex items-center space-x-4 text-sm">
              <div className="flex items-center">
                <div className="w-3 h-3 bg-blue-500 rounded-full mr-2"></div>
                <span className="text-gray-400">YieldShift</span>
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 bg-gray-500 rounded-full mr-2"></div>
                <span className="text-gray-400">Vanilla Uniswap</span>
              </div>
            </div>
          </div>
          
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={historicalData}>
              <defs>
                <linearGradient id="yieldshiftGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#3B82F6" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <XAxis 
                dataKey="time" 
                stroke="#6B7280" 
                fontSize={12}
                tickLine={false}
              />
              <YAxis 
                stroke="#6B7280" 
                fontSize={12}
                tickLine={false}
                tickFormatter={(value) => `$${value.toFixed(0)}`}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#1F2937',
                  border: '1px solid #374151',
                  borderRadius: '8px',
                }}
                labelStyle={{ color: '#9CA3AF' }}
              />
              <Area
                type="monotone"
                dataKey="yieldshift"
                stroke="#3B82F6"
                strokeWidth={2}
                fill="url(#yieldshiftGradient)"
                name="YieldShift"
              />
              <Line
                type="monotone"
                dataKey="vanilla"
                stroke="#6B7280"
                strokeWidth={2}
                strokeDasharray="5 5"
                dot={false}
                name="Vanilla"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Additional Stats */}
      <div className="grid grid-cols-3 border-t border-gray-700">
        <div className="px-6 py-4 border-r border-gray-700">
          <p className="text-gray-400 text-sm">Swaps Since Harvest</p>
          <p className="text-white text-xl font-semibold">{stats.swapCount}/10</p>
        </div>
        <div className="px-6 py-4 border-r border-gray-700">
          <p className="text-gray-400 text-sm">Last Harvest</p>
          <p className="text-white text-xl font-semibold">{stats.lastHarvest}</p>
        </div>
        <div className="px-6 py-4">
          <p className="text-gray-400 text-sm">vs. Vanilla Pool</p>
          <p className="text-green-400 text-xl font-semibold">+{((stats.totalAPY / stats.vanillaAPY - 1) * 100).toFixed(0)}x Yield</p>
        </div>
      </div>
    </div>
  );
};

// Metric Card Component
const MetricCard: React.FC<{
  label: string;
  value: string;
  gradient: string;
  icon: string;
}> = ({ label, value, gradient, icon }) => (
  <div className={`bg-gradient-to-br ${gradient} rounded-lg p-4 text-white`}>
    <div className="flex items-center justify-between mb-2">
      <span className="text-2xl">{icon}</span>
    </div>
    <p className="text-sm opacity-90 mb-1">{label}</p>
    <p className="text-2xl font-bold">{value}</p>
  </div>
);
