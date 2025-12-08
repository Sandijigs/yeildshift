import React, { useState, useEffect } from 'react';

interface Activity {
  id: string;
  type: 'shift' | 'harvest' | 'compound' | 'config';
  message: string;
  details?: string;
  timestamp: Date;
  txHash?: string;
}

// Mock activities - in production, fetch from contract events
const mockActivities: Activity[] = [
  {
    id: '1',
    type: 'shift',
    message: 'Shifted $5,000 USDC to Morpho Blue',
    details: 'Best APY: 11.2%',
    timestamp: new Date(Date.now() - 2 * 60 * 1000),
    txHash: '0x1234...5678',
  },
  {
    id: '2',
    type: 'harvest',
    message: 'Harvested $124 in rewards',
    details: 'Auto-compounded to pool',
    timestamp: new Date(Date.now() - 15 * 60 * 1000),
    txHash: '0x2345...6789',
  },
  {
    id: '3',
    type: 'shift',
    message: 'Rebalanced ETH to EigenLayer',
    details: 'weETH APY: 8.7%',
    timestamp: new Date(Date.now() - 45 * 60 * 1000),
    txHash: '0x3456...7890',
  },
  {
    id: '4',
    type: 'harvest',
    message: 'Harvested $89 in rewards',
    details: 'From Aave v3',
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
    txHash: '0x4567...8901',
  },
  {
    id: '5',
    type: 'compound',
    message: 'Compounded rewards to pool',
    details: '+$213 liquidity added',
    timestamp: new Date(Date.now() - 3 * 60 * 60 * 1000),
    txHash: '0x5678...9012',
  },
];

const activityIcons: Record<Activity['type'], { icon: string; bg: string }> = {
  shift: { icon: '↗️', bg: 'bg-blue-500/20' },
  harvest: { icon: '🌾', bg: 'bg-green-500/20' },
  compound: { icon: '🔄', bg: 'bg-purple-500/20' },
  config: { icon: '⚙️', bg: 'bg-gray-500/20' },
};

const formatTimeAgo = (date: Date): string => {
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  
  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)} min ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)} hours ago`;
  return `${Math.floor(seconds / 86400)} days ago`;
};

interface ActivityFeedProps {
  poolId: string;
}

export const ActivityFeed: React.FC<ActivityFeedProps> = ({ poolId }) => {
  const [activities, setActivities] = useState<Activity[]>(mockActivities);
  const [isLive, setIsLive] = useState(true);

  // Simulate live updates
  useEffect(() => {
    if (!isLive) return;

    const interval = setInterval(() => {
      // In production, this would listen to contract events
      const randomActivity: Activity = {
        id: Date.now().toString(),
        type: Math.random() > 0.5 ? 'shift' : 'harvest',
        message: Math.random() > 0.5 
          ? `Shifted $${(Math.random() * 5000).toFixed(0)} to best yield`
          : `Harvested $${(Math.random() * 200).toFixed(0)} in rewards`,
        timestamp: new Date(),
      };

      // Only add occasionally for demo
      if (Math.random() > 0.9) {
        setActivities(prev => [randomActivity, ...prev.slice(0, 9)]);
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [isLive]);

  return (
    <div className="bg-gray-800/50 rounded-xl border border-gray-700 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-700 flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white">Activity Feed</h2>
          <p className="text-sm text-gray-400 mt-1">Recent yield optimization events</p>
        </div>
        <button
          onClick={() => setIsLive(!isLive)}
          className={`flex items-center space-x-2 px-3 py-1.5 rounded-lg text-sm transition-colors ${
            isLive 
              ? 'bg-green-500/20 text-green-400' 
              : 'bg-gray-700 text-gray-400'
          }`}
        >
          <div className={`w-2 h-2 rounded-full ${isLive ? 'bg-green-500 animate-pulse' : 'bg-gray-500'}`} />
          <span>{isLive ? 'Live' : 'Paused'}</span>
        </button>
      </div>

      {/* Activity List */}
      <div className="divide-y divide-gray-700/50 max-h-[400px] overflow-y-auto">
        {activities.map((activity) => (
          <ActivityRow key={activity.id} activity={activity} />
        ))}
      </div>

      {/* Footer */}
      <div className="px-6 py-3 bg-gray-900/30 border-t border-gray-700 flex items-center justify-between">
        <p className="text-xs text-gray-500">
          Showing last {activities.length} events
        </p>
        <button className="text-xs text-blue-400 hover:text-blue-300 transition-colors">
          View all →
        </button>
      </div>
    </div>
  );
};

const ActivityRow: React.FC<{ activity: Activity }> = ({ activity }) => {
  const { icon, bg } = activityIcons[activity.type];
  
  return (
    <div className="flex items-start space-x-3 px-6 py-4 hover:bg-gray-700/20 transition-colors">
      {/* Icon */}
      <div className={`w-10 h-10 rounded-lg ${bg} flex items-center justify-center flex-shrink-0`}>
        <span className="text-lg">{icon}</span>
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <p className="text-white font-medium">{activity.message}</p>
        {activity.details && (
          <p className="text-sm text-gray-400 mt-0.5">{activity.details}</p>
        )}
        <div className="flex items-center space-x-3 mt-2">
          <span className="text-xs text-gray-500">{formatTimeAgo(activity.timestamp)}</span>
          {activity.txHash && (
            <a 
              href={`https://sepolia.basescan.org/tx/${activity.txHash}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-blue-400 hover:text-blue-300"
            >
              View tx ↗
            </a>
          )}
        </div>
      </div>
    </div>
  );
};
