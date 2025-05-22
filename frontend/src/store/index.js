import { defineStore } from 'pinia';
import { BrowserProvider, JsonRpcProvider, Contract } from 'ethers';
import factoryAbi from '@/abis/EscrowFactory.json';

export const useWeb3Store = defineStore('web3', {
  state: () => ({
    address: null,
    provider: null,
    signer: null,
    factory: null
  }),
  actions: {
    async connect() {
      if (window.ethereum) {
        const provider = new BrowserProvider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        this.provider = provider;
        this.signer = signer;
        this.address = address;
      } else {
        this.provider = new JsonRpcProvider(import.meta.env.VITE_TETH_RPC_URL);
      }
      this.factory = new Contract(
        import.meta.env.VITE_FACTORY_ADDRESS,
        factoryAbi,
        this.signer || this.provider
      );
    }
  }
});
