// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library CardUtils {

    uint8 private constant nCards = 52;
    uint8 private constant HIGH_CARD = 0;
	uint8 private constant ONE_PAIR = 1;
	uint8 private constant TWO_PAIR = 2;
	uint8 private constant THREE_OF_A_KIND = 3;
	uint8 private constant STRAIGHT = 4;
	uint8 private constant FLUSH = 5;
	uint8 private constant FULL_HOUSE = 6;
	uint8 private constant FOUR_OF_A_KIND = 7;
	uint8 private constant STRAIGHT_FLUSH = 8;
    uint8 private constant ROYAL_FLUSH = 9;
	uint256 private constant TOTAL_5_CARD_COMBINATIONS = 52 ** 5;

    modifier onlyValidHands(uint8[] memory cards) {
        require(cards.length == 7, "Invalid hands");
        _;
    }

    function isNCardsEqual(uint8[] memory cards, uint8 n, uint8 times) internal pure onlyValidHands(cards) returns (bool) {
        require(times == 1 || times == 2, "times parameter must be either 1 or 2");
        uint8[13] memory rankCount = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        for (uint i = 0; i < cards.length; i++) {
            uint8 rank = cards[i] / 4;
            rankCount[rank]++;
        }
        uint8 counter = 0;
        for (uint8 j = 12; j >= 0; j--) {
            if (rankCount[j] == n) {
                counter++;
            }
            if (counter == times) {
                return true;
            }
        }
        return false;
    }

    function isFlush(uint8[] memory cards) internal pure onlyValidHands(cards) returns (bool) {
        uint8[4] memory suitCount = [0, 0, 0, 0];
        for (uint i = 0; i < cards.length; i++) {
            uint8 suit = cards[i] % 4;
            suitCount[suit]++;
        }
        for (uint8 j = 3; j >= 0; j--) {
            if (suitCount[j] >= 5) {
                return true;
            }
        }
        return false;
    }

    function isStraight(uint8[] memory cards) internal pure onlyValidHands(cards) returns (bool) {
        uint8[13] memory rankCount = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        for (uint i = 0; i < cards.length; i++) {
            uint8 rank = cards[i] / 4;
            rankCount[rank]++;
        }
        uint8 streak = 0;
        for (uint8 j = 12; j >= 0; j--) {
            if (rankCount[j] > 0) {
                streak += 1;
            }
            else {
                streak = 0;
            }
            if (streak == 5) {
                return true;
            }
        }
        return false;
    }

    function isTJQKA(uint8[] memory cards) internal pure returns (bool) {
        uint8[5] memory tjqkaCount = [0, 0, 0, 0, 0];
        for (uint i = 0; i < cards.length; i++) {
            uint8 rank = cards[i] / 4;
            if (8 <= rank && rank <= 12) {
                tjqkaCount[rank - 8]++;
            }
        }
        for (uint8 j = 0; j < 4; j++) {
            if (tjqkaCount[j] <= 0) {
                return false;
            }
        }
        return true;
    }

    function findWinningHand(uint8[] memory hand, uint8[] memory table) public pure returns (uint8, uint8[] memory) {
        
    }

}