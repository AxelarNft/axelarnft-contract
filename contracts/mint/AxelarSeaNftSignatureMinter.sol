//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./lib/AxelarSeaNftMinterBase.sol";

abstract contract AxelarSeaNftSignatureMinterBase is AxelarSeaNftMinterWithPayment, MetaTransactionVerifier {
  using SafeTransferLib for IERC20;

  address public operator;

  event UpdateConfigSignatureMinter(
    address indexed nftAddress,
    bytes32 indexed collectionId,
    bytes32 indexed projectId,
    address operator,
    AxelarSeaNftPriceData priceData
  );
  function _updateConfig(
    bytes memory data
  ) internal override {
    (operator, priceData) = abi.decode(data, (address, AxelarSeaNftPriceData));

    emit UpdateConfigSignatureMinter(
      address(nft),
      nft.collectionId(),
      nft.projectId(),
      operator,
      priceData
    );
  }

  function mintSignature(
    uint256 nonce,
    bytes calldata payload,
    bytes calldata signature
  ) public payable nonReentrant {
    verifyMetaTransaction(
      operator,
      nonce,
      payload,
      signature
    );

    (address to, uint256 maxAmount, uint256 amount) = abi.decode(payload, (address, uint256, uint256));
    _pay(msg.sender, amount);
    nft.mint(to, maxAmount, amount);
  }
}

contract AxelarSeaNftSignatureMinter is AxelarSeaNftSignatureMinterBase, AxelarSeaNftMinterWithTokenPayment {}
contract AxelarSeaNftSignatureMinterNative is AxelarSeaNftSignatureMinterBase, AxelarSeaNftMinterWithNativePayment {}
