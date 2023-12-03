// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './game-logic/utils.sol';

//0x8b0c5278f646fa6bd2de166a73cc5a5bcf242ceb0bab6cad60e4500f052c20aa
//0x8b0c5278f646fa6bd2de166a73cc5a5bcf242ceb0bab6cad60e4500f052c20ab
//0x8b0c5278f646fa6bd2de166a73cc5a5bcf242ceb0bab6cad60e4500f052c20ac
contract PokerChain {
    uint8 private constant MAX_PLAYERS = 3;
    struct Game {
        address owner;
        address[] players;
        mapping(address => bytes32) playerStates;
        mapping(address => uint256) playerChips;
        mapping(address => uint8[]) playerCards;
        mapping(address => uint8) cardMasks;
        PlayerAction[] playerActions;
        uint8[] isPlayerInGame;
        uint8[] isPlayerAllIn;
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

    enum PlayerAction { Call, Raise, Check, Fold, Idle, AllIn }

    address private owner;
    uint256 private commission; // pay to our system
    uint8 private nextGameId; 
    uint8 private bigBlindPlayerId; 
    uint8 private numGames; 
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
        bigBlindPlayerId = 0;
        newGame.smallBlindPlayer = 0;
        newGame.bigBlindPlayer = 1;
        newGame.minBuyIn = minBuyIn;
        newGame.maxBuyIn = maxBuyIn;
        newGame.currentPlayerIndex = 0;
        // newGame.verifiedPlayerCount = 0;
        // newGame.numPlayerInGame = 0;
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
    function joinGame(uint256 gameId, bytes32 playerHash) public payable onlyState(gameId, GameStatus.Create) validGameId(gameId) {
        _joinGame(gameId, playerHash);
    }

    function _joinGame(uint256 gameId, bytes32 playerHash) internal {
        Game storage game = games[gameId];
        require(msg.value >= commission + game.minBuyIn && msg.value <= commission + game.maxBuyIn, "Deposit amount must not less than minBuyIn and not more than MaxBuyIn");
        require(game.players.length < MAX_PLAYERS, "Game is full");
        require(msg.sender != address(0x0) && msg.sender != address(this), "Invalid player address");

        game.players.push(msg.sender);
        game.playerStates[msg.sender] = playerHash;
        game.playerChips[msg.sender] = msg.value - commission;
        game.cardMasks[msg.sender] = 0;
        game.isPlayerInGame.push(1);
        game.numPlayerInGame += 1;
        game.verifiedPlayerCount += 1;
        game.playerBetAmounts.push(0);
        game.playerActions.push(PlayerAction.Idle);

        if (game.players.length == MAX_PLAYERS) {
            // game.verifiedPlayerCount = 0;
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
    function startGame(uint8 gameId, uint256 seed) public onlyState(gameId, GameStatus.AwaitingToStart) validGameId(gameId) {
        Game storage game = games[gameId];
        // require(game.status == GameStatus.AwaitingToStart, "Game not in correct state");
        require(game.players.length == MAX_PLAYERS, "Table does not full yet");

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
        game.pot += game.bigBlindAmount * 2;
        game.playerChips[bigBlindPlayer] -= game.bigBlindAmount;
        game.playerChips[smallBlindPlayer] -= game.bigBlindAmount;

        game.currentBet = game.bigBlindAmount;
        game.currentPlayerIndex = game.bigBlindPlayer + 1;
        game.playerBetAmounts[game.bigBlindPlayer] = game.bigBlindAmount;
        game.playerActions[game.bigBlindPlayer] = PlayerAction.Raise;
        game.playerBetAmounts[game.smallBlindPlayer] = game.bigBlindAmount;
        game.playerActions[game.smallBlindPlayer] = PlayerAction.Raise;
    }

    function _min(uint256 a, uint256 b) internal returns (uint256) {
        return a <= b ? a : b;
    }

    /*
        Function to Call in the Round
        @param : gameId, player action, raise amount
    */
    function callAction(uint8 gameId) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid call action");
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1){
            _nextPlayer(game);
            return;
        }
        address player = game.players[game.currentPlayerIndex];

        game.playerActions[game.currentPlayerIndex] = PlayerAction.Call;
        uint256 callAmount = _min(game.currentBet - game.playerBetAmounts[game.currentPlayerIndex], game.playerChips[player]);
        game.pot += callAmount ;
        game.playerChips[player] -= callAmount;
        game.playerBetAmounts[game.currentPlayerIndex] = _min(game.currentBet, game.playerBetAmounts[game.currentPlayerIndex] + callAmount);
        if (game.playerChips[player] == 0){
            game.isPlayerAllIn[game.currentPlayerIndex] = 1;
            game.playerActions[game.currentPlayerIndex] = PlayerAction.AllIn;
        }
        _nextPlayer(game);
        
    }

    /*
        Function to Raise in the Round
        @param : gameId, player action, raise amount
    */
    function raiseAction(uint8 gameId, uint256 raiseAmount) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid raise action");
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1){
            _nextPlayer(game);
            return;
        }
        address player = game.players[game.currentPlayerIndex];

        require(raiseAmount > game.currentBet, "Raise amount must be greater than current bet");
        require(game.playerChips[player] >= raiseAmount, "Insufficient balance");

        game.playerActions[game.currentPlayerIndex] = PlayerAction.Raise;
        game.currentBet = raiseAmount;
        game.pot += raiseAmount;
        game.playerBetAmounts[game.currentPlayerIndex] = raiseAmount;
        game.playerChips[player] -= raiseAmount;
        if (game.playerChips[player] == 0){
            game.isPlayerAllIn[game.currentPlayerIndex] = 1;
            game.playerActions[game.currentPlayerIndex] = PlayerAction.AllIn;
        }
        _nextPlayer(game);
    }

    /*
        Function to Check in the Round
        @param : gameId, player action, raise amount
    */
    function checkAction(uint8 gameId) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid check action");
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1){
            _nextPlayer(game);
            return;
        }
        require(game.playerBetAmounts[game.currentPlayerIndex] == game.currentBet, "Cannot check, must match current bet");
        game.playerActions[game.currentPlayerIndex] = PlayerAction.Check;
        _nextPlayer(game);
    }

    /*
        Function to Fold in the Round
        @param : gameId, player action, raise amount
    */
    function foldAction(uint8 gameId) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid fold action");
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1){
            _nextPlayer(game);
            return;
        }
        game.playerActions[game.currentPlayerIndex] = PlayerAction.Fold;
        _nextPlayer(game);
    }

    function _isValidAction(Game storage game) internal view returns (bool) {
        return (game.status == GameStatus.PreFlop || game.status == GameStatus.Flop || game.status == GameStatus.Turn || game.status == GameStatus.River) &&
            (game.playerActions[game.currentPlayerIndex] != PlayerAction.Fold) &&
            (msg.sender == game.players[game.currentPlayerIndex]) &&
            (game.isPlayerInGame[game.currentPlayerIndex] != 0);
    }

    function getIsValidAction(uint8 gameId) public view returns (
        bool validState,
        bool validAction,
        bool validPlayer,
        bool validActivePlayer
    ) {
        Game storage game = games[gameId];
        return (game.status == GameStatus.PreFlop || game.status == GameStatus.Flop || game.status == GameStatus.Turn || game.status == GameStatus.River ,
            game.playerActions[game.currentPlayerIndex] != PlayerAction.Fold,
            msg.sender == game.players[game.currentPlayerIndex],
            game.isPlayerInGame[game.currentPlayerIndex] != 0);
    }

    function _nextPlayer(Game storage game) internal {
        if (game.playerActions[(game.currentPlayerIndex + 1) % MAX_PLAYERS] == PlayerAction.Fold) {
            game.currentPlayerIndex = (game.currentPlayerIndex + 2) % MAX_PLAYERS;
        } else{
            game.currentPlayerIndex = (game.currentPlayerIndex + 1) % MAX_PLAYERS;
        }
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
        game.currentBet = 0;
        for (uint i = 0; i < MAX_PLAYERS;++i){
            game.playerActions[i] = PlayerAction.Idle;
        }
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
        game.currentBet = 0;
        for (uint i = 0; i < MAX_PLAYERS;++i){
            game.playerActions[i] = PlayerAction.Idle;
        }
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
        game.currentBet = 0;
        for (uint i = 0; i < MAX_PLAYERS;++i){
            game.playerActions[i] = PlayerAction.Idle;
        }
        return (game.communityCards[0], game.communityCards[1], game.communityCards[2], game.communityCards[3], game.communityCards[4]);
    }

    /*
        Function to reward
        @param : gameId
    */
    function showdown(uint8 gameId) public view onlyState(gameId, GameStatus.River) returns(uint8[][] memory, uint8[] memory, uint8[] memory) {
        Game storage game = games[gameId];
        
        (uint40[] bestHands, uint8[] winnerIndices) = PokerUtils.checkWinningHands(game.playerCards, game.communityCards);
        uint256 rewards = game.pot / winnerIndices.length;
        for (uint i=0; i<winnerIndices.length; i++) {
            game.playerChips[game.players[i]] += rewards;
        }

        uint8[][] bestHandsDecoded = new uint8[][](bestHands.length);
        uint8[] bestHandsCombination = new uint8[](bestHands.length);
        for (uint i=0; i<bestHands.length; i++) {
            bestHandsDecoded[i] = PokerUtils.decodeHand(bestHands[i]);
            bestHandsCombination[i] = PokerUtils.getScore(bestHands[i]);
        }
        game.status = GameStatus.Finish;
        
        return (bestHandsDecoded, bestHandsCombination, winnerIndices);
    }

    /*
        Function to reset game
        @param : gameId
    */
    function clear(uint8 gameId) public payable onlyState(gameId, GameStatus.Finish) {
        Game storage game = games[gameId];
        for (uint i=0; i < MAX_PLAYERS; i++) {
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
            return;
        }
        _resetRound(gameId);
    }

    /*
        Function to reset round
        @param : gameId
    */
    function _resetRound(uint8 gameId) internal {
        Game storage game = games[gameId];
        bigBlindPlayerId = 0;
        game.bigBlindPlayer = 0;
        game.smallBlindPlayer = 0;
        game.pot = 0;
        game.currentBet = 0;
        game.currentPlayerIndex = 0;
        game.status = GameStatus.AwaitingToStart;
        game.playerActions = new PlayerAction[](0);
        game.playerBetAmounts = new uint256[](0);
        game.ranks = new uint8[](0);
        game.communityCards = new uint8[](0);
        _resetPlayerCards(gameId);
    }

    function _resetGame(uint8 gameId) internal {
        // Game storage game = games[gameId];
        delete games[gameId];
        bigBlindPlayerId = 0;
        // Remove gameId from gameIds array
        // for (uint i = 0; i < game.length; i++) {
        //     if (game[i] == gameId) {
        //         game[i] = game[game.length - 1];
        //         game.pop();
        //         break;
        //     }
        // }
    }

    function _resetPlayerCards(uint8 gameId) internal {
        Game storage game = games[gameId];
        for (uint i = 0; i < game.players.length; i++) {
            game.playerCards[game.players[i]] = new uint8[](0);
        }
    }

    function getGameBasicDetails(uint256 gameId) public view returns (
        address oowner,
        uint256 pot,
        uint256 matchStartTime,
        GameStatus status,
        uint256 verifiedPlayerCount,
        uint8[] memory
    ) {
        Game storage game = games[gameId];
        return (game.owner, game.pot, game.matchStartTime, game.status, game.verifiedPlayerCount, game.isPlayerInGame);
    }

    function getHand(uint256 gameId) public view onlyState(gameId, GameStatus.PreFlop) returns (
        uint8 firstCard,
        uint8 secondCard
    ) {
        Game storage game = games[gameId];
        return (game.playerCards[msg.sender][0], game.playerCards[msg.sender][1]);
    }

    function getPlayers(uint256 gameId) public view returns (address[] memory) {
        return games[gameId].players;
    }
    
    function getNumGames() public view returns (uint8 numGames) {
        return games.length;
    }

    function getRoundDetails(uint256 gameId) public view returns (
        uint256[] memory,
        PlayerAction[] memory,
        uint256 pot,
        uint256 currentBet,
        uint8 currentPlayerIndex
    ) {
        Game storage game = games[gameId];
        return (game.playerBetAmounts, game.playerActions, game.pot, game.currentBet, game.currentPlayerIndex);
    }

    function getShowdown(uint256 gameId) public view returns (
        uint256[] memory,
        PlayerAction[] memory,
        uint256 pot,
        uint256 currentBet,
        uint8 currentPlayerIndex
    ) {
        Game storage game = games[gameId];
        return (game.playerBetAmounts, game.playerActions, game.pot, game.currentBet, game.currentPlayerIndex);
    }
}