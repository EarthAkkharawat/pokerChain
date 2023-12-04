import React from "react";
import { Col, Container, Row } from "react-bootstrap";
import SelfPlayer from "../self-player/SelfPlayer";
import OtherPlayer from "../other-player/OtherPlayer";
import CardRow from "../card/CardRow";

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
  return (
    <Container
      fluid
      className="background-container justify-content-between text-center"
      style={{ backgroundImage: `url(${pokerBG})` }}
    >
      <Row className="mt-5">
        <Col>
          <OtherPlayer />
        </Col>
        <Col>
          <OtherPlayer playerLeft={false} />
        </Col>
      </Row>
      <Row className="my-5">
        <CardRow cards={MOCK_CARDS} />
      </Row>
      <Row className="mb-5">
        <SelfPlayer playerCards={MOCK_PLAYER_CARDS} />
      </Row>
    </Container>
  );
};

export default Table;
