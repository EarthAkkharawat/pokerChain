import React, { useState } from "react";
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
  const [smallBlind, setSmallBlind] = useState<number>(0);
  const [minBuyIn, setMinBuyIn] = useState<number>(0);
  const [maxBuyIn, setMaxBuyIn] = useState<number>(0);
  const [buyIn, setBuyIn] = useState<number>(0);

  const handleSubmit = async () => {
    setShowModal(false);
    try {
      const contract = await getPokerGameContract();
      console.log(contract);

      const options = { value: buyIn.toString() };
      const tx = await contract.createGame(
        smallBlind,
        minBuyIn,
        maxBuyIn,
        options
      );
      await tx.wait();
      const gameCount = await contract.getGameCount();
      setGameList(Array.from({ length: gameCount }, (_, i) => i));
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
