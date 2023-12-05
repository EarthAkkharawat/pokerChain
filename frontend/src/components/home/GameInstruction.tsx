import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "react-bootstrap";
import CreateTableModal from "./CreateTableModal";

const GameInstruction: React.FC = () => {
  const navigate = useNavigate();

  const [showModal, setShowModal] = useState<boolean>(false);
  const [gameList, setGameList] = useState<number[]>([]);

  const createTable = () => {
    setShowModal(true);
  };

  const joinTable = (tableId: number) => {
    console.log(`Joining table ${tableId}`);
    navigate(`/table/${tableId}`);
  };

  console.log(gameList);
  return (
    <div style={{ color: "#FFFFFF" }}>
      <h2>Available Poker Tables</h2>
      {gameList.map((tableId) => (
        <div key={tableId} onClick={() => joinTable(tableId)}>
          <p>Table {tableId}</p>
          <button>Join Table</button>
        </div>
      ))}
      <div>
        <p>Create a New Table</p>
        <Button onClick={createTable} variant="dark">
          Create Table
        </Button>
      </div>

      <CreateTableModal
        showModal={showModal}
        setShowModal={setShowModal}
        setGameList={setGameList}
      />
    </div>
  );
};

export default GameInstruction;
