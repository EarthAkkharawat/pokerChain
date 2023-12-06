import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button, Col, Container, Row } from "react-bootstrap";
import { ethers } from 'ethers';

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
// const MOCK_PLAYER_CARDS: number[] = [6, 7];

const Table: React.FC = () => {
  // logic goes here
  // const navigate = useNavigate();
  const [contract, setContract] = useState<any>(null);
  const [gameId, setGameId] = useState<number>(-1);
  const [gameStatus, setGameStatus] = useState<number>(1);
  const [tableCards, setTableCards] = useState<number[]>([255, 255, 255, 255, 255]);
  const [potSize, setPotSize] = useState<string>("0");
  const [currentPlayer, setCurrentPlayer] = useState<string>("None");
  const [nextPlayer, setNextPlayer] = useState<string>("None");
  const [playerCards, setPlayerCards] = useState<number[]>([255, 255]);
  const [gameStatusText, setGameStatusText] = useState<string>("None");

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
      const handleOpenTableCard = (_gameId: number, communityCards: number[]) => {
        if (gameId === _gameId ) { 
          setTableCards(communityCards);
          fetchAndSetPlayerCards();
        }
        console.log(_gameId ,"communityCards updated ->", communityCards)
      };
      const handleNextPlayerAction = (_gameId: number, player: string, actionType: number, amount: number, nextPlayer: string) => {
        // Handle Next Player Action
        // 1 = CALL, 2 = RAISE, 3 = CHECK, 4 = FOLD, 5 = IDLE, 6 = ALLIN
        if (gameId === _gameId ) {
          const _gameStatusText = (actionType === 1 ? "CALL" : actionType === 2 ? "RAISE" : actionType === 3 ? "CHECK" : actionType === 4 ? "FOLD" : actionType === 5 ? "IDLE" : actionType === 6 ? "ALLIN" : "") + " with amount " + amount.toString();
          setGameStatusText(_gameStatusText);
          setCurrentPlayer(player);
          setNextPlayer(nextPlayer);
        }
        console.log(_gameId ,"turn changed -> current player", player, "next player", nextPlayer);
      };

      const handleGameEnded = (_gameId: number, winner: string, winnings: number) => {
        // Handle Game Ended
        // some logic here
        if (gameId === _gameId ) { alert("Game ended\nwinner: " + winner + "\nwinnings: " + winnings); }
        console.log(_gameId ,"Game ended -> winner:", winner, "winnings:", winnings);
      };

      const handlePotUpdated = (_gameId: number, newPotSize: number) => {
        // Handle Pot Updated
        if (gameId === _gameId ) { 
          setPotSize(newPotSize.toString()); 
        }
        console.log(_gameId ,"newPotSize ->", newPotSize);
      };

      const fetchAndSetPlayerCards = async () => {
        try {
          const playerCard = await contract.getMyHand(gameId);
          setPlayerCards(playerCard);
        } catch (error) {
          console.error("Error fetching player cards:", error);
        }
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
  }, [gameId, contract]);

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
    console.log("startGame", contract)
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
  // useEffect(() => {
  //   const fetchPlayerCards = async () => {
  //     console.log("fetchPlayerCards", contract)
  //     if (contract) {
  //       const playerCard = await contract.getMyHand(gameId);
  //       console.log("playerCards ->", playerCards);
  //       setPlayerCards(playerCard);
  //     }
  //   }
  //   fetchPlayerCards();
  // }, [gameId, contract, playerCards])

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

  const [value, setValue] = useState<number | any>(0);

  return (
    <Container
      fluid
      className="background-container justify-content-between text-center"
      style={{ backgroundImage: `url(${pokerBG})` }}
    >
      {false && (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}><Button variant="light" style={{}} onClick={() => startGame(1)}>START GAME</Button></div>
      )}

      {(gameStatus > 2 || true) && (
        <>
          <div style={{
              display: "flex",
              flexDirection: "column",
              backgroundColor: "#003366", // A deeper shade of blue for better contrast
              color: "white",
              padding: "15px", // Add some padding for spacing
              borderRadius: "10px", // Rounded corners
              boxShadow: "0 4px 8px rgba(0, 0, 0, 0.1)", // Subtle shadow for depth
              maxWidth: "300px", // Limiting width for better text readability
              margin: "20px", // Margin to prevent sticking to the screen edges
              textAlign: "center" // Center align text
          }}>
              <div style={{ marginBottom: "10px" }}>Current pot size: {potSize}</div>
              <div style={{ marginBottom: "10px" }}>Previous player: {currentPlayer}</div>
              <div style={{ marginBottom: "10px" }}>Previous action: {gameStatusText}</div>
              <div>Current player: {nextPlayer}</div>
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
            <SelfPlayer playerCards={playerCards} />
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '5%' }}>
              <Button variant="light" style={{}} onClick={() => check()}>Check</Button>
              <Button variant="light" style={{}} onClick={() => call()}>Call</Button>
              <Button variant="light" style={{}} onClick={() => raise(value)}>Raise</Button>
              <Button variant="light" style={{}} onClick={() => fold()}>Fold</Button>
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
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
