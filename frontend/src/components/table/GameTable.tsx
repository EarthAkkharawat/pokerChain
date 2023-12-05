import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button, Col, Container, Row } from "react-bootstrap";
import SelfPlayer from "../self-player/SelfPlayer";
import OtherPlayer from "../other-player/OtherPlayer";
import CardRow from "../card/CardRow";
import { getPokerGameContract } from "../../utils/contracts";

import pokerBG from "../../assets/poker-background.jpg";
import "./GameTable.styles.css";

interface CardProps {
  url: string;
  className?: string;
  style?: React.CSSProperties;
}

const MOCK_CARDS: number[] = [1, 2, 3, 4, 5];
const MOCK_PLAYER_CARDS: number[] = [6, 7];

const Table: React.FC = () => {
  // logic goes here
  // const navigate = useNavigate();
  const [contract, setContract] = useState<any>(null);
  const [gameId, setGameId] = useState<number>(-1);
  const [tableCards, setTableCards] = useState<number[]>([255,255,255,255,255]);

  useEffect(() => {
    const fetchData = async () => {
      const fetchedContract = await getPokerGameContract();
      setContract(fetchedContract);
      setGameId(Number(window.location.pathname.split("/")[2]));
    };
    fetchData();
    // console.log("contract:", contract);
  }, []); 

  useEffect(() => {
    console.log("contract:", contract);
    console.log("gameId:", gameId);
  }, [contract, gameId]); 

  // useState(() => {
  //   const fetchData = async() => {

  //   }
  // })

  const startGame = async (seed: Number) => {
      if (!contract) return;
      try {
        const tx = await contract.startGame(
          gameId,
          seed
        );
        await tx.wait();
      } catch (error) {
        alert(error);
      }
  };

  return (
    <Container
      fluid
      className="background-container justify-content-between text-center"
      style={{ backgroundImage: `url(${pokerBG})` }}
    >
      <Button onClick={() => startGame(1)}>STARTTTTTTTTT</Button>
      <Row className="mt-5">
        <Col>
          <OtherPlayer />
        </Col>
        <Col>
          <OtherPlayer playerLeft={false} />
        </Col>
      </Row>
      <Row className="my-5">
        <CardRow cards={tableCards} />
      </Row>
      <Row className="mb-5">
        <SelfPlayer playerCards={MOCK_PLAYER_CARDS} />
      </Row>
    </Container>
  );
};

export default Table;
