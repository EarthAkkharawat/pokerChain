import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Modal, Button, Form } from "react-bootstrap";
import { getPokerGameContract } from "../../utils/contracts";

interface CreateTableModalProps {
  showModal: boolean;
  setShowModal: React.Dispatch<React.SetStateAction<boolean>>;
  setGameList: React.Dispatch<React.SetStateAction<number[]>>;
}

const CreateTableModal: React.FC<CreateTableModalProps> = ({
  showModal,
  setShowModal,
  setGameList,
}) => {
  const navigate = useNavigate();

  const [smallBlind, setSmallBlind] = useState<number>(0);
  const [minBuyIn, setMinBuyIn] = useState<number>(0);
  const [maxBuyIn, setMaxBuyIn] = useState<number>(0);
  const [buyIn, setBuyIn] = useState<number>(0);
  const [contract, setContract] = useState<any>(null);
  const [gameCount, setGameCount] = useState<number>(0);
  const joinTable = (tableId: number) => {
    const options = { value: buyIn.toString() };
    contract.joinGame(tableId, options);
    console.log(`Joining table ${tableId}`);
    navigate(`/table/${tableId}`);
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
      await fetchGameCount();

      await setGameList(Array.from({ length: Number(gameCount) }, (_, i) => i));
    }
    fetchData();
  }, [contract])
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
      {showModal && (
        <Modal show={showModal} onHide={() => setShowModal(false)}>
          <Modal.Header closeButton>
            <Modal.Title>Create Game</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <Form>
              <Form.Group>
                <Form.Label>Small Blind:</Form.Label>
                <Form.Control
                  name="smallBlind"
                  type="number"
                  value={smallBlind}
                  onChange={(e) => setSmallBlind(Number(e.target.value))}
                  placeholder="Small Blind"
                />
              </Form.Group>
              <Form.Group>
                <Form.Label>Min Buy-In:</Form.Label>
                <Form.Control
                  name="minBuyIn"
                  type="number"
                  value={minBuyIn}
                  onChange={(e) => setMinBuyIn(Number(e.target.value))}
                  placeholder="Min Buy-In"
                />
              </Form.Group>
              <Form.Group>
                <Form.Label>Max Buy-In:</Form.Label>
                <Form.Control
                  name="maxBuyIn"
                  type="number"
                  value={maxBuyIn}
                  onChange={(e) => setMaxBuyIn(Number(e.target.value))}
                  placeholder="Max Buy-In"
                />
              </Form.Group>
              <Form.Group>
                <Form.Label>Your Buy-In Amount:</Form.Label>
                <Form.Control
                  name="buyIn"
                  type="number"
                  value={buyIn}
                  onChange={(e) => setBuyIn(Number(e.target.value))}
                  placeholder="Your Buy-In Amount"
                />
              </Form.Group>
            </Form>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="dark" onClick={handleSubmit}>
              Submit
            </Button>
          </Modal.Footer>
        </Modal>
      )}
    </div>
  );
};

export default CreateTableModal;
