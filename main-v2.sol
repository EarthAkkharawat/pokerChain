// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './game-logic/utils.sol';

contract PokerChain {
    struct Game {
        address owner;
        address[] players;
        mapping(address => bytes32) playerStates;
        mapping(address => uint256) playerChips;
        mapping(address => uint8) cardMasks;
        uint256[] ranks;
        uint256 pot;
        uint256 randomSeed;
        uint256 matchStartTime;
        uint256 smallBlind;
        uint256 minBuyIn;
        uint256 maxBuyIn;
        uint256 lastBet;
        uint8 currentPlayerIndex;
        uint8 verifiedPlayerCount;
        uint8 gameCount;
        GameStatus status;
    }

    enum GameStatus {
        Create,
        AwaitingToStart,
        PreFlop,
        Flop,
        Turn,
        River,
        Reveal,
        Clear,
        Finish
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
        RoyalFlush
    }

    address private owner;
    uint256 private commission; // pay to our system
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

    function createGame(uint256 smallBlind, uint256 minBuyIn, uint256 maxBuyIn, bytes32 playerHash) public payable returns (uint256) {
        
        require(minBuyIn <= maxBuyIn, "Minimum buy in must not exceed maximum buy in");

        uint256 gameId = nextGameId++;
        Game storage newGame = games[gameId];
        newGame.owner = msg.sender;
        newGame.smallBlind = smallBlind;
        newGame.minBuyIn = minBuyIn;
        newGame.maxBuyIn = maxBuyIn;
        newGame.status = GameStatus.Create;
        
        _joinGame(gameId, playerHash);
        return gameId;
    }

    function joinGame(uint256 gameId, bytes32 playerHash) public payable {
        _joinGame(gameId, playerHash);
    }

    function _joinGame(uint256 gameId, bytes32 playerHash) internal {
        Game storage game = games[gameId];
        require(game.status == GameStatus.Create, "Game not in correct state");
        require(msg.value >= commission + game.minBuyIn && msg.value <= commission + game.maxBuyIn, "Deposit amount must not less than minBuyIn and not more than MaxBuyIn");
        require(game.players.length < MAX_PLAYERS, "Game is full");

        game.players.push(msg.sender);
        game.playerStates[msg.sender] = playerHash;
        game.playerChips[msg.sender] = msg.value - commission;
        game.cardMasks[msg.sender] = 0;
        game.verifiedPlayerCount++;

        if (game.verifiedPlayerCount == MAX_PLAYERS) {
            game.verifiedPlayerCount = 0;
            game.status = GameStatus.AwaitingToStart;
            payable(owner).transfer(MAX_PLAYERS * commission); // pay commission to us
        }
    }

    function startGame(uint8 gameId) public onlyOwner {
        Game storage game = games[gameId];
        require(game.status == GameStatus.AwaitingToStart, "Game not in correct state");

        game.status = GameStatus.PreFlop;
        // deal the card
    }

    function foldHand() public {

    }

    function betHand() public {
        
    }

    function reveal() public {

    }

    function clear() public {

    }
}