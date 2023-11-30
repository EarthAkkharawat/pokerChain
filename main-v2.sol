// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './game-logic/utils.sol';

contract PokerChain {
    struct Game {
        address owner;
        address[] players;
        mapping(address => bytes32) playerStates;
        mapping(address => uint256) playerChips;
        mapping(address => uint256[]) playerCards;
        mapping(address => uint8) cardMasks;
        uint256[] ranks;
        uint256[] deck;
        uint256 pot;
        uint256 randomSeed;
        uint256 matchStartTime;
        uint256 smallBlindAmount;
        uint256 bigBlindAmount;
        uint256 smallBlindPlayer;
        uint256 bigBlindPlayer;
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
        RoyalStraightFlush
    }

    address private owner;
    uint256 private commission; // pay to our system
    uint256 private nextGameId; 
    uint256 private bigBlindPlayerId; 
    uint8 private constant MAX_PLAYERS = 2;
    uint8 private constant TOTAL_CARDS = 52;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyState(uint256 gameId, GameStatus state) {
        Game storage game = games[gameId];
        require(game.status == state, "Invalid state");
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
        newGame.smallBlindAmount = smallBlind;
        newGame.bigBlindAmount = smallBlind * 2;
        newGame.bigBlindPlayer = (bigBlindPlayerId++) % MAX_PLAYERS;
        newGame.smallBlindPlayer = (1 + bigBlindPlayerId++) % MAX_PLAYERS;
        newGame.minBuyIn = minBuyIn;
        newGame.maxBuyIn = maxBuyIn;
        newGame.status = GameStatus.Create;
        for (uint256 i = 0; i < 52; i++) {
            newGame.deck.push(i);
        }

        _joinGame(gameId, playerHash);
        return gameId;
    }

    function joinGame(uint256 gameId, bytes32 playerHash) public payable {
        _joinGame(gameId, playerHash);
    }

    function _joinGame(uint256 gameId, bytes32 playerHash) internal onlyState(gameId, GameStatus.Create) {
        Game storage game = games[gameId];
        // require(game.status == GameStatus.Create, "Game not in correct state");
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
            _transfer(owner, commission); // pay commission to us
        }
    }

    function _transfer(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert("Transfer error");
        }
    }

    function drawCard(uint256 gameId, uint256 seed) internal returns (uint256) {
        Game storage game = games[gameId];
        require(game.deck.length > 0, "No more cards in the deck");
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty))) % game.deck.length;
        uint256 card = game.deck[randomIndex];
        game.deck[randomIndex] = game.deck[game.deck.length - 1];
        game.deck.pop();

        return card;
    }

    function startGame(uint8 gameId, uint256 seed) public onlyOwner onlyState(gameId, GameStatus.AwaitingToStart) {
        Game storage game = games[gameId];
        // require(game.status == GameStatus.AwaitingToStart, "Game not in correct state");

        game.status = GameStatus.PreFlop;
        // deal the card
        for (uint i = 0; i < games[gameId].players.length; i++) {
            address playerId = games[gameId].players[i];
            for (uint j = 0; j < 2; j++) {
                uint256 card = drawCard(gameId, seed);
                game.playerCards[playerId].push(card);
            }
        }
        // Big blind and Small blind initial bet
        address bigBlindPlayer = game.players[game.bigBlindPlayer];
        address smallBlindPlayer = game.players[game.smallBlindPlayer];
        require(game.playerChips[bigBlindPlayer] >= game.bigBlindAmount, "Insufficient balance");
        require(game.playerChips[smallBlindPlayer] >= game.smallBlindAmount, "Insufficient balance");
        game.playerChips[bigBlindPlayer] -= game.bigBlindAmount;
        game.playerChips[smallBlindPlayer] -= game.smallBlindAmount;
        game.pot += game.bigBlindAmount + game.smallBlindAmount;
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