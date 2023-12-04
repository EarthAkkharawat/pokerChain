// ethereum.js in the utils folder
import { ethers } from 'ethers';
import pokerGameABI from './pokerContractABI.json';
import nftABI from './nftContractABI.json';

const contractAddress = '0x28c05D4A6163BaFa0B7D6825fAD8a304B95A8A4B';
const nftContractAddress = '0xfe5272414a5d6289d5e505fcf2dcd8a1f47b13ab';

export const getPokerGameContract = async () => {
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  const contract = new ethers.Contract(contractAddress, pokerGameABI, signer);
  return contract;
};

export const getNFTContract = async () => {
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  const contract = new ethers.Contract(nftContractAddress, nftABI, signer);
  return contract;
}