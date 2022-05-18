// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    mapping(address => uint256) private _mintPrices;
    mapping(address => bool) private _whiteList;
    mapping(uint256 => mapping(address => uint256)) private _salesPrices;
    Counters.Counter private _tokenIdCounter;
    address private _systemAddress;
    uint256 private _maxMintSupply;

    bool public isBlind;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _tokenIdCounter.increment();
        _whiteList[_msgSender()] = true;
    }

    function mint(address tokenAddress) public {
        require(_whiteList[_msgSender()] == true, "Not in whitelist.");

        require(
            _maxMintSupply <= _tokenIdCounter.current(),
            "Over than mint supply."
        );

        require(
            _mintPrices[tokenAddress] > 0,
            "Not support this token or pausing use this token for mint."
        );

        require(
            IERC20(tokenAddress).allowance(_msgSender(), address(this)) >=
                _mintPrices[tokenAddress],
            "Allowance too low."
        );

        IERC20(tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _mintPrices[tokenAddress]
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function getMintPrice(address tokenAddress)
        public
        view
        returns (uint256 amount)
    {
        return _mintPrices[tokenAddress];
    }

    function setMintPrice(address tokenAddress, uint256 value)
        public
        onlyOwner
    {
        require(tokenAddress == address(tokenAddress), "Invalid address.");
        _mintPrices[tokenAddress] = value;
    }

    function setMaxMintAmount(uint256 amount) public onlyOwner {
        _maxMintSupply = amount;
    }

    function setBlind() public onlyOwner {
        require(isBlind == false, "Blind box was unpack.");
        isBlind = true;
    }

    function setWhiteList(address userAddress, bool state) public onlyOwner {
        require(_whiteList[userAddress] != state, "same state.");
        _whiteList[userAddress] = state;
    }

    function checkInWhiteList(address target) public view returns (bool) {
        return _whiteList[target];
    }

    function getPrice(uint256 id, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return _salesPrices[id][tokenAddress];
    }

    function setSalePrice(
        uint256 id,
        address tokenAddress,
        uint256 price
    ) public {
        require(ownerOf(id) == _msgSender(), "You not have this token.");
        _salesPrices[id][tokenAddress] = price;
        approve(address(this), id);
    }

    function buy(uint256 id, address tokenAddress) public {
        require(getApproved(id) == address(this), "This nft can't transfer.");

        require(
            _salesPrices[id][tokenAddress] != 0,
            "This nft not support this token."
        );

        require(
            IERC20(tokenAddress).allowance(_msgSender(), address(this)) >=
                _salesPrices[id][tokenAddress],
            "Allowance too low."
        );

        IERC20(tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _salesPrices[id][tokenAddress]
        );

        address tokenOwner = ownerOf(id);
        
        IERC20(tokenAddress).safeIncreaseAllowance(
            tokenOwner,
            _salesPrices[id][tokenAddress]
        );

        IERC20(tokenAddress).safeTransfer(
            tokenOwner,
            _salesPrices[id][tokenAddress]
        );

        _safeTransfer(tokenOwner, _msgSender(), id, "");
        _salesPrices[id][tokenAddress] = 0;
    }
}
