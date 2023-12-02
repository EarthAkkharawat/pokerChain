// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library CardUtils {

    function getRank(uint8 card) internal pure returns (uint8) {
        return card / 4;
    }

    function getSuit(uint8 card) internal pure returns (uint8) {
        return card % 4;
    }

    function sortHand(uint8[] memory hand) internal pure returns (uint8[] memory) {
        uint8 i;
        uint8 j;
        for (i = 1; i < hand.length; i++) {
            uint8 key = hand[i];
            j = i - 1;
            while (j >= 0 && hand[j] < key) {
                hand[j + 1] = hand[j];
                if (j == 0) { break; }
                j--;
            }
            hand[j + 1] = key;
        }
        return hand; 
    }

    function combineHand(uint8[] memory playerHands, uint8[] memory tableCards) internal pure returns (uint8[] memory hand) {
        hand = new uint8[](7);
        for (uint8 i = 0; i < 2; i++) { hand[i] = playerHands[i]; }
        for (uint8 j = 0; j < 5; j++) { hand[j] = tableCards[j]; }
        hand = sortHand(hand);
        return hand;
    }

    function getScore(uint40 hand) public pure returns (uint8 score) {
        score = uint8(hand >> 30);
        return score;
    }

    function decodeHand(uint40 hand) public pure returns (uint8[] memory decodedHand) {
        decodedHand = new uint8[](5);
        for (uint8 i = 0; i < 5; i++) {
            decodedHand[i] = uint8((hand >> (6 * (4 - i))) & 63);
        }
        return decodedHand;
    }

    function encodeHand(uint8[] memory hand, uint8 score) public pure returns (uint40 encodedHand) {
        encodedHand = uint40(score) << 30;
        hand = sortHand(hand);
        for (uint8 i = 0; i < 5; i++) {
            encodedHand |= uint40(hand[i]) << (6 * i);
        }
        return encodedHand;
    }

    function checkWinningHands(uint8[][] memory playerHands, uint8[] memory tableCards) internal pure returns (uint8[][] memory bestHands,uint8[] memory winnerIndices) {
        uint8 numberOfPlayers = uint8(playerHands.length);
        uint40[] memory handScores = new uint40[](numberOfPlayers);
        bestHands = new uint8[][](numberOfPlayers);

        for (uint i = 0; i < numberOfPlayers; i++) {
            uint8[] memory hand = combineHand(playerHands[i], tableCards);
            handScores[i] = getHandScore(hand);
            bestHands[i] = decodeHand(handScores[i]);
        }
        winnerIndices = getWinner(handScores);
        return (bestHands, winnerIndices);
    }

    function getHandScore(uint8[] memory hand) internal pure returns (uint40) {
        uint8[] memory bestHand;
        bool passCondition;
        (passCondition, bestHand) = isRoyalFlush(hand);     if (passCondition) { return encodeHand(bestHand, 9); }
        (passCondition, bestHand) = isStraightFlush(hand);  if (passCondition) { return encodeHand(bestHand, 8); }
        (passCondition, bestHand) = isNOfAKind(hand, 4);    if (passCondition) { return encodeHand(bestHand, 7); }
        (passCondition, bestHand) = isFullHouse(hand);      if (passCondition) { return encodeHand(bestHand, 6); }
        (passCondition, bestHand) = isFlush(hand);          if (passCondition) { return encodeHand(bestHand, 5); }
        (passCondition, bestHand) = isStraight(hand);       if (passCondition) { return encodeHand(bestHand, 4); }
        (passCondition, bestHand) = isNOfAKind(hand, 3);    if (passCondition) { return encodeHand(bestHand, 3); }
        (passCondition, bestHand) = isTwoPair(hand);        if (passCondition) { return encodeHand(bestHand, 2); }
        (passCondition, bestHand) = isNOfAKind(hand, 2);    if (passCondition) { return encodeHand(bestHand, 1); }
        (, bestHand) = isNOfAKind(hand, 1);
        return encodeHand(bestHand, 0);
    }

    function getWinner(uint40[] memory handScores) internal pure returns (uint8[] memory winnerIndices) {
        uint highestScore = 0;
        uint8 countWinners = 0;

        for (uint8 i = 0; i < handScores.length; i++) {
            if (handScores[i] > highestScore) {
                highestScore = handScores[i];
                countWinners = 1;
            } else if (handScores[i] == highestScore) {
                countWinners++;
            }
        }

        winnerIndices = new uint8[](countWinners);
        uint8 index = 0;
        for (uint8 i = 0; i < handScores.length; i++) {
            if (handScores[i] == highestScore) {
                winnerIndices[index] = i;
                index++;
            }
        }
        return winnerIndices;
    }

    function isRoyalFlush(uint8[] memory hand) internal pure returns (bool, uint8[] memory bestHand) {
        bestHand = new uint8[](5);
        uint8[5] memory royalRanks = [12, 11, 10, 9, 8];
        uint8 counter;
        for (uint8 i = 3; i >= 0; i--) {
            counter = 0;
            for (uint8 j = 0; j < hand.length && counter < 5; j++) {
                if (getSuit(hand[j]) == i && getRank(hand[j]) == royalRanks[counter]) {
                    bestHand[counter] = hand[j];
                    counter++;
                }
            }
            if (counter == 5) {
                return (true, bestHand);
            }
            if (i == 0) { break; }
        }
        return (false, bestHand);
    }

    function isStraightFlush(uint8[] memory hand) internal pure returns (bool, uint8[] memory bestHand) {
        bestHand = new uint8[](5);
        uint8 counter;
        uint8 lastRank;
        uint8 currentRank;
        // uint8 isAce;
        for (uint8 i = 3; i >= 0; i--) {
            counter = 0;
            // isAce = 255;
            for (uint8 j = 0; j < hand.length && counter < 5; j++) {
                if (getSuit(hand[j]) == i) {
                    currentRank = getRank(hand[j]);
                    if (counter == 0) {
                        // isAce = currentRank == 12 ? j : 255;
                        lastRank = currentRank;
                        bestHand[counter] = hand[j];
                        counter++; 
                    }
                    else if (currentRank == lastRank - 1) {
                        lastRank = currentRank;
                        bestHand[counter] = hand[j];
                        counter++;
                    }
                    // else if (currentRank == 0 && counter == 4 && isAce!=255) {
                    //     bestHand[counter] = hand[isAce];
                    //     counter++;
                    // }
                    else {
                        counter = 0;
                        lastRank = currentRank;
                        bestHand[counter] = hand[j];
                        counter++;
                    }
                    if (counter == 5) {
                        return (true, bestHand);
                    }
                }
            }
            if (i == 0) { break; }
        }
        return (false, bestHand);
    }

    function isFullHouse(uint8[] memory hand) internal pure returns (bool, uint8[] memory bestHand) {
        bestHand = new uint8[](5);
        uint8[] memory rankCounts = new uint8[](13);
        uint8 i;

        // Count the number of cards for each rank
        for (i = 0; i < hand.length; i++) {
            rankCounts[getRank(hand[i])]++;
        }

        uint8 threeOfAKindRank = 255; // Invalid rank, used as a flag
        uint8 pairRank = 255;

        // First, find Three of a Kind
        for (i = 12; i >= 0; i--) {
            if (rankCounts[i] >= 3) {
                threeOfAKindRank = i;
                break;
            }
            if (i == 0) { break; }
        }
        // Then, find a Pair
        if (threeOfAKindRank != 255) {
            for (i = 12; i >= 0; i--) {
                if (rankCounts[i] >= 2 && i != threeOfAKindRank) {
                    pairRank = i;
                    break;
                }
                if (i == 0) { break; }
            }
        }

        // if full house
        if (threeOfAKindRank != 255 && pairRank != 255) {
            uint8 index = 0;
            uint8 counter3 = 0;
            uint8 counter2 = 0;
            for (i = 0; i < hand.length && index < 5; i++) {
                if (getRank(hand[i]) == threeOfAKindRank && counter3 < 3) {
                    bestHand[index] = hand[i];
                    index++;
                    counter3++;
                }
                else if (getRank(hand[i]) == pairRank && counter2 < 2) {
                    bestHand[index] = hand[i];
                    index++;
                    counter2++;
                }
            }
            return (true, bestHand);
        }

        return (false, bestHand);
    }

    function isFlush(uint8[] memory hand) internal pure returns (bool, uint8[] memory bestHand) {
        bestHand = new uint8[](5);
        uint8 i;
        uint8[4] memory suitCounts = [0, 0, 0, 0];
        for (i = 0; i < hand.length; i++) {
             suitCounts[getSuit(hand[i])]++;
        }
        for (i = 3; i >= 0; i--) {
            if (suitCounts[i] >= 5) {
                uint8 counter = 0;
                for (uint8 j = 0; j < hand.length && counter < 5; j++) {
                    if (getSuit(hand[j]) == i) {
                        bestHand[counter] = hand[j];
                        counter++;
                    }
                }
                return (true, bestHand);
            }
            if (i == 0) { break; }
        }
        return (false, bestHand);
    }

    function isStraight(uint8[] memory hand) internal pure returns (bool, uint8[] memory bestHand) {
        bestHand = new uint8[](5);
        uint8 lastRank = getRank(hand[0]);
        uint8 counter = 1;
        uint8 index = 0;
        for (uint8 i = 1; i < hand.length; i++) {
            uint8 currentRank = getRank(hand[i]);
            if (currentRank == lastRank - 1) {
                counter++;
                bestHand[index] = hand[i];
                index++;
            }
            else if (currentRank != lastRank) {
                bestHand[0] = hand[i];
                index = 1;
                counter = 1;
            }
            lastRank = currentRank;
            if (counter == 5) {
                return (true, bestHand);
            }
        }
        // if (counter == 4 && lastRank == 0 && getRank(hand[i]) == 12) {
        //     bestHand[index] = hand[0];
        //     return (true, bestHand);
        // }
        return (false, bestHand);
    }

    function isNOfAKind(uint8[] memory hand, uint8 n) internal pure returns (bool, uint8[] memory bestHand) {
        require(0 < n && n < 5, "N must be between 1 and 4");
        bestHand = new uint8[](5);
        uint8[] memory rankCounts = new uint8[](13);
        uint8 i;

        for (i = 0; i < hand.length; i++) {
            rankCounts[getRank(hand[i])]++;
        }

        // Check for N of a Kind
        for (i = 12; i >= 0; i--) {
            if (rankCounts[i] >= n) {
                // Found N of a Kind
                uint8 count = 0;
                uint8 remainingCount = 0;

                // Add the N cards of the same rank
                for (uint8 j = 0; j < hand.length && count < n; j++) {
                    if (getRank(hand[j]) == i) {
                        bestHand[count] = hand[j];
                        count++;
                    }
                }

                // Add the next 5-n highest cards
                for (uint8 j = 0; j < hand.length && remainingCount < 5 - n; j++) {
                    // if (getRank(hand[j]) != i) {
                    //     bestHand[count + remainingCount] = hand[j];
                    //     remainingCount++;
                    // }
                    bool dup = false;
                    for (uint8 k = 0; k < n; k++) {
                        if (getRank(hand[j]) == bestHand[k]) {
                            dup = true;
                            break;
                        }
                    }
                    if (!dup) {
                        bestHand[count + remainingCount] = hand[j];
                        remainingCount++;
                    }
                }
                return (true, bestHand);
            }
            if (i == 0) { break; }
        }
        return (false, bestHand);
    }

    function isTwoPair(uint8[] memory hand) internal pure returns (bool, uint8[] memory bestHand) {
        bestHand = new uint8[](5);
        uint8[] memory rankCounts = new uint8[](13);
        uint8 i;

        // Count the number of cards for each rank
        for (i = 0; i < hand.length; i++) {
            rankCounts[getRank(hand[i])]++;
        }

        uint8 firstPairRank = 255; // Invalid rank, used as a flag
        uint8 secondPairRank = 255;

        // Check for pairs
        for (i = 12; i >= 0; i--) {
            if (rankCounts[i] >= 2) {
                if (firstPairRank == 255) {
                    firstPairRank = i;
                } else {
                    secondPairRank = i;
                    break; // Found two pairs
                }
            }
            if (i == 0) { break; }
        }

        if (secondPairRank != 255) {
            // Found Two Pair, add card into bestHand
            uint8 counter1 = 0;
            uint8 counter2 = 0;
            uint8 index = 0;
            bool singleCardAdded = false;
            for (i = 0; i < hand.length && index < 5; i++) {
                if (counter1 < 2 && getRank(hand[i]) == firstPairRank) {
                    bestHand[index] = hand[i];
                    index++;
                    counter1++;
                }
                else if (counter2 < 2 && getRank(hand[i]) == secondPairRank) {
                    bestHand[index] = hand[i];
                    index++;
                    counter2++;
                }
                else if (!singleCardAdded) {
                    singleCardAdded = true;
                    bestHand[index] = hand[i];
                    index++;
                }
            }
            return (true, bestHand);
        }

        return (false, bestHand);
    }

}