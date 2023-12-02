import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useParams } from 'react-router-dom';
import { getEthereumContract } from '../../utils/contracts';

const PokerTablePage: React.FC = () => {
  const [players, setPlayers] = useState<any[]>([]);
  const { gameId } = useParams<{ gameId: string }>();
  
  const getPlayers = async () => {
    try {
      // Ensure Ethereum object and provider are available
      if (window.ethereum) {
        const contract = await getEthereumContract();
        console.log(contract);

        // Call the getPlayers function from your contract
        const gameIdNumber = Number(gameId);
        console.log(gameIdNumber);
        const playersList = await contract.getPlayers(gameIdNumber);
        console.log(playersList);
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
