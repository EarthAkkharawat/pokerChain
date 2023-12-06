# PokerChain
## Members
- 6330104021 Charnkij Suksuwanveeree
- 6330563421 Akira Sitdhikariyawat
- 6330585221 Akkharawat Burachokviwat
- 6331324021 Punya Gunawardana

## Description
Our project aims to revolutionize online poker by introducing a blockchain-powered platform, addressing the trust and transparency issues prevalent in traditional centralized poker systems. This innovative approach utilizes smart contracts for guaranteed fair play and transparent card distribution. Every game detail is indelibly recorded on the blockchain, ensuring permanent, transparent records and robust anti-collusion measures. By leveraging the strengths of blockchain technology, such as its immutability and decentralization, our platform provides a secure, trustless gaming environment, superior to conventional online poker platforms.

Note: The design of this poker platform incorporates adjusted rules, intended mainly for educational use. Its primary aim is to showcase the capabilities and applications of blockchain technology in the realm of online gaming. While integrating the smart contract with the user interface, minor errors or glitches may occasionally occur. Nonetheless, the smart contract underpinning the game's logic is fully operational and serves to demonstrate its functional aspects.


## Details
- [Poker Smart Contracts](contracts/README.md): All the poker game logic is managed on this component. Inside this component, there will be [main-v2.sol](contracts/main-v2.sol) which manage all game logic and [utils.sol](contracts/utils.sol) which is a library that manage all card logic (check winning hand, determine winning pattern etc.)
- [NFT Smart Contracts](contracts_nft/README.md): This component manage NFTs within the application.
- [Frontend](frontend/README.md): The GUI to interact and with the poker game logic and play is managed within this component.

## Deployment & How to run
**Game Logic**
- Upload both [main-v2.sol](contracts/main-v2.sol) and [utils.sol](contracts/utils.sol) to Remix IDE, compile with enable optimization option as on and then deploy the main-v2.sol contract.
- Put the deployed contract address into the [following line in contract.tsx](frontend/src/utils/contracts.tsx#L6) and add [contract's ABI](frontend/src/utils/pokerContractABI.json) to the same folder.
- This component can be deployed alone on Remix IDE to easily test the functionalities of this Poker game.

**NFTs**
- Upload [nft.sol](contracts_nft/nft.sol) to Remix IDE then compile and deploy.
- Put the deployed contract address into the [following line in contract.tsx](frontend/src/utils/contracts.tsx#L7) and add [contract's ABI](frontend/src/utils/nftContractABI.json) to the same folder.

**Frontend**
- run the following command in order
```
> cd frontend
> npm i
> npm start
```
- Then go to [http://localhost:3000](http://localhost:3000) to play with our Poker game.