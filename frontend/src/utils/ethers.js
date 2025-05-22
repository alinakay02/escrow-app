import { Contract } from 'ethers';
import escrowAbi from '@/abis/Escrow.json';

export function getEscrow(address, signerOrProvider) {
  return new Contract(address, escrowAbi, signerOrProvider);
}
