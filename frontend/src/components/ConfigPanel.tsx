import React, { useState } from 'react';

interface ConfigPanelProps {
  poolId: string;
}

export const ConfigPanel: React.FC<ConfigPanelProps> = ({ poolId }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [config, setConfig] = useState({
    shiftPercentage: 30,
    minAPYThreshold: 5,
    harvestFrequency: 10,
    riskTolerance: 7,
  });

  const handleSave = () => {
    // In production, this would call the contract's configurePool function
    console.log('Saving config:', config);
    alert('Configuration saved! (Demo only - would submit to contract)');
  };

  return (
    <div className="bg-gray-800/50 rounded-xl border border-gray-700 overflow-hidden">
      {/* Header - Always visible */}
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-700/20 transition-colors"
      >
        <div className="flex items-center space-x-3">
          <span className="text-2xl">⚙️</span>
          <div className="text-left">
            <h2 className="text-lg font-bold text-white">Pool Configuration</h2>
            <p className="text-sm text-gray-400">Customize yield optimization settings</p>
          </div>
        </div>
        <svg 
          className={`w-5 h-5 text-gray-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`}
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Expandable Content */}
      {isExpanded && (
        <div className="px-6 pb-6 border-t border-gray-700">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6">
            {/* Shift Percentage */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Capital Shift Percentage
              </label>
              <div className="flex items-center space-x-4">
                <input
                  type="range"
                  min="10"
                  max="50"
                  value={config.shiftPercentage}
                  onChange={(e) => setConfig({ ...config, shiftPercentage: parseInt(e.target.value) })}
                  className="flex-1 h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-500"
                />
                <span className="text-white font-semibold w-12 text-right">{config.shiftPercentage}%</span>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Percentage of idle liquidity to route to yield sources
              </p>
            </div>

            {/* Min APY Threshold */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Minimum APY Threshold
              </label>
              <div className="flex items-center space-x-4">
                <input
                  type="range"
                  min="2"
                  max="20"
                  value={config.minAPYThreshold}
                  onChange={(e) => setConfig({ ...config, minAPYThreshold: parseInt(e.target.value) })}
                  className="flex-1 h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-500"
                />
                <span className="text-white font-semibold w-12 text-right">{config.minAPYThreshold}%</span>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Only shift capital if yield source APY exceeds this
              </p>
            </div>

            {/* Harvest Frequency */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Harvest Frequency
              </label>
              <div className="flex items-center space-x-4">
                <input
                  type="range"
                  min="5"
                  max="50"
                  step="5"
                  value={config.harvestFrequency}
                  onChange={(e) => setConfig({ ...config, harvestFrequency: parseInt(e.target.value) })}
                  className="flex-1 h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-500"
                />
                <span className="text-white font-semibold w-20 text-right">{config.harvestFrequency} swaps</span>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Number of swaps between reward harvests
              </p>
            </div>

            {/* Risk Tolerance */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Risk Tolerance
              </label>
              <div className="flex items-center space-x-4">
                <input
                  type="range"
                  min="1"
                  max="10"
                  value={config.riskTolerance}
                  onChange={(e) => setConfig({ ...config, riskTolerance: parseInt(e.target.value) })}
                  className="flex-1 h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-500"
                />
                <span className="text-white font-semibold w-12 text-right">{config.riskTolerance}/10</span>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                {config.riskTolerance <= 3 && 'Conservative - only low-risk vaults (Aave, Compound)'}
                {config.riskTolerance > 3 && config.riskTolerance <= 6 && 'Moderate - includes Morpho Blue'}
                {config.riskTolerance > 6 && 'Aggressive - includes all yield sources'}
              </p>
            </div>
          </div>

          {/* Current Config Summary */}
          <div className="mt-6 p-4 bg-gray-900/50 rounded-lg">
            <h3 className="text-sm font-medium text-gray-300 mb-3">Configuration Summary</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div>
                <span className="text-gray-500">Shift:</span>
                <span className="text-white ml-2">{config.shiftPercentage}% of idle capital</span>
              </div>
              <div>
                <span className="text-gray-500">Min APY:</span>
                <span className="text-white ml-2">{config.minAPYThreshold}%</span>
              </div>
              <div>
                <span className="text-gray-500">Harvest:</span>
                <span className="text-white ml-2">Every {config.harvestFrequency} swaps</span>
              </div>
              <div>
                <span className="text-gray-500">Risk:</span>
                <span className="text-white ml-2">
                  {config.riskTolerance <= 3 ? 'Conservative' : config.riskTolerance <= 6 ? 'Moderate' : 'Aggressive'}
                </span>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="mt-6 flex items-center justify-between">
            <button
              onClick={() => setConfig({
                shiftPercentage: 30,
                minAPYThreshold: 5,
                harvestFrequency: 10,
                riskTolerance: 7,
              })}
              className="px-4 py-2 text-sm text-gray-400 hover:text-white transition-colors"
            >
              Reset to defaults
            </button>
            <div className="flex items-center space-x-3">
              <button
                onClick={() => setIsExpanded(false)}
                className="px-4 py-2 text-sm text-gray-400 hover:text-white transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                className="px-6 py-2 bg-blue-500 hover:bg-blue-600 text-white font-medium rounded-lg transition-colors"
              >
                Save Configuration
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
