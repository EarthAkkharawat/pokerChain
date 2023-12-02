import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import pokerGameABI from '../../utils/pokerContractABI.json';
import { useParams } from 'react-router-dom';

const contractAddress = "0xed27012c24FDa47A661De241c4030ecB9D18a76d"; // Your contract address

const PokerTablePage: React.FC = () => {
  const [players, setPlayers] = useState<any[]>([]);
  const { gameId } = useParams<{ gameId: string }>();
  
  const getPlayers = async () => {
    try {
      // Ensure Ethereum object and provider are available
      if (window.ethereum) {
        const provider = new ethers.BrowserProvider(window.ethereum)
        const contract = new ethers.Contract(contractAddress, pokerGameABI, provider);
        console.log(contract);

        // Call the getPlayers function from your contract
        const gameIdNumber = Number(gameId);
        console.log(gameIdNumber);
        const playersList = await contract.getPlayers(gameIdNumber - 1);

        // Ensure playersList is an array before setting the state
        if (Array.isArray(playersList)) {
          setPlayers(playersList);
        } else {
          setPlayers([]); // Or handle the error as you see fit
        }
      } else {
        console.error('Ethereum object not found');
        setPlayers([]); // Set to empty array or handle the error
      }
    } catch (error) {
      console.error('Error fetching players:', error);
      setPlayers([]); // Set to empty array or handle the error
    }
  };

  useEffect(() => {
    getPlayers();
  }, []);

  return (
    <div className="poker-table">
      {/* Render your players here */}
      {players.map((player, index) => (
        <div key={index} className="player">
          Player: {player} {/* Format as needed */}
        </div>
      ))}
    </div>
  );
};

export default PokerTablePage;
