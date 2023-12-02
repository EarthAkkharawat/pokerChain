// ethereum.js in the utils folder
import { ethers } from 'ethers';
import pokerGameABI from './pokerContractABI.json'; // adjust the path if necessary

const contractAddress = '0x30cA403F6626281ef9Ff6d450773835Da11d7fe5'; // replace with your contract address

export const getEthereumContract = async() => {
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  const contract = new ethers.Contract(contractAddress, pokerGameABI, signer);
  return contract;
};
