// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library CardUtils {

    struct HandResult {
        uint8 score;
        uint8[] bestHand;
    }

    function getRank(uint8 card) internal pure returns (uint8) {
        return card / 4;
    }

    function getSuit(uint8 card) internal pure returns (uint8) {
        return card % 4;
    }

    function combineHand(uint8[] memory playerHands, uint8[] memory tableCards) internal pure returns (uint8[] memory hand) {
        hand = new uint8[](7);
        for (uint8 i = 0; i < 2; i++) { hand[i] = playerHands[i]; }
        for (uint8 j = 0; j < 5; j++) { hand[j] = tableCards[j]; }
        return hand;
    }

    function getHandScore(uint8[] memory hand) internal pure returns (uint8 score, uint8[] memory bestHand) {

    }

    function checkWinningHands(uint8[][] memory playerHands, uint8[] memory tableCards) internal pure returns (uint[] memory) {
        uint8 numberOfPlayers = uint8(playerHands.length);
        HandResult[] memory handResults = new HandResult[](numberOfPlayers);

        for (uint i = 0; i < numberOfPlayers; i++) {
            uint8[] memory hand = combineHand(playerHands[i], tableCards);
            (uint8 handScore,uint8[] memory bestHand) = getHandScore(hand);
            handResults[i] = HandResult(handScore, bestHand);
        }

        // determine winner
        
    }

}