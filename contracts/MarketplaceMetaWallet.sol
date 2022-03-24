//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Minimal contract for allowing token transfer seperated from user wallet

import "./Marketplace.sol";
import "./meta-transactions/NativeMetaTransaction.sol";
import "./meta-transactions/ContextMixin.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketplaceMetaWallet is NativeMetaTransaction, ContextMixin, ReentrancyGuard {
  using SafeERC20 for IERC20;

  event Buy(address indexed token, uint256 indexed tokenId, uint256 amount, address priceToken, uint256 price, address indexed seller);

  bool public initialized = false;

  AxelarSeaMarketplace public master;
  address public walletAddress;

  modifier onlyOwner {
    require(msgSender() == walletAddress, "Not owner");
    _;
  }

  function initialize(address _master, address _walletAddress) public {
    require(!initialized, "Initialized");

    master = AxelarSeaMarketplace(_master);
    walletAddress = _walletAddress;

    initialized = true;
  }

  function buyERC721(IERC721 token, address seller, uint256 tokenId) public nonReentrant onlyOwner {
    AxelarSeaMarketplace.SaleInfo memory saleInfo = master.getSale(seller, address(token), tokenId);

    saleInfo.priceToken.safeApprove(address(master), saleInfo.price + 10000); // + 10000 To prevent floating point error
    master.buyERC721(token, seller, tokenId);
    token.safeTransferFrom(address(this), walletAddress, tokenId);

    // Prevent any exploit
    saleInfo.priceToken.safeApprove(address(master), 0);

    emit Buy(address(token), tokenId, 1, address(saleInfo.priceToken), saleInfo.price, seller);
  }

  function buyERC1155(IERC1155 token, address seller, uint256 tokenId, uint256 amount) public nonReentrant onlyOwner {
    AxelarSeaMarketplace.SaleInfo memory saleInfo = master.getSale(seller, address(token), tokenId);
    
    saleInfo.priceToken.safeApprove(address(master), saleInfo.price * amount + 10000); // + 10000 To prevent floating point error
    master.buyERC1155(token, seller, tokenId, amount);
    token.safeTransferFrom(address(this), walletAddress, tokenId, amount, "");

    // Prevent any exploit
    saleInfo.priceToken.safeApprove(address(master), 0);

    emit Buy(address(token), tokenId, amount, address(saleInfo.priceToken), saleInfo.price, seller);
  }
}