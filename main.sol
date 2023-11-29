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
        uint256 pot;
        uint256 randomSeed;
        uint256 matchStartTime;
        uint256 smallBlind;
        uint256 bettingLimit;
        uint256 lastBet;
        uint8 currentPlayerIndex;
        uint8 verifiedPlayerCount;
        uint8 gameCount;
        GameStatus status;
    }

    enum GameStatus {
        Created,
        AwaitingVerificationStart,
        AwaitingVerificationChange,
        MatchInProgress,
        Reveal,
        Clear,
        Finished,
        FirstTurn,
        SecondTurn,
        WaitingStateAfterStart,
        WaitingStateAfterChange
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
        StraightFlush
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

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function createGame(uint256 smallBlind, uint256 limit, bytes32 playerStateHash) public payable returns (uint256) {
        require(2 * smallBlind <= limit, "Limit must be at least twice the small blind");
        require(msg.value == commission + 3 * smallBlind, "Incorrect deposit amount");

        uint256 gameId = nextGameId++;
        Game storage newGame = games[gameId];
        newGame.owner = msg.sender;
        newGame.smallBlind = smallBlind;
        newGame.bettingLimit = limit;
        newGame.status = GameStatus.WaitingStateAfterStart;
        
        _joinGame(gameId, playerStateHash);
        return gameId;
    }
    
    function joinGame(uint256 gameId, bytes32 playerStateHash) public payable {
        _joinGame(gameId, playerStateHash);
    }

    function supplyRandomStateHash(uint256 gameId, bytes32 randomStateHash, uint8 playerId, uint8 cardMask) public {
        Game storage game = games[gameId];
        require(game.status == GameStatus.WaitingStateAfterChange || game.status == GameStatus.WaitingStateAfterStart, "Invalid state for supplying hash");
        require(game.players[playerId] == msg.sender, "Only the player can supply their state hash");
        require(game.players.length == MAX_PLAYERS, "Incomplete player registration");

        game.playerStates[msg.sender] = randomStateHash;
        game.cardMasks[msg.sender] = cardMask;
        game.verifiedPlayerCount++;

        if (game.verifiedPlayerCount == MAX_PLAYERS) {
            game.verifiedPlayerCount = 0;
            game.status = game.status == GameStatus.WaitingStateAfterStart ? GameStatus.AwaitingVerificationStart : GameStatus.AwaitingVerificationChange;
        }
    }

    function verifyPlayerState(uint256 gameId, uint256 randomState, uint8 playerId) public {
        Game storage game = games[gameId];
        require(game.status == GameStatus.AwaitingVerificationStart || game.status == GameStatus.AwaitingVerificationChange, "Not in verification stage");
        require(playerId < MAX_PLAYERS, "Invalid player ID");
        require(game.players[playerId] == msg.sender, "Only the player can verify their state");
        require(game.playerStates[msg.sender] == keccak256(abi.encodePacked(randomState)), "Incorrect state hash");

        game.randomSeed += randomState;
        game.verifiedPlayerCount++;

        if (game.verifiedPlayerCount == MAX_PLAYERS) {
            game.currentPlayerIndex = 0;
            game.status = GameStatus.Reveal; // Placeholder for actual game logic
        }
    }

    function makeBet(uint256 gameId, uint256 betAmount) public payable {
        Game storage game = games[gameId];
        require(game.status == GameStatus.FirstTurn || game.status == GameStatus.SecondTurn, "Not in betting stage");
        require(msg.value == betAmount, "Bet amount does not match sent value");
        require(betAmount >= game.lastBet && betAmount <= game.bettingLimit, "Bet amount not within limits");

        game.pot += betAmount;
        game.lastBet = betAmount;
        game.currentPlayerIndex = (game.currentPlayerIndex + 1) % MAX_PLAYERS;

        // Update game status based on the current phase of the game
        if (game.currentPlayerIndex == 0) {
            if (game.status == GameStatus.FirstTurn) {
                game.status = GameStatus.WaitingStateAfterChange;
            } else if (game.status == GameStatus.SecondTurn) {
                game.status = GameStatus.Reveal;
            }
        }
    }

    function revealCards(uint256 gameId, bytes memory signature, uint256 claimedHand, uint8 claimedCombination, uint8 playerId) public {
        Game storage game = games[gameId];
        require(game.status == GameStatus.Reveal, "Not in reveal stage");
        require(game.currentPlayerIndex == playerId, "Not the current player's turn");
        require(game.players[playerId] == msg.sender, "Only the player can reveal their cards");

        bytes32 message = prefixed(keccak256(abi.encodePacked(game.randomSeed + playerId)));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        require(ecrecover(message, v, r, s) == msg.sender, "Invalid signature");

        uint8[5] memory cardIds = parseCards(v, r, s);
        require(PokerUtils.checkClaimedHand(claimedHand, cardIds), "Invalid claimed hand");
        require(PokerUtils.checkClaimedCombination(claimedHand, claimedCombination), "Invalid claimed combination");
        game.ranks[playerId] = PokerUtils.calcHandRank(claimedHand, claimedCombination);
        game.verifiedPlayerCount++;

        if (game.verifiedPlayerCount == MAX_PLAYERS) {
            game.status = GameStatus.Clear;
        }
    }

    function requestBank(uint256 gameId) public {
        Game storage game = games[gameId];
        require(game.status == GameStatus.Clear, "Not in bank request stage");
        
        uint256 maxRank = 0;
        address winner;

        for (uint8 i = 0;i < game.players.length; i++) {
            address player = game.players[i];
            if (game.ranks[i] > maxRank) {
                maxRank = game.ranks[i];
                winner = player;
            }
        }

        payable(winner).transfer(game.pot);
        game.status = GameStatus.Finished;
    }

    function _joinGame(uint256 gameId, bytes32 playerStateHash) internal {
        Game storage game = games[gameId];
        require(game.status == GameStatus.WaitingStateAfterStart, "Game not in correct state");
        require(msg.value == commission + 3 * game.smallBlind, "Incorrect deposit amount");
        require(game.players.length < MAX_PLAYERS, "Game is full");

        game.players.push(msg.sender);
        game.playerStates[msg.sender] = playerStateHash;
        game.cardMasks[msg.sender] = 0;
        game.verifiedPlayerCount++;

        if (game.verifiedPlayerCount == MAX_PLAYERS) {
            game.verifiedPlayerCount = 0;
            game.status = GameStatus.AwaitingVerificationStart;
            payable(owner).transfer(MAX_PLAYERS * commission);
        }
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function parseCards(uint8 v, bytes32 r, bytes32 s) internal pure returns (uint8[5] memory cardIds) {
        uint256 seed = 3 * uint256(s) + 5 * uint256(r) + 7 * v;
        for (uint8 i = 0; i < 5; i++) {
            cardIds[i] = uint8(seed % TOTAL_CARDS);
            seed = 31 * seed + 13;
        }
        return cardIds;
    }

}
