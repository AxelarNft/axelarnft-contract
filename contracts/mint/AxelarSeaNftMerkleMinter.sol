//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../meta-transactions/MetaTransactionVerifier.sol";
import "./IAxelarSeaNftInitializable.sol";
import "./AxelarSeaNftBase.sol";

contract AxelarSeaNftMerkleMinter is Ownable, ReentrancyGuard {
  struct AxelarSeaNftMintData {
    bytes32 merkleRoot;
    uint256 mintPriceStart;
    uint256 mintPriceEnd;
    uint256 mintPriceStep;
    IERC20 mintTokenAddress;
    uint256 mintStart;
    uint256 mintEnd;
  }

  bool private initialized;
  AxelarSeaProjectRegistry public registry;
  AxelarSeaNftMintData public mintData;
  AxelarSeaNftBase public nft;

  event UpdateConfig(
    address indexed nftAddress,
    bytes32 indexed collectionId,
    bytes32 indexed projectId,
    AxelarSeaNftMintData mintData
  );
  function updateConfig(
    bytes memory data
  ) public onlyOwner {
    mintData = abi.decode(data, (AxelarSeaNftMintData));

    require(mintData.mintEnd >= mintData.mintStart, "Invalid timestamp");

    emit UpdateConfig(
      address(nft),
      nft.collectionId(),
      nft.projectId(),
      mintData
    );
  }

  function initialize(
    address targetNft,
    address owner,
    bytes memory data
  ) external {
    require(!initialized, "Initialized");
    initialized = true;

    nft = AxelarSeaNftBase(targetNft);
    registry = nft.registry();

    updateConfig(data);

    _transferOwnership(owner);
  }

  function mintFee() public view returns(uint256) {
    return nft.mintFee();
  }

  function mintPrice() public view returns(uint256) {
    unchecked {
      if (mintData.mintPriceStep == 0) {
        return mintData.mintPriceStart;
      }

      if (block.timestamp < mintData.mintStart) {
        return mintData.mintPriceStart;
      }
      
      // block.timestamp >= mintStart
      uint256 priceChange = mintData.mintPriceStep * (block.timestamp - mintData.mintStart);
      uint256 priceDiff = mintData.mintPriceEnd <= mintData.mintPriceStart ? mintData.mintPriceStart - mintData.mintPriceEnd : mintData.mintPriceEnd - mintData.mintPriceStart;

      if (priceChange < priceDiff) {
        return mintData.mintPriceEnd <= mintData.mintPriceStart ? mintData.mintPriceStart - priceChange : mintData.mintPriceStart + priceChange; 
      } else {
        return mintData.mintPriceEnd;
      }
    }
  }

  function _pay(address from, uint256 amount) internal {
    if (!(block.timestamp >= mintData.mintStart && block.timestamp <= mintData.mintEnd)) {
      revert NotMintingTime();
    }

    if (mintData.mintPriceStart > 0 || mintData.mintPriceEnd > 0) {
      uint256 totalPrice = mintPrice() * amount;
      uint256 fee = totalPrice * mintFee() / 1e18;

      mintData.mintTokenAddress.transferFrom(from, registry.feeAddress(), fee);
      mintData.mintTokenAddress.transferFrom(from, nft.fundAddress(), totalPrice - fee);
    }
  }

  function checkMerkle(address toCheck, uint256 maxAmount, bytes32[] calldata proof) public view returns(bool) {
    return MerkleProof.verify(proof, mintData.merkleRoot, keccak256(abi.encodePacked(toCheck, maxAmount)));
  }

  function mintMerkle(address to, uint256 maxAmount, uint256 amount, bytes32[] calldata proof) public nonReentrant {
    require(checkMerkle(to, maxAmount, proof), "Not whitelisted");
    _pay(msg.sender, amount);
    nft.mint(to, maxAmount, amount);
  }

  // function mintSignature(
  //   address operatorAddress,
  //   uint256 nonce,
  //   bytes32 sigR,
  //   bytes32 sigS,
  //   uint8 sigV,
  //   bytes memory payload
  // ) public onlyMinter(operatorAddress) nonReentrant {
  //   verifyMetaTransaction(
  //     operatorAddress,
  //     payload,
  //     nonce,
  //     sigR,
  //     sigS,
  //     sigV
  //   );

  //   (address to, uint256 maxAmount, uint256 amount) = abi.decode(payload, (address, uint256, uint256));
  //   _pay(msg.sender, amount);
  //   _mintInternal(to, maxAmount, amount);
  // }
}