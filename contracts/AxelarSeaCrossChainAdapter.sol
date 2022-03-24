//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// Emit event and let backend submit it to meta wallet

// On test we exclude fee, so we can bypass this section

contract AxelarSeaCrossChainAdapter {
  using SafeERC20 for IERC20;

  event CreateMetaWallet(address target);
  function createMetaWallet() public {
    emit CreateMetaWallet(msg.sender);
  }

  // event BuyERC721();
  // function buyERC721(IERC721 token, address seller, uint256 tokenId, address destination, IERC20 token, uint256 amount) public {
  //   token.safeTransfer
  // }
}