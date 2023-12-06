// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract pokerProfile is ERC721, Ownable(msg.sender) {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 private constant TOKENS_RESERVED = 0;
    uint256 public price = 0;
    uint256 public constant MAX_MINT_PER_TX = 100;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("Poker NFT", "PKC") {
        // Base IPFS URI of the NFTs
        baseUri = "ipfs://bafybeie6wew34alb6drbwqyiy7akumsk3rgsczahkovxctj6jk2p3rthxe/";
        for (uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
            _safeMint(msg.sender, i);
        }
        totalSupply = TOKENS_RESERVED;
    }

    function mint(uint256 _numTokens) external payable {
        require(isSaleActive, "The sale is paused.");
        require(
            _numTokens <= MAX_MINT_PER_TX,
            "You can only mint a maximum of 10 NFTs per transaction."
        );
        require(
            mintedPerWallet[msg.sender] + _numTokens <= 10,
            "You can only mint 10 NFTs per wallet."
        );
        uint256 curTotalSupply = totalSupply;
        require(
            curTotalSupply + _numTokens <= MAX_TOKENS,
            "Exceeds `MAX_TOKENS"
        );
        require(
            _numTokens * price <= msg.value,
            "Insufficient funds. You need more ETH!"
        );

        for (uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }
        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseUri = _baseURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = (balance * 70) / 100;
        uint256 balanceTwo = (balance * 30) / 100;
        (bool transferOne, ) = payable(owner()).call{value: balanceOne}("");
        (bool transferTwo, ) = payable(owner()).call{value: balanceTwo}("");
        require(transferOne && transferTwo, "Transfer failed.");
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _ownerOf(tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // function _baseURI() internal view virtual override returns (string memory) {
    //     return baseUri;
    // }
}
