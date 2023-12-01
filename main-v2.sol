// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './game-logic/utils.sol';

contract PokerChain {
    struct Game {
        address owner;
        address[] players;
        mapping(address => bytes32) playerStates;
        mapping(address => uint256) playerChips;
        mapping(address => uint8[]) playerCards;
        mapping(address => uint8) cardMasks;
        PlayerAction[] playerActions;
        uint8[] isPlayerInGame;
        uint256[] playerBetAmounts;
        uint256[] ranks;
        uint8[] deck;
        uint8[] communityCards;
        uint256 pot;
        uint8 numPlayerInGame;
        uint256 randomSeed;
        uint256 matchStartTime;
        uint256 smallBlindAmount;
        uint256 bigBlindAmount;
        uint8 smallBlindPlayer;
        uint8 bigBlindPlayer;
        uint256 minBuyIn;
        uint256 maxBuyIn;
        uint256 currentBet;
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

    uint8 private constant HIGH_CARD = 0;
	uint8 private constant ONE_PAIR = 1;
	uint8 private constant TWO_PAIR = 2;
	uint8 private constant THREE_OF_A_KIND = 3;
	uint8 private constant STRAIGHT = 4;
	uint8 private constant FLUSH = 5;
	uint8 private constant FULL_HOUSE = 6;
	uint8 private constant FOUR_OF_A_KIND = 7;
	uint8 private constant STRAIGHT_FLUSH = 8;
	uint8 private constant ROYAL_STRAIGHT_FLUSH = 9;

    enum PlayerAction { Call, Raise, Check, Fold }

    address private owner;
    uint256 private commission; // pay to our system
    uint8 private nextGameId; 
    uint8 private bigBlindPlayerId; 
    uint8 private numGames; 
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

        uint8 gameId = nextGameId++;
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
        newGame.isPlayerInGame.push(1);
        newGame.numPlayerInGame = 1;
        newGame.status = GameStatus.Create;
        for (uint8 i = 0; i < 52; i++) {
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
        require(msg.sender != address(0x0) && msg.sender != address(this), "Invalid player address");

        game.players.push(msg.sender);
        game.playerStates[msg.sender] = playerHash;
        game.playerChips[msg.sender] = msg.value - commission;
        game.cardMasks[msg.sender] = 0;
        game.isPlayerInGame.push(1);
        game.numPlayerInGame++;
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
    function drawCard(uint256 gameId, uint256 seed) internal validGameId(gameId) returns (uint8) {
        Game storage game = games[gameId];
        require(game.deck.length > 0, "No more cards in the deck");
        uint8 randomIndex = uint8(uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty))) % game.deck.length);
        uint8 card = game.deck[randomIndex];
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
        for (uint i = 0; i < game.players.length; i++) {
            address playerAddress = game.players[i];
            if (game.isPlayerInGame[i] == 0){
                continue;
            }
            for (uint j = 0; j < 2; j++) {
                uint8 card = drawCard(gameId, seed);
                game.playerCards[playerAddress].push(card);
            }
        }
        for (uint i = 0; i < 5; i++) {
            uint8 card = drawCard(gameId, seed);
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
        require(game.isPlayerInGame[game.currentPlayerIndex] != 0, "You have already been eliminated");

        if (action == PlayerAction.Call) {
            require(game.playerBetAmounts[game.currentPlayerIndex] < game.currentBet, "Raise amount must be greater than current bet");
            address player = game.players[game.currentPlayerIndex];
            game.pot += game.currentBet;
            game.playerBetAmounts[game.currentPlayerIndex] += game.currentBet;
            game.playerChips[player] -= game.currentBet;
        } else if (action == PlayerAction.Raise) {
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

    /*
        Function to reveal 4 community cards
        @param : gameId
    */
    function turn(uint8 gameId) public onlyState(gameId, GameStatus.Flop) returns (
        uint256 firstCard,
        uint256 secondCard,
        uint256 thirdCard,
        uint256 fourthCard
    ){
        Game storage game = games[gameId];
        game.status = GameStatus.Turn;
        game.currentPlayerIndex = 0;
        return (game.communityCards[0], game.communityCards[1], game.communityCards[2], game.communityCards[3]);
    }

    /*
        Function to reveal 5 community cards
        @param : gameId
    */
    function River(uint8 gameId) public onlyState(gameId, GameStatus.Turn) returns (
        uint256 firstCard,
        uint256 secondCard,
        uint256 thirdCard,
        uint256 fourthCard,
        uint256 FifthCard
    ){
        Game storage game = games[gameId];
        game.status = GameStatus.Turn;
        game.currentPlayerIndex = 0;
        return (game.communityCards[0], game.communityCards[1], game.communityCards[2], game.communityCards[3], game.communityCards[4]);
    }

    /*
        Function to reward and reset game
        @param : gameId
    */
    function showdown(uint8 gameId) public payable onlyState(gameId, GameStatus.River) {
        Game storage game = games[gameId];
        uint256 maxRank = 0;
        uint256 winner = 0;
        for (uint i=0; i<MAX_PLAYERS; i++){
            address player = game.players[i];
            // TODO
            game.ranks[i] = PokerUtils.checkCardsCombination(game.playerCards[player], game.communityCards);
            if (game.ranks[i] > maxRank){
                maxRank = game.ranks[i];
                winner = i;
            }
        }
        
        game.playerChips[game.players[winner]] += game.pot;

        for (uint i=0; i < MAX_PLAYERS; i++){
            if (game.playerChips[game.players[i]] == 0) {
                game.isPlayerInGame[i] == 0;
                game.numPlayerInGame--;
            }
        }

        if (game.numPlayerInGame == 1) {
            uint256 winner_idx = 0;
            for (uint i = 0; i < game.isPlayerInGame.length; i++) {
                if (game.isPlayerInGame[i] == 1) {
                    winner_idx = int(i);
                }
            }
            _transfer(game.players[winner_idx], game.playerChips[game.players[winner_idx]]);
            _resetGame(gameId);
        }

        _resetRound(gameId);

    }

    function _resetRound(uint8 gameId) internal {
        Game storage game = games[gameId];
        bigBlindPlayerId = 0;
        game.bigBlindPlayer = 0;
        game.smallBlindPlayer = 0;
        game.pot = 0;
        game.currentBet = 0;
        game.currentPlayerIndex = 0;
        game.status = GameStatus.AwaitingToStart;
        game.playerActions.length = 0;
        game.playerBetAmounts.length = 0;
        game.ranks.length = 0;
        game.communityCards.length = 0;
        _resetPlayerCards(gameId);
    }

    function _resetGame(uint8 gameId) internal {
        Game storage game = games[gameId];
        delete game[gameId];
        bigBlindPlayerId = 0;
        // Remove gameId from gameIds array
        for (uint i = 0; i < game.length; i++) {
            if (game[i] == gameId) {
                game[i] = game[game.length - 1];
                game.pop();
                break;
            }
        }
    }

    function _resetPlayerCards(uint8 gameId) internal {
        Game storage game = games[gameId];
        for (uint i = 0; i < game.players.length; i++) {
            game.playerCards[game.players[i]].length = 0;
        }
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