import React from "react";
import PokerCard from "../card/PokerCard";
import ProfilePicture from "../profile-picture/ProfilePicture";
import { Col, Container, Row } from "react-bootstrap";

interface SelfPlayerProps {
  playerCards: number[];
}

const CARD_WIDTH = 175;
const CARD_HEIGHT = 225;

const SelfPlayer: React.FC<SelfPlayerProps> = ({ playerCards }) => {
  return (
    <Container>
      <Row className="position-relative">
        <Col>
          {playerCards.map((playerCard) => {
            return (
              <>
                <PokerCard
                  url={require(`../../assets/cards/${playerCard}.png`)}
                  style={{
                    width: CARD_WIDTH,
                    height: CARD_HEIGHT,
                    marginLeft: "10px",
                  }}
                />
              </>
            );
          })}
        </Col>
        <Col
          className="position-absolute"
          style={{
            zIndex: 1,
            left: "250px",
            top: "100px",
          }}
        >
          <ProfilePicture size="100px" />
        </Col>
      </Row>
    </Container>
  );
};

export default SelfPlayer;
