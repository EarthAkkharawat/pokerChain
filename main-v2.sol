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
        PlayerAction[] playerActions;
        uint256[] playerBetAmounts;
        uint256[] ranks;
        uint256[] deck;
        uint256[] communityCards;
        uint256 pot;
        uint256 randomSeed;
        uint256 matchStartTime;
        uint256 smallBlindAmount;
        uint256 bigBlindAmount;
        uint256 smallBlindPlayer;
        uint256 bigBlindPlayer;
        uint256 minBuyIn;
        uint256 maxBuyIn;
        uint256 currentBet;
        uint256 currentPlayerIndex;
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

    enum PlayerAction { Raise, Check, Fold }

    address private owner;
    uint256 private commission; // pay to our system
    uint256 private nextGameId; 
    uint256 private bigBlindPlayerId; 
    uint256 private numGames; 
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

    modifier validGameId(uint256 gameId) {
        Game storage game = games[gameId];
        require(gameId <= numGames, "gameId does not exists");
        _;
    }

    mapping(uint256 => Game) private games;  

    constructor(uint256 _commission) {
        owner = msg.sender;
        commission = _commission;
    }

    /*
        Function to create new game
        @param : smallBlind, minBuyIn, maxBuyIn, playerHash
    */
    function createGame(uint256 smallBlind, uint256 minBuyIn, uint256 maxBuyIn, bytes32 playerHash) public payable returns (uint256) {
        
        require(minBuyIn <= maxBuyIn, "Minimum buy in must not exceed maximum buy in");

        uint256 gameId = nextGameId++;
        numGames = gameId;
        Game storage newGame = games[gameId];
        newGame.owner = msg.sender;
        newGame.smallBlindAmount = smallBlind;
        newGame.bigBlindAmount = smallBlind * 2;
        newGame.bigBlindPlayer = (bigBlindPlayerId++) % MAX_PLAYERS;
        newGame.smallBlindPlayer = (1 + bigBlindPlayerId++) % MAX_PLAYERS;
        newGame.minBuyIn = minBuyIn;
        newGame.maxBuyIn = maxBuyIn;
        newGame.verifiedPlayerCount = 1;
        newGame.status = GameStatus.Create;
        for (uint256 i = 0; i < 52; i++) {
            newGame.deck.push(i);
        }

        _joinGame(gameId, playerHash);
        return gameId;
    }

    /*
        Function to join existing game
        @param : gameId, player hash
    */
    function joinGame(uint256 gameId, bytes32 playerHash) public payable {
        _joinGame(gameId, playerHash);
    }

    function _joinGame(uint256 gameId, bytes32 playerHash) internal onlyState(gameId, GameStatus.Create) validGameId(gameId) {
        Game storage game = games[gameId];
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

    /*
        Function to transfer assets
        @param : receiver address, amount
    */
    function _transfer(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert("Transfer error");
        }
    }

    /*
        Function to draw card
        @param : gameId, seed
    */
    function drawCard(uint256 gameId, uint256 seed) internal validGameId(gameId) returns (uint256) {
        Game storage game = games[gameId];
        require(game.deck.length > 0, "No more cards in the deck");
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty))) % game.deck.length;
        uint256 card = game.deck[randomIndex];
        game.deck[randomIndex] = game.deck[game.deck.length - 1];
        game.deck.pop();

        return card;
    }

    /*
        Function to start game and enter the preflop state
        @param : gameId, seed
    */
    function startGame(uint8 gameId, uint256 seed) public onlyOwner onlyState(gameId, GameStatus.AwaitingToStart) validGameId(gameId) {
        Game storage game = games[gameId];
        // require(game.status == GameStatus.AwaitingToStart, "Game not in correct state");
        require(game.players.length == MAX_PLAYERS, "Game not in correct state");

        game.status = GameStatus.PreFlop;
        // deal the card
        for (uint i = 0; i < games[gameId].players.length; i++) {
            address playerId = games[gameId].players[i];
            for (uint j = 0; j < 2; j++) {
                uint256 card = drawCard(gameId, seed);
                game.playerCards[playerId].push(card);
            }
        }
        for (uint i = 0; i < 5; i++) {
            uint256 card = drawCard(gameId, seed);
            game.communityCards.push(card);
        }

        // Big blind and Small blind initial bet
        address bigBlindPlayer = game.players[game.bigBlindPlayer];
        address smallBlindPlayer = game.players[game.smallBlindPlayer];
        require(game.playerChips[bigBlindPlayer] >= game.bigBlindAmount, "Insufficient balance");
        require(game.playerChips[smallBlindPlayer] >= game.smallBlindAmount, "Insufficient balance");
        game.pot += game.bigBlindAmount + game.smallBlindAmount;
        game.playerChips[bigBlindPlayer] -= game.bigBlindAmount;
        game.playerChips[smallBlindPlayer] -= game.smallBlindAmount;

        game.currentPlayerIndex = game.smallBlindPlayer + 1;
    }

    /*
        Function to betting in the Round
        @param : gameId, player action, raise amount
    */
    function bettingRound(uint8 gameId, PlayerAction action, uint256 raiseAmount) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(game.status == GameStatus.PreFlop || game.status == GameStatus.Flop || game.status == GameStatus.Turn || game.status == GameStatus.River, "Invalid state");
        require(game.playerActions[game.currentPlayerIndex] != PlayerAction.Fold, "Player has already folded");
        require(msg.sender == game.players[game.currentPlayerIndex], "Not your turn");

        if (action == PlayerAction.Raise) {
            require(raiseAmount > game.currentBet, "Raise amount must be greater than current bet");
            address player = game.players[game.currentPlayerIndex];
            require(game.playerChips[player] >= raiseAmount, "Insufficient balance");
            game.currentBet = raiseAmount;
            game.pot += raiseAmount;
            game.playerBetAmounts[game.currentPlayerIndex] += raiseAmount;
            game.playerChips[player] -= raiseAmount;
        } else if (action == PlayerAction.Check) {
            require(game.playerBetAmounts[game.currentPlayerIndex] == game.currentBet, "Cannot check, must match current bet");
        } else if (action == PlayerAction.Fold) {
            game.playerActions[game.currentPlayerIndex] = PlayerAction.Fold;
        }

        game.currentPlayerIndex = (game.currentPlayerIndex + 1) % MAX_PLAYERS;
    }

    /*
        Function to reveal 3 community cards
        @param : gameId
    */
    function flop(uint8 gameId) public onlyState(gameId, GameStatus.PreFlop) returns (
        uint256 firstCard,
        uint256 secondCard,
        uint256 thirdCard
    ){
        Game storage game = games[gameId];
        game.status = GameStatus.Flop;
        game.currentPlayerIndex = 0;
        return (game.communityCards[0], game.communityCards[1], game.communityCards[2]);
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