//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MarketplaceMetaWallet.sol";
import "./meta-transactions/NativeMetaTransaction.sol";
import "./meta-transactions/ContextMixin.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// import {IAxelarExecutable} from "./IAxelarExecutable.sol";

import "hardhat/console.sol";

contract AxelarSeaMarketplace is Ownable, NativeMetaTransaction, ContextMixin, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Buy(address buyer, address indexed token, uint256 indexed tokenId, uint256 amount, address priceToken, uint256 price, address indexed seller);

    address public marketplaceMetaWallet;

    address public feeAddress;
    uint256 public marketFee = 2.5e16; // 2.5%

    struct SaleInfo {
        uint256 amount;
        IERC20 priceToken;
        uint256 price;
    }

    constructor(address _marketplaceMetaWallet) {
        feeAddress = msg.sender;
        marketplaceMetaWallet = _marketplaceMetaWallet;
        _initializeEIP712("AxelarSeaMarketplace");
    }

    mapping(address => mapping(address => mapping(uint256 => SaleInfo))) private sales;
    mapping(address => MarketplaceMetaWallet) public metaWallet;
    mapping(address => uint256) public royalty;

    function getSale(address seller, address token, uint256 tokenId) public view returns(SaleInfo memory) {
        return sales[seller][token][tokenId];
    }

    event SetFeeAddress(address indexed caller, address indexed newAddress);
    function setFeeAddress(address newAddress) public onlyOwner {
        feeAddress = newAddress;
        emit SetFeeAddress(msg.sender, newAddress);
    }

    event SetMarketFee(address indexed caller, uint256 newFee);
    function setMarketFee(uint256 newFee) public onlyOwner {
        marketFee = newFee;
        emit SetMarketFee(msg.sender, newFee);
    }

    event SetRoyaltyFee(address indexed setter, address indexed token, uint256 fee);
    function setRoyaltyFee(address token, uint256 fee) public {
        require(Ownable(token).owner() == msgSender(), "Not collection owner");
        require(fee <= 1e18 - marketFee, "Invalid fee");
        royalty[token] = fee;
        emit SetRoyaltyFee(msgSender(), token, fee);
    }

    event List(address indexed seller, address indexed token, uint256 indexed tokenId, uint256 amount, address priceToken, uint256 price);
    function list(address token, uint256 tokenId, uint256 amount, IERC20 priceToken, uint256 price) public {
        address seller = msgSender();
        sales[seller][token][tokenId].amount = amount;
        sales[seller][token][tokenId].priceToken = priceToken;
        sales[seller][token][tokenId].price = price;
        emit List(seller, token, tokenId, amount, address(priceToken), price);
    }

    event CancelListing(address indexed seller, address indexed token, uint256 indexed tokenId);
    function cancelListing(address token, uint256 tokenId) public {
        address seller = msgSender();
        sales[seller][token][tokenId].amount = 0;
        sales[seller][token][tokenId].price = 0;
        emit CancelListing(seller, token, tokenId);
    }

    function buyERC721(IERC721 token, address seller, uint256 tokenId) public nonReentrant {
        address buyer = msgSender();

        SaleInfo storage saleInfo = sales[seller][address(token)][tokenId];

        require(saleInfo.amount > 0 && saleInfo.price > 0, "Not for sale");

        uint256 fee = saleInfo.price * marketFee / 1e18;
        uint256 royaltyFee = saleInfo.price * royalty[address(token)] / 1e18;

        saleInfo.priceToken.safeTransferFrom(buyer, feeAddress, fee);
        if (royaltyFee > 0) {
            saleInfo.priceToken.safeTransferFrom(buyer, Ownable(address(token)).owner(), royaltyFee);
        }
        saleInfo.priceToken.safeTransferFrom(buyer, seller, saleInfo.price - fee - royaltyFee);
        token.safeTransferFrom(seller, buyer, tokenId);

        emit Buy(buyer, address(token), tokenId, 1, address(saleInfo.priceToken), saleInfo.price, seller);

        sales[seller][address(token)][tokenId].price = 0;
        sales[seller][address(token)][tokenId].amount = 0;
    }

    function buyERC1155(IERC1155 token, address seller, uint256 tokenId, uint256 amount) public nonReentrant {
        address buyer = msgSender();

        SaleInfo storage saleInfo = sales[seller][address(token)][tokenId];

        require(amount > 0 && saleInfo.amount >= amount && saleInfo.price > 0, "Not for sale");

        uint256 fee = saleInfo.price * marketFee / 1e18;
        uint256 royaltyFee = saleInfo.price * royalty[address(token)] / 1e18;

        saleInfo.priceToken.safeTransferFrom(buyer, feeAddress, fee * amount);
        if (royaltyFee > 0) {
            saleInfo.priceToken.safeTransferFrom(buyer, Ownable(address(token)).owner(), royaltyFee * amount);
        }
        saleInfo.priceToken.safeTransferFrom(buyer, seller, (saleInfo.price - fee - royaltyFee) * amount);
        token.safeTransferFrom(seller, buyer, tokenId, amount, "");

        emit Buy(buyer, address(token), tokenId, amount, address(saleInfo.priceToken), saleInfo.price, seller);

        sales[seller][address(token)][tokenId].amount -= amount;
    }

    event CreateMetaWallet(address indexed caller, address indexed target, address indexed contractAddress);
    function createMetaWallet(address target) public returns(MarketplaceMetaWallet) {
        MarketplaceMetaWallet wallet = MarketplaceMetaWallet(Clones.clone(marketplaceMetaWallet));
        wallet.initialize(address(this), target);
        emit CreateMetaWallet(msgSender(), target, address(wallet));
        metaWallet[target] = wallet;
        return wallet;
    }
}
