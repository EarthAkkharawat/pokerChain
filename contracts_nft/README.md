
# PokerProfile NFT Smart Contract

## Overview

This Solidity smart contract, named `PokerProfile`, is an ERC-721 compliant non-fungible token (NFT) contract for creating and managing unique Poker-themed NFTs. Each token represents a distinct Poker profile and is owned by an Ethereum address.

## Features

- **ERC-721 Compliance**: The contract follows the ERC-721 standard, allowing for the creation and ownership of unique tokens on the Ethereum blockchain.

- **Ownership and Minting Limits**: The contract inherits from the `Ownable` and `ERC721` contracts. It allows the owner to reserve a certain number of tokens and establishes limits on the number of tokens that can be minted in a single transaction and per wallet.

- **Sale Functionality**: The contract includes functionality to enable or disable the sale of tokens. Only the contract owner has the authority to toggle the sale state.

- **Metadata and URI Configuration**: Each token has associated metadata, and the base URI for fetching metadata from IPFS is configurable by the contract owner. The metadata for each token is constructed based on the token ID and a base URI.

- **Minting and Pricing**: Users can mint tokens by sending ETH to the contract. The number of tokens to mint, price per token, and total supply limits are enforced. Minted tokens are assigned to the sender's address.

- **Withdrawal Function**: The contract owner can withdraw the contract's ETH balance. The withdrawal is split into two portions: 70% for one address and 30% for another.

## Contract Parameters

- `MAX_TOKENS`: The maximum number of tokens that can be minted.
- `TOKENS_RESERVED`: The number of tokens reserved for the contract owner.
- `price`: The price per token in ETH.
- `MAX_MINT_PER_TX`: The maximum number of tokens that can be minted in a single transaction.

## Functions

- `mint(uint256 _numTokens)`: Allows users to mint a specified number of tokens, subject to various checks.
- `flipSaleState()`: Toggles the sale state, enabling or disabling the minting of tokens.
- `setBaseURI(string memory _baseURI)`: Allows the owner to set the base URI for token metadata.
- `setPrice(uint256 _price)`: Allows the owner to set the price per token.
- `withdrawAll()`: Allows the owner to withdraw the contract's ETH balance.
- `tokenURI(uint256 tokenId)`: Overrides the ERC-721 `tokenURI` function to generate the URI for a specific token ID.

## Deployment

The contract is deployed with a predefined base IPFS URI, and a certain number of tokens are reserved for the contract owner during deployment.

## License

This smart contract is released under the MIT License. See the SPDX-License-Identifier at the top of the code for details.