//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/AxelarSeaNftMinterBase.sol";

abstract contract AxelarSeaNftMerkleMinterBase is AxelarSeaNftMinterWithPayment {
  using SafeTransferLib for IERC20;

  bytes32 public merkleRoot;

  event UpdateConfigMerkleMinter(
    address indexed nftAddress,
    bytes32 indexed collectionId,
    bytes32 indexed projectId,
    bytes32 merkleRoot,
    AxelarSeaNftPriceData priceData
  );
  function _updateConfig(
    bytes memory data
  ) internal override {
    (merkleRoot, priceData) = abi.decode(data, (bytes32, AxelarSeaNftPriceData));

    emit UpdateConfigMerkleMinter(
      address(nft),
      nft.collectionId(),
      nft.projectId(),
      merkleRoot,
      priceData
    );
  }

  function checkMerkle(address toCheck, uint256 maxAmount, bytes32[] calldata proof) public view returns(bool) {
    return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(toCheck, maxAmount)));
  }

  function mintMerkle(address to, uint256 maxAmount, uint256 amount, bytes32[] calldata proof) public payable nonReentrant {
    if(!checkMerkle(to, maxAmount, proof)) revert NotWhitelisted();
    _ensureMintLimit(to, maxAmount, amount);
    _pay(msg.sender, amount);
    nft.mint(to, amount);
  }
}

contract AxelarSeaNftMerkleMinter is AxelarSeaNftMerkleMinterBase, AxelarSeaNftMinterWithTokenPayment {}
contract AxelarSeaNftMerkleMinterNative is AxelarSeaNftMerkleMinterBase, AxelarSeaNftMinterWithNativePayment {}
