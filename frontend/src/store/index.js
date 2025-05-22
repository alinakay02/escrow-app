import { defineStore } from 'pinia';
import { BrowserProvider, JsonRpcProvider, Contract } from 'ethers';
import { setupNetwork, DEFAULT_NETWORK, CONTRACT_ADDRESSES } from '@/config/networks';
import factoryAbi from '@/abis/EscrowFactory.json';
import escrowAbi from '@/abis/EscrowMarketplace.json';
import userProfileAbi from '@/abis/UserProfile.json';

export const useWeb3Store = defineStore('web3', {
  state: () => ({
    address: null,
    provider: null,
    signer: null,
    factory: null,
    userProfile: null,
    isConnecting: false,
    error: null,
    chainId: null,
    contracts: {}
  }),

  getters: {
    isConnected: (state) => !!state.address,
    isCorrectNetwork: (state) => state.chainId === DEFAULT_NETWORK.chainId,
    getContract: (state) => (address) => state.contracts[address],
  },

  actions: {
    async connect() {
      this.isConnecting = true;
      this.error = null;

      try {
        if (!window.ethereum) {
          throw new Error('MetaMask not installed');
        }

        // Setup network in MetaMask
        const networkSetup = await setupNetwork();
        if (!networkSetup) {
          throw new Error('Failed to setup network');
        }

        const provider = new BrowserProvider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        const network = await provider.getNetwork();
        
        this.provider = provider;
        this.signer = signer;
        this.address = address;
        this.chainId = '0x' + network.chainId.toString(16);

        // Initialize contracts
        await this.initializeContracts();

        // Setup event listeners
        this.setupEventListeners();

      } catch (error) {
        console.error('Connection error:', error);
        this.error = error.message;
        throw error;
      } finally {
        this.isConnecting = false;
      }
    },

    async initializeContracts() {
      // Initialize Factory contract
      this.factory = new Contract(
        CONTRACT_ADDRESSES.FACTORY,
        factoryAbi,
        this.signer || this.provider
      );

      // Get marketplace and user profile addresses from factory
      const [marketplaceAddr, userProfileAddr] = await this.factory.getContracts();

      // Initialize marketplace contract
      this.contracts[marketplaceAddr] = new Contract(
        marketplaceAddr,
        escrowAbi,
        this.signer || this.provider
      );

      // Initialize user profile contract
      this.userProfile = new Contract(
        userProfileAddr,
        userProfileAbi,
        this.signer || this.provider
      );
    },

    setupEventListeners() {
      if (!window.ethereum) return;

      window.ethereum.on('accountsChanged', async (accounts) => {
        if (accounts.length === 0) {
          this.disconnect();
        } else {
          this.address = accounts[0];
          await this.initializeContracts();
        }
      });

      window.ethereum.on('chainChanged', (chainId) => {
        window.location.reload();
      });

      window.ethereum.on('disconnect', () => {
        this.disconnect();
      });
    },

    disconnect() {
      this.address = null;
      this.signer = null;
      this.factory = null;
      this.userProfile = null;
      this.contracts = {};
      this.chainId = null;
      this.error = null;
    },

    async getEscrowContract(address) {
      if (!this.contracts[address]) {
        this.contracts[address] = new Contract(
          address,
          escrowAbi,
          this.signer || this.provider
        );
      }
      return this.contracts[address];
    }
  }
});
