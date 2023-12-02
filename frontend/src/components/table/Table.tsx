import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import Modal from "./Modal";
import { getEthereumContract } from "../../utils/contracts";
import { parseEther } from "@ethersproject/units";

const GameTable: React.FC = () => {
  const navigate = useNavigate();
  const [showModal, setShowModal] = useState<boolean>(false);
  const [smallBlind, setSmallBlind] = useState<number>(0);
  const [minBuyIn, setMinBuyIn] = useState<number>(0);
  const [maxBuyIn, setMaxBuyIn] = useState<number>(0);
  const [buyIn, setBuyIn] = useState<number>(0);
  const [gameList, setGameList] = useState<number[]>([]);

  const joinTable = (tableId: number) => {
    console.log(`Joining table ${tableId}`);
    navigate(`/table/${tableId}`);
  };

  const createTable = () => {
    setShowModal(true);
  };

  const handleSubmit = async () => {
    setShowModal(false);
    try {
      const contract = await getEthereumContract();
      console.log(contract);

      const options = { value: buyIn.toString() };
      const tx = await contract.createGame(
          smallBlind,
          minBuyIn,
          maxBuyIn,
          options,
      );
      await tx.wait();
      setGameList((prevGameList) => [...prevGameList, prevGameList.length]);
    //   navigate("/table/" + gameList.length);

      // Add any post-transaction logic here
    } catch (error) {
      console.error("Error creating table:", error);
    }
  };
  console.log(gameList);
  return (
    <div>
      <h2>Available Poker Tables</h2>
      {gameList.map((tableId) => (
        <div key={tableId} onClick={() => joinTable(tableId)}>
          <p>Table {tableId}</p>
          <button>Join Table</button>
        </div>
      ))}
      <div onClick={createTable}>
        <p>Create a New Table</p>
        <button>Create Table</button>
      </div>

      {showModal && (
        <Modal onClose={() => setShowModal(false)}>
          <h2>Create Game</h2>
          <label>
            Small Blind:
            <input
              name="smallBlind"
              type="number"
              value={smallBlind}
              onChange={(e) => setSmallBlind(Number(e.target.value))}
              placeholder="Small Blind"
            />
          </label>
          <label>
            Min Buy-In:
            <input
              name="minBuyIn"
              type="number"
              value={minBuyIn}
              onChange={(e) => setMinBuyIn(Number(e.target.value))}
              placeholder="Min Buy-In"
            />
          </label>
          <label>
            Max Buy-In:
            <input
              name="maxBuyIn"
              type="number"
              value={maxBuyIn}
              onChange={(e) => setMaxBuyIn(Number(e.target.value))}
              placeholder="Max Buy-In"
            />
          </label>
          <label>
            Your Buy-In Amount:
            <input
              name="buyIn"
              type="number"
              value={buyIn}
              onChange={(e) => setBuyIn(Number(e.target.value))}
              placeholder="Your Buy-In Amount"
            />
          </label>
          <button onClick={handleSubmit}>Submit</button>
        </Modal>
      )}
    </div>
  );
};

export default GameTable;
