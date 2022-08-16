//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./lib/AxelarSeaNftMinterBase.sol";

abstract contract AxelarSeaNftPublicMinterBase is AxelarSeaNftMinterWithPayment {
  using SafeTransferLib for IERC20;

  uint256 public maxMintPerWallet;

  event UpdateConfigPublicMinter(
    address indexed nftAddress,
    bytes32 indexed collectionId,
    bytes32 indexed projectId,
    uint256 maxMintPerWallet,
    AxelarSeaNftPriceData priceData
  );
  function _updateConfig(
    bytes memory data
  ) internal override {
    (maxMintPerWallet, priceData) = abi.decode(data, (uint256, AxelarSeaNftPriceData));

    emit UpdateConfigPublicMinter(
      address(nft),
      nft.collectionId(),
      nft.projectId(),
      maxMintPerWallet,
      priceData
    );
  }

  function mintPublic(address to, uint256 amount) public payable nonReentrant {
    _pay(msg.sender, amount);
    nft.mint(to, maxMintPerWallet, amount);
  }
}

contract AxelarSeaNftPublicMinter is AxelarSeaNftPublicMinterBase, AxelarSeaNftMinterWithTokenPayment {}
contract AxelarSeaNftPublicMinterNative is AxelarSeaNftPublicMinterBase, AxelarSeaNftMinterWithNativePayment {}
