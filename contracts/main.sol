// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './game-logic/utils.sol';

/**
 * @title PokerChain
 * @dev Implements a secure, decentralized PVP drop-poker platform.
 */
contract PokerChain {
    struct Game {
        address owner;
        address[] players;
        mapping(address => bytes32) playerStates;
        mapping(address => uint8) cardMasks;
        uint256[] ranks;
        uint256[] deck;
        uint256 pot;
        uint256 randomSeed;
        uint256 matchStartTime;
        uint256 smallBlind;
        uint256 bigBlind;
        uint256 minBuyIn;
        uint256 maxBuyIn;
        uint256 bettingLimit;
        uint256 lastBet;
        uint8 currentPlayerIndex;
        uint8 verifiedPlayerCount;
        uint8 gameCount;
        GameStatus status;
    }

    enum GameStatus {
        Created,
        AwaitingToStart,
        PreFlop,
        Flop,
        Turn,
        Liver,
        Reveal,
        Clear
    }

    enum PokerHand {
        HighCard,
        OnePair,
        TwoPair,
        ThreeOfAKind,
        Straight,
        Flush,
        FullHouse,
        FourOfAKind,
        StraightFlush,
        RoyalStraightFlush
    }

    address private owner;
    uint256 private commission;
    uint256 private nextGameId;
    uint8 private constant MAX_PLAYERS = 2;
    uint8 private constant TOTAL_CARDS = 52;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    mapping(uint256 => Game) private games;

    constructor(uint256 _commission) {
        owner = msg.sender;
        commission = _commission;
    }

    function createGame(bytes32 playerHash, uint256 smallBlind, uint256 minBuyIn, uint256 maxBuyIn) public payable returns (uint256) {
        require(minBuyIn > 0, "Min BuyIn must greater than Zero");
        require(smallBlind > 0, "Small Blind must greater than Zero");
        require(msg.value >= minBuyIn && msg.value <= maxBuyIn, "Deposit amount must not less than minBuyIn and not greater than MaxBuyIn");

        uint256 gameId = nextGameId++;
        Game storage newGame = games[gameId];
        newGame.owner = msg.sender;
        newGame.smallBlind = smallBlind;
        newGame.bigBlind = smallBlind*2;
        newGame.minBuyIn = minBuyIn;
        newGame.maxBuyIn = maxBuyIn;
        newGame.status = GameStatus.Created;
        for (uint256 i = 0; i < 52; i++) {
            newGame.deck.push(i);
        }
        _joinGame(gameId, playerHash);
        return gameId;
    }
    
    function joinGame(uint256 gameId, bytes32 playerHash) public payable {
        _joinGame(gameId, playerHash);
    }

    function _joinGame(uint256 gameId, bytes32 playerHash) internal {
        Game storage game = games[gameId];
        require(game.status == GameStatus.Created, "Game not in correct state");
        require(msg.value >= commission + game.minBuyIn && msg.value <= commission + game.maxBuyIn, "Deposit amount must not less than minBuyIn and not more than MaxBuyIn");
        require(game.players.length <= MAX_PLAYERS, "Game is full");

        game.players.push(msg.sender);
        game.playerStates[msg.sender] = playerHash;
        // game.cardMasks[msg.sender] = 0;
        game.verifiedPlayerCount++;

        if (game.verifiedPlayerCount == MAX_PLAYERS) {
            game.verifiedPlayerCount = 0;
            game.status = GameStatus.AwaitingToStart;
            payable(owner).transfer(MAX_PLAYERS * commission);
        }
    }

    function getGameBasicDetails(uint256 gameId) public view returns (
        address oowner,
        uint256 pot,
        uint256 matchStartTime,
        GameStatus status
    ) {
        Game storage game = games[gameId];
        return (game.owner, game.pot, game.matchStartTime, game.status);
    }

    // Function to get player-specific details in a game
    function getPlayerDetails(uint256 gameId, address player) public view returns (
        bytes32 playerState,
        uint8 cardMask
    ) {
        Game storage game = games[gameId];
        return (game.playerStates[player], game.cardMasks[player]);
    }

    // Function to get an array of player addresses
    function getPlayers(uint256 gameId) public view returns (address[] memory) {
        return games[gameId].players;
    }

    function drawCard(uint256 gameId, uint256 seed) public onlyOwner returns (uint256) {
        Game storage game = games[gameId];
        require(game.deck.length > 0, "No more cards in the deck");
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty))) % game.deck.length;
        uint256 card = game.deck[randomIndex];
        game.deck[randomIndex] = game.deck[game.deck.length - 1];
        game.deck.pop();

        return card;
    }

    // function makeBet(uint256 gameId, uint256 betAmount) public payable {
    //     Game storage game = games[gameId];
    //     require(game.status == GameStatus.FirstTurn || game.status == GameStatus.SecondTurn, "Not in betting stage");
    //     require(msg.value == betAmount, "Bet amount does not match sent value");
    //     require(betAmount >= game.lastBet && betAmount <= game.bettingLimit, "Bet amount not within limits");

    //     game.pot += betAmount;
    //     game.lastBet = betAmount;
    //     game.currentPlayerIndex = (game.currentPlayerIndex + 1) % MAX_PLAYERS;

    //     // Update game status based on the current phase of the game
    //     if (game.currentPlayerIndex == 0) {
    //         if (game.status == GameStatus.FirstTurn) {
    //             game.status = GameStatus.WaitingStateAfterChange;
    //         } else if (game.status == GameStatus.SecondTurn) {
    //             game.status = GameStatus.Reveal;
    //         }
    //     }
    // }

}
