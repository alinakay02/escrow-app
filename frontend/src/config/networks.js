export const NETWORKS = {
  customTestnet: {
    chainId: '0x539', // 1337 in hex
    chainName: 'Custom Testnet',
    rpcUrls: ['http://93.95.97.136:8545'],
    nativeCurrency: {
      name: 'ETH',
      symbol: 'ETH',
      decimals: 18
    },
    blockExplorerUrls: []
  }
};

export const DEFAULT_NETWORK = NETWORKS.customTestnet;

export const CONTRACT_ADDRESSES = {
  FACTORY: import.meta.env.VITE_FACTORY_ADDRESS,
  // Add other contract addresses here
};

export async function setupNetwork() {
  const { ethereum } = window;
  if (!ethereum) return false;

  try {
    await ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: DEFAULT_NETWORK.chainId }],
    });
    return true;
  } catch (switchError) {
    // This error code indicates that the chain has not been added to MetaMask
    if (switchError.code === 4902) {
      try {
        await ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [DEFAULT_NETWORK],
        });
        return true;
      } catch (addError) {
        console.error('Error adding network:', addError);
        return false;
      }
    }
    console.error('Error switching network:', switchError);
    return false;
  }
} 