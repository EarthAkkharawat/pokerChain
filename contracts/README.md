# PokerChain Contract Documentation

## Contract Overview
`PokerChain` is a Solidity smart contract designed for running a decentralized Texas Hold'em poker game on the Ethereum blockchain. It features functionalities for game creation, player actions during the game, and managing poker rounds.

## Contract Fields
1. `MAX_PLAYERS`: The maximum number of players allowed in a game.
2. `Game`: Struct that represents a game, containing information about players, cards, bets, game status, etc.
3. `GameStatus`: Enum representing different states of a game.
4. `PlayerAction`: Enum representing different actions a player can take during a game.
5. `owner`: Address of the contract owner.
6. `commission`: Commission paid to the system.
7. `nextGameId`: ID for the next game.
8. `bigBlindPlayerId`: ID of the player who is the big blind.
9. `numGames`: Number of games created.
10. `TOTAL_CARDS`: Total number of cards in a deck.
11. `games`: Mapping from game IDs to games.

## Enum

### GameStatus
- `Create`: The initial state of the game when it is created.
- `AwaitingToStart`: The game is waiting for enough players to join.
- `PreFlop`: The stage where players receive their initial two cards.
- `Flop`: The stage where the first three community cards are revealed.
- `Turn`: The stage where the fourth community card is revealed.
- `River`: The stage where the fifth and final community card is revealed.
- `Finish`: The game is finished, and the winner is determined.
- `Clear`: The game is cleared and ready for a new round or game.

### PlayerAction
- `Call`: A player action to match the current highest bet.
- `Raise`: A player action to increase the current highest bet.
- `Check`: A player action to pass the turn without betting, only available if no bet has been made in the current round.
- `Fold`: A player action to give up on the current hand and forfeit any bets already made.
- `Idle`: A default state indicating the player has not taken any action yet.
- `AllIn`: A player action to bet all remaining chips.

## Structs

### Game
- `owner`: Address of the game creator.
- `players`: Dynamic array of player addresses participating in the game.
- `playerChips`: Mapping from player address to their chip count.
- `playerCards`: Mapping from player address to an array of their cards.
- `playerActions`: Dynamic array of actions taken by each player.
- `isPlayerInGame`: Dynamic array indicating whether a player is still active in the game.
- `isPlayerAllIn`: Dynamic array indicating whether a player has gone all-in.
- `playerBetAmounts`: Dynamic array of the amount each player has bet in the current round.
- `deck`: Dynamic array representing the deck of cards.
- `communityCards`: Dynamic array of cards that are in play for all players.
- `pot`: Total amount of chips bet in the current round.
- `numPlayerInGame`: Count of active players in the game.
- `smallBlindAmount`: Amount of the small blind bet.
- `bigBlindAmount`: Amount of the big blind bet.
- `smallBlindPlayer`: Index of the player assigned as the small blind.
- `bigBlindPlayer`: Index of the player assigned as the big blind.
- `minBuyIn`: Minimum amount required to join the game.
- `maxBuyIn`: Maximum amount allowed to join the game.
- `currentBet`: The current highest bet that players must match or exceed.
- `currentPlayerIndex`: Index of the current player to take action.
- `verifiedPlayerCount`: Count of players who have verified their participation.
- `gameCount`: The number of games played.
- `status`: Current status of the game, as defined in `GameStatus`.

## Modifiers
1. `onlyOwner`: Ensures that only the contract owner can call a function.
2. `onlyState`: Ensures that a function is called only when the game is in a specific state.
3. `validGameId`: Ensures that the provided game ID is valid.

## Functions

### Constructor
- **Parameters**: 
  - `_commission` (`uint256`): The commission amount for the contract (All players need to pay when join game).
- **Functionality**: Sets the contract owner and commission amount.

### createGame
- **Modifiers**: require(minBuyIn <= maxBuyIn);
- **Parameters**: 
  - `smallBlind` (`uint256`): The amount of the small blind.
  - `minBuyIn` (`uint256`): Minimum buy-in amount.
  - `maxBuyIn` (`uint256`): Maximum buy-in amount.
- **Returns**: `uint256` - The ID of the created game.
- **Functionality**: Creates a new game with specified parameters.

### joinGame
- **Modifiers**: 
  - `onlyState`: Requires the game to be in the `Create` state.
  - `validGameId`: Validates the game ID.
- **Parameters**: 
  - `gameId` (`uint256`): The ID of the game to join.
- **Functionality**: Allows a player to join an existing game.

### _joinGame
- **Modifiers**: N/A
- **Parameters**: 
  - `gameId` (`uint256`): The ID of the game to join.
- **Functionality**: Internal function to handle player joining logic.

### _transfer
- **Modifiers**: N/A
- **Parameters**: 
  - `to` (`address`): Address to transfer ether to.
  - `amount` (`uint256`): Amount of ether to transfer.
- **Functionality**: Internal function to transfer ether.

### drawCard
- **Modifiers**: 
  - `validGameId`: Validates the game ID.
- **Parameters**:
  - `gameId` (`uint256`): The ID of the game.
  - `seed` (`uint256`): A seed for randomness.
- **Returns**: `uint8` - The drawn card.
- **Functionality**: Draws a card from the game deck using a pseudo-random index.

### startGame
- **Modifiers**:
  - `onlyState`: Requires the game to be in the `AwaitingToStart` state.
  - `validGameId`: Validates the game ID.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
  - `seed` (`uint256`): A seed for randomness.
- **Functionality**: Starts the game and deals cards to players. It also sets the initial betting round.

### _min
- **Modifiers**: N/A
- **Parameters**:
  - `a` (`uint256`): First number.
  - `b` (`uint256`): Second number.
- **Returns**: `uint256` - The smaller of the two numbers.
- **Functionality**: Internal function to determine the smaller of two numbers.

### callAction
- **Modifiers**:
  - `validGameId`: Validates the game ID.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Functionality**: Allows a player to call during their turn in the betting round.

### raiseAction
- **Modifiers**:
  - `validGameId`: Validates the game ID.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
  - `raiseAmount` (`uint256`): The amount by which the player raises.
- **Functionality**: Allows a player to raise their bet during their turn in the betting round.

### checkAction
- **Modifiers**:
  - `validGameId`: Validates the game ID.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Functionality**: Allows a player to check during their turn in the betting round.

### foldAction
- **Modifiers**:
  - `validGameId`: Validates the game ID.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Functionality**: Allows a player to fold during their turn in the betting round.

### _isValidAction
- **Modifiers**: N/A
- **Parameters**:
  - `game` (`Game storage`): The game in question.
- **Returns**: `bool` - Whether the action is valid.
- **Functionality**: Internal function to check if a player's action is valid. It verifies if the game is currently in one of the main betting rounds: PreFlop, Flop, Turn, or River. Secondly, the condition checks if the current player (identified by game.currentPlayerIndex) has not folded their hand. Thirdly, it ensures that the action is being taken by the correct player, matching the msg.sender (the address calling the function) with the address of the current player in the game. Lastly, it confirms that the player is still in the game, as indicated by their status in the game.isPlayerInGame array.

### getIsValidAction
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Returns**: Tuple of four `bool` values representing valid state, action, player, and active player status.
- **Functionality**: Provides information about whether a player's action is valid in the current game state (get info from _isValidAction).

### _nextPlayer
- **Modifiers**: N/A
- **Parameters**:
  - `game` (`Game storage`): The game in question.
- **Functionality**: Internal function to move the turn to the next player in the game.

### flop
- **Modifiers**:
  - `onlyState`: Requires the game to be in the `PreFlop` state.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Returns**: Tuple of three `uint256` values representing the first, second, and third community cards.
- **Functionality**: Moves the game to the `Flop` state and reveals the first three community cards.

### turn
- **Modifiers**:
  - `onlyState`: Requires the game to be in the `Flop` state.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Returns**: Tuple of four `uint256` values representing the first four community cards.
- **Functionality**: Moves the game to the `Turn` state and reveals the fourth community card.

### River
- **Modifiers**:
  - `onlyState`: Requires the game to be in the `Turn` state.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Returns**: Tuple of five `uint256` values representing all the community cards.
- **Functionality**: Moves the game to the `River` state and reveals the fifth community card.

### showdown
- **Modifiers**:
  - `onlyState`: Requires the game to be in the `River` state.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Returns**: Tuple of three arrays: an array of arrays of `uint8` representing the hands of players, an array of `uint8` representing the best hand combinations, and an array of `uint8` representing the indices of the winning players.
- **Functionality**: Determines the winner(s) of the game based on the best hand and distributes the pot accordingly.

### clear
- **Modifiers**:
  - `onlyState`: Requires the game to be in the `Finish` state.
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Functionality**: Resets the game state for a new round or game. Handles distribution of remaining chips and resetting player statuses.

### _resetRound
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Functionality**: Internal function to reset the game state for a new round, including resetting bets, player actions, and community cards.

### _resetGame
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Functionality**: Internal function to completely reset and delete the game data.

### _resetPlayerCards
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint8`): The ID of the game.
- **Functionality**: Internal function to reset the cards of each player.

### getGameBasicDetails
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint256`): The ID of the game.
- **Returns**: Tuple containing the game's owner address, pot size, game status, verified player count, and an array of player statuses.
- **Functionality**: Provides basic details about the game, such as the owner, current pot, and the number of verified players.

### getHand
- **Modifiers**:
  - `onlyState`: Requires the game to be in the `PreFlop` state.
- **Parameters**:
  - `gameId` (`uint256`): The ID of the game.
- **Returns**: Tuple of two `uint8` values representing the player's two cards.
- **Functionality**: Provides the player's hand for the current game.

### getPlayers
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint256`): The ID of the game.
- **Returns**: `address[]` - Array of player addresses.
- **Functionality**: Returns a list of players participating in the specified game.

### getNumGames
- **Modifiers**: N/A
- **Functionality**: Returns the total number of games created (`uint8`).

### getRoundDetails
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint256`): The ID of the game.
- **Returns**: Tuple containing arrays of player bet amounts and actions, the current pot, current bet, and the index of the current player.
- **Functionality**: Provides detailed information about the current round in the specified game.

### getShowdown
- **Modifiers**: N/A
- **Parameters**:
  - `gameId` (`uint256`): The ID of the game.
- **Returns**: Same as `getRoundDetails`.
- **Functionality**: Provides detailed information about the showdown phase of the specified game.

[...End of Documentation...]




