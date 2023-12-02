// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @title PokerUtils
 */
library PokerUtils {
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
	
	function calcHandRank(uint256 hand, uint8 combination) pure internal returns(uint256) {
	    return TOTAL_5_CARD_COMBINATIONS * combination + hand;
	}
    
    // check if all N cards have the same number
    function checkNCardsEqual(uint256 hand, uint8 size, uint8 offset) pure internal returns(bool) {
        uint8 goldenCardId = nCards;
        for(uint i = 0; i < 5; ++i) {
            uint8 card = uint8(hand % nCards);
            uint8 cardId = card / 4;
            hand = hand / nCards;
            if (i >= offset && i < offset + size) {
                if (goldenCardId == nCards) {
                    goldenCardId = cardId;
                    continue;
                }
                if (goldenCardId != cardId) {
                    return false;
                }
            }
        }
        return true;
    }

    // check if all 5 cards have the same sign
    function checkFlush(uint256 hand) pure internal returns(bool) {
        uint8 goldenType = nCards;
        for(uint i = 0; i < 5; ++i) {
            uint8 card = uint8(hand % nCards);
            uint8 cardType = card % 4;
            hand = hand / nCards;
            if (goldenType == nCards) {
                goldenType = cardType;
                continue;
            }
            if (goldenType != cardType) {
                return false;
            }
        }
        return true;
    }
    
    // check if all 5 cards are consecutive number
    function checkStraight(uint256 hand) pure internal returns(bool) {
        uint8 lastId = nCards;
        for(uint i = 0; i < 5; ++i) {
            uint8 card = uint8(hand % nCards);
            uint8 cardId = card / 4;
            hand = hand / nCards;
            if (i > 0) {
                if (cardId + 1 != lastId) {
                    return false;
                }
            }
            lastId = cardId;
        }
        return true;
    }

    // check if all 5 card is either 10,J,Q,K,A (special case for royal flush)
    function checkTJQKA(uint256 hand) pure internal returns(bool) {
        for(uint i = 0; i < 5; ++i) {
            uint8 cardRank = uint8(hand % nCards) / 4;
            if (cardRank < 8 || cardRank > 12) {
                return false;
            }
            hand = hand / nCards;
        }
        return true;
    }
    
    
    function checkClaimedCombination(uint256 claimedHand, uint8 claimedCombination) internal pure returns(bool) {
        if (claimedCombination == HIGH_CARD) {
            return true;
        }
        if (claimedCombination == ONE_PAIR) {
            return checkNCardsEqual(claimedHand, 2, 0);
        }
        
        if (claimedCombination == TWO_PAIR) {
            return checkNCardsEqual(claimedHand, 2, 0) && checkNCardsEqual(claimedHand, 2, 2);
        }
        
        if (claimedCombination == THREE_OF_A_KIND) {
            return checkNCardsEqual(claimedHand, 3, 0);
        }
        
        if (claimedCombination == STRAIGHT) {
            return checkStraight(claimedHand);
        }
        
        if (claimedCombination == FLUSH) {
            return checkFlush(claimedHand);
        }
        
        if (claimedCombination == FULL_HOUSE) {
            return checkNCardsEqual(claimedHand, 3, 0) && checkNCardsEqual(claimedHand, 2, 3);
        }
        
        if (claimedCombination == FOUR_OF_A_KIND) {
            return checkNCardsEqual(claimedHand, 4, 0);
        }
        
        if (claimedCombination == STRAIGHT_FLUSH) {
            return checkStraight(claimedHand) && checkFlush(claimedHand);
        }
        if (claimedCombination == ROYAL_FLUSH) {
            return checkStraight(claimedHand) && checkFlush(claimedHand) && checkTJQKA(claimedHand);
        }
        return false;
    }
    
    function checkClaimedHand(uint256 hand, uint8[5] memory cardIds) internal pure returns(bool) {
        for(uint i = 0; i < 5; ++i) {
            uint8 card = uint8(hand % nCards);
            hand = hand / nCards;
            bool foundEq = false;
            for(uint j = 0;j < 5; ++j) {
                if (card == cardIds[j]) {
                    foundEq = true;
                    break;
                }
            }
            if(!foundEq) {
                return false;
            }
        }
        
        return true;
    }
}