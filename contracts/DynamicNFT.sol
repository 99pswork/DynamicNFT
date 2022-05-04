// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "erc721a/contracts/ERC721A.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TheDynamicNFT is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    bool public preSaleActive = true;
    bool public publicSaleActive = false;

    bool public paused = true;
    bool public revealed = false;

    uint256 public maxSupply = 50; 
    uint256 public preSalePrice = 0.1 ether; 
    uint256 public publicSalePrice = 0.15 ether; 

    uint256 public maxPreSale = 1;
    uint256 public maxPublicSale = 1;

    string private _baseURIextended1;
    string private _baseURIextended2;
    
    string public notRevealedUri = "";

    uint256 deviationPercent = 5;

    AggregatorV3Interface internal priceFeed;

    mapping(address => bool) public isWhiteListed;

    mapping(address => uint256) public preSaleCounter;
    mapping(address => uint256) public publicSaleCounter;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) ReentrancyGuard() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // mainnet
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function preSaleMint(uint256 _amount) external payable nonReentrant{
        require(preSaleActive, "Dynamic-NFT Pre Sale is not Active");
        require(isWhiteListed[msg.sender], "Dynamic-NFT User is not White-Listed");
        require(preSaleCounter[msg.sender].add(_amount) <= maxPreSale, "Dynamic-NFT Maximum Pre Sale Minting Limit Reached");
        require(preSalePrice*_amount <= msg.value, "Dynamic-NFT ETH Value Sent for Pre Sale is not enough");
        mint(_amount, true);
    }

    function publicSaleMint(uint256 _amount) external payable nonReentrant {
        require(publicSaleActive, "Dynamic-NFT Public Sale is not Active");
        require(publicSaleCounter[msg.sender].add(_amount) <= maxPublicSale, "Dynamic-NFT Maximum Minting Limit Reached");
        mint(_amount, false);
    }

    function mint(uint256 amount,bool state) internal {
        require(!paused, "Dynamic-NFT Minting is Paused");
        require(totalSupply().add(amount) <= maxSupply, "Dynamic-NFT Maximum Supply Reached");
        if(state){
            preSaleCounter[msg.sender] = preSaleCounter[msg.sender].add(amount);
        }
        else{
            require(publicSalePrice*amount <= msg.value, "Dynamic-NFT ETH Value Sent for Public Sale is not enough");
            publicSaleCounter[msg.sender] = publicSaleCounter[msg.sender].add(amount);
        }
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view virtual override returns (string memory){
        if(checkDeviation())
        {
            return _baseURIextended1;
        }
        else{
            return _baseURIextended2;
        }
    }

    function setBaseURI(string calldata baseURI1_, string calldata baseURI2_) external onlyOwner {
        _baseURIextended1 = baseURI1_;
        _baseURIextended2 = baseURI2_;
    }

    function togglePauseState() external onlyOwner {
        paused = !paused;
    }

    function togglePreSale() external onlyOwner {
        preSaleActive = !preSaleActive;
        publicSaleActive = false;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        preSaleActive = false;
    }

    function addWhiteListedAddresses(address[] memory _address) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            isWhiteListed[_address[i]] = true;
        }
    }

    function setPreSalePrice(uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setDeviation(uint256 _percent) external onlyOwner {
        deviationPercent = _percent;
    }

    function airDrop(address[] memory _address) external onlyOwner {
        require(totalSupply().add(_address.length) <= maxSupply, "Dynamic-NFT Maximum Supply Reached");
        for(uint i=0; i < _address.length; i++){
            _safeMint(_address[i], 1);
        }
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function withdrawTotal() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setNotRevealedURI(string memory _notRevealedUri) external onlyOwner {
        notRevealedUri = _notRevealedUri;
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Dynamic-NFT URI For Token Non-existent");
        if(!revealed){
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI(); 
        return bytes(currentBaseURI).length > 0 ? 
        string(abi.encodePacked(currentBaseURI,_tokenId.toString(),".json")) : "";
    }

    function checkDeviation() internal view returns(bool) {
        uint80 roundId;
        int price;
        int priceOld;
        uint timeStamp;
        uint256 deviation;
        uint256 priceDifference;

        (roundId, price,, timeStamp,) = priceFeed.latestRoundData();

        uint timeStampOld = timeStamp;
        timeStamp -= 86400; // 1 day = 86400

        while (timeStampOld > timeStamp) {
            roundId -= 1;
            (,priceOld,, timeStampOld,) = priceFeed.getRoundData(roundId);
        }

        if(priceOld > price) {
            priceDifference = uint256(priceOld - price);
            deviation = priceDifference.mul(100).div(uint256(priceOld));
            if(deviation > deviationPercent) {
                return true; // +ve deviation
            }
        }
        return false;
    }
}
