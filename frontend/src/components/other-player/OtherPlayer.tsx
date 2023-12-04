import React from "react";
import { Col, Container, Row } from "react-bootstrap";
import foldCard from "../../assets/cards/255.png";
import ProfilePicture from "../profile-picture/ProfilePicture";
import PokerCard from "../card/PokerCard";

interface OtherPlayerProps {
  showCards?: boolean; // nullable for test
  cards?: string[]; // nullable for test
  playerLeft?: boolean;
}

const OtherPlayer: React.FC<OtherPlayerProps> = ({
  showCards,
  cards,
  playerLeft = true,
}) => {
  const { left, top } = playerLeft
    ? { left: "-300px", top: "125px" }
    : { left: "45px", top: "125px" };

  return (
    <Container>
      <Row>
        <Col className="position-relative">
          <PokerCard
            url={foldCard}
            style={{
              zIndex: 2,
            }}
          />

          <PokerCard
            url={foldCard}
            style={{
              zIndex: 1,
              left: "50px",
              top: "50px",
            }}
            className="position-absolute"
          />
        </Col>
        <Col className="position-relative">
          <div
            className="position-absolute"
            style={{ zIndex: 2, left: left, top: top }}
          >
            <ProfilePicture size="100px" />
          </div>
        </Col>
      </Row>
    </Container>
  );
};

export default OtherPlayer;
