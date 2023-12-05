import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button, Col, Container, Row } from "react-bootstrap";
import SelfPlayer from "../self-player/SelfPlayer";
import OtherPlayer from "../other-player/OtherPlayer";
import CardRow from "../card/CardRow";
import { getPokerGameContract } from "../../utils/contracts";
import RangeSlider from 'react-bootstrap-range-slider';

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
  const [gameStatus, setGameStatus] = useState<number>(1);
  const [tableCards, setTableCards] = useState<number[]>([255,255,255,255,255]);

  useEffect(() => {
    const fetchContract = async () => {
      const fetchedContract = await getPokerGameContract();
      setContract(fetchedContract);
      setGameId(Number(window.location.pathname.split("/")[2]));
    };
    fetchContract();
    // console.log("contract:", contract);
  }, []); 

  useEffect(() => {
    const fetchGameDetails = async () => {
        if (contract) {
            const gameDetails = await contract.getGameBasicDetails(gameId);
            setGameStatus(gameDetails.status);
        }
    };
    fetchGameDetails();
  }, [contract, gameId]);

  useEffect(() => {
    console.log("contract:", contract);
    console.log("gameId:", gameId);
    console.log("gameStatus:", gameStatus);
  }, [contract, gameId, gameStatus]); 

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
        console.log("Game started");
      } catch (error) {
        alert(error);
      }
  };

  const check = async () => {
    if (contract) {
      try {
        await contract.checkAction(gameId);
      }
      catch (error) {
        alert(error);
      }
    }
  }

  const call = async () => {
    if (contract) {
      try {
        await contract.callAction(gameId);
      }
      catch (error) {
        alert(error);
      }
    }
  }
   
  const raise = async (raiseAmount: Number) => {
    if (contract) {
      try {
        await contract.raiseAction(gameId, raiseAmount);
      }
      catch (error) {
        alert(error);
      }
    }
  } 

  const fold = async () => {
    if (contract) {
      try {
        await contract.foldAction(gameId);
      }
      catch (error) {
        alert(error);
      }
    }
  }

  const [ value, setValue ] = useState<number| any>(0); 

  return (
    <Container
      fluid
      className="background-container justify-content-between text-center"
      style={{ backgroundImage: `url(${pokerBG})` }}
    >
      {false && (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh'}}><Button variant="light" style = {{}} onClick={() => startGame(1)}>START GAME</Button></div>
      )}

      {(gameStatus > 2 || true) && (
        <>
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
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '5%'}}>
              <Button variant="light" style = {{}} onClick={() => check()}>Check</Button>
              <Button variant="light" style = {{}} onClick={() => call()}>Call</Button>
              <Button variant="light" style = {{}} onClick={() => raise(value)}>Raise</Button>
              <Button variant="light" style = {{}} onClick={() => fold()}>Fold</Button> 
            </div> 
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center'}}>
            <RangeSlider
                value={value}
                onChange={changeEvent => setValue(changeEvent.target.value)}
                min={10}
                max={200}
              />
            </div>
          </Row>
        </>
      )}
    </Container>
  );
};

export default Table;
