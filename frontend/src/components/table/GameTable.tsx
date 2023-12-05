import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button, Col, Container, Row } from "react-bootstrap";
import { ethers } from 'ethers';

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
  const [gameStatus, setGameStatus] = useState<number>(1);
  const [tableCards, setTableCards] = useState<number[]>([255,255,255,255,255]);
  const [potSize, setPotSize] = useState<number>(0);
  const [currentPlayer, setCurrentPlayer] = useState<string>("");
  const [nextPlayer, setNextPlayer] = useState<string>("");

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
    if (contract && gameId >= 0) {
        const handleOpenTableCard = (gameId: number, communityCards: number[]) => {
            setTableCards(communityCards);
            console.log("communityCards updated ->", communityCards)
        };
        const handleNextPlayerAction = (gameId: number, player: string, actionType: number, amount: number, nextPlayer: string) => {
            // Handle Next Player Action
            // 1 = CALL, 2 = RAISE, 3 = CHECK, 4 = FOLD, 5 = IDLE, 6 = ALLIN
            setCurrentPlayer(player);
            setNextPlayer(nextPlayer);
            console.log("turn changed -> current player",player,"next player", nextPlayer)
        };
    
        const handleGameEnded = (gameId: number, winner: string, winnings: number) => {
          // Handle Game Ended
          // some logic here
            alert("Game ended\nwinner: " + winner + "\nwinnings: " + winnings)
            console.log("Game ended -> winner:", winner, "winnings:", winnings)
        };
    
        const handlePotUpdated = (gameId: number, newPotSize: number) => {
          // Handle Pot Updated
            setPotSize(newPotSize);
            console.log("newPotSize ->", newPotSize)
        };

        contract.on('GameStateChanged', handleOpenTableCard);
        contract.on('NextPlayerAction', handleNextPlayerAction);
        contract.on('GameEnded', handleGameEnded);
        contract.on('PotUpdated', handlePotUpdated);

        // Cleanup function
        return () => {
            // contract.off('GameStateChanged', listener);
        };
    }
  }, [contract, gameId]);

  // useEffect(() => {
  //   const fetchGameDetails = async () => {
  //       if (contract) {
  //           const gameDetails = await contract.getGameBasicDetails(gameId);
  //           setGameStatus(gameDetails.status);
  //       }
  //   };
  //   fetchGameDetails();
  // }, [contract, gameId]);

  // useEffect(() => {
  //   console.log("contract:", contract);
  //   console.log("gameId:", gameId);
  //   console.log("gameStatus:", gameStatus);
  // }, [contract, gameId, gameStatus]); 


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

  const callAction = async () => {
    if (!contract) return;
    try {

    } catch (error) {
      alert(error);
    }
  };

  const raiseAction = async (raiseAmount: Number) => {
    if (!contract) return;
    try {

    } catch (error) {
      alert(error);
    }
  }

  const foldAction = async () => {
    if (!contract) return;
    try {

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
      {false && (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh'}}><Button variant="light" style = {{}} onClick={() => startGame(1)}>START GAME</Button></div>
      )}

      {(gameStatus > 2 || true) && (
        <>
          <div style = {{ display:"flex",flexDirection:"column", backgroundColor:"blue", color:"white"}}>
            <div>POT SIZE: {potSize}</div>
            <div>CURRENT ADDRESS: {currentPlayer}</div>
            <div>NEXT ADDRESS: {nextPlayer}</div>
          </div>
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
        </>
      )}
    </Container>
  );
};

export default Table;
