import React from 'react';
import { WagmiProvider, createConfig, http } from 'wagmi';
import { baseSepolia } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RainbowKitProvider, connectorsForWallets } from '@rainbow-me/rainbowkit';
import {
  injectedWallet,
  walletConnectWallet,
  coinbaseWallet,
} from '@rainbow-me/rainbowkit/wallets';
import '@rainbow-me/rainbowkit/styles.css';

import { Dashboard } from './components/Dashboard';
import './App.css';

const projectId = '6b87a3c69cbd8b52055d7aef763148d6';

// Custom connector configuration WITHOUT MetaMask SDK (to avoid openapi-fetch bug)
const connectors = connectorsForWallets(
  [{
    groupName: 'Recommended',
    wallets: [
      injectedWallet,        // This handles MetaMask browser extension
      walletConnectWallet,
      coinbaseWallet,
    ],
  }],
  {
    appName: 'YieldShift',
    projectId,
  }
);

// Configure wagmi
const config = createConfig({
  chains: [baseSepolia],
  connectors,
  transports: {
    [baseSepolia.id]: http('https://sepolia.base.org'),
  },
});

const queryClient = new QueryClient();

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <div className="min-h-screen bg-gray-50">
            <Dashboard />
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
