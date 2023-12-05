import React, { useEffect, useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import Modal from "./Modal";
import { getPokerGameContract } from "../../utils/contracts";
function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
const GameTable: React.FC = () => {
  const navigate = useNavigate();
  const [showModal, setShowModal] = useState<boolean>(false);
  const [smallBlind, setSmallBlind] = useState<number>(0);
  const [minBuyIn, setMinBuyIn] = useState<number>(0);
  const [maxBuyIn, setMaxBuyIn] = useState<number>(0);
  const [buyIn, setBuyIn] = useState<number>(0);
  const [gameList, setGameList] = useState<number[]>([]);
  const [contract, setContract] = useState<any>(null);
  const [gameCount, setGameCount] = useState<number>(0);
  // const [temp, setTemp] = useState<any>(null);

  const joinTable = (tableId: number) => {
    const options = { value: buyIn.toString() };
    contract.joinGame(tableId, options);
    console.log(`Joining table ${tableId}`);
    navigate(`/table/${tableId}`);
  };

  const createTable = () => {
    setShowModal(true);
  };

  const fetchContract = async () => {
    await getPokerGameContract().then((contract) => {
      // console.log("contract:", contract)
      setContract(contract);
    });
  }
  const fetchGameCount = async () => {
    try {
      // var temp = await contract.getNumGames();
      // console.log("temp:", temp)
      // setGameCount(temp);
      // console.log("Game count:", gameCount)
      await contract.getNumGames().then((count: number) => {
        // console.log("count", count)
        setGameCount(count);
        // console.log("contract in game count:", contract)
        // console.log("Game count:", gameCount)
      });
    } catch (error) {
      console.error("Error fetching game count:", error);
    }
  }
  useEffect(() => {
    const fetchData = async () => {
      await fetchContract();
      await sleep(2000);
      await fetchGameCount();
      await sleep(2000);

      await setGameList(Array.from({ length: Number(gameCount) }, (_, i) => i));
    }
    fetchData();
    // fetchContract().then(() => {
    //   fetchGameCount().then(() => {
    //     setGameList(Array.from({ length: Number(gameCount) }, (_, i) => i));
    //   });
    // });
  }, [contract])

  // useEffect(() => {
  //   fetchGameCount();
  //   setGameList(Array.from({ length: Number(gameCount) }, (_, i) => i));

  // }, [contract])

  const handleSubmit = async () => {
    setShowModal(false);
    try {
      console.log("contract:", contract);
      const tx = await contract.createGame(
        smallBlind,
        minBuyIn,
        maxBuyIn,
      );
      await tx.wait();

    } catch (error) {
      console.error("Error creating table:", error);
    }
  };
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
