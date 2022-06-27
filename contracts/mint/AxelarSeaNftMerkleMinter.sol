//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "../lib/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IAxelarSeaNftInitializable.sol";
import "./AxelarSeaNftBase.sol";
import "hardhat/console.sol";

contract AxelarSeaNftMerkleMinter is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct AxelarSeaNftMintData {
    bytes32 merkleRoot;
    uint256 mintPriceStart;
    uint256 mintPriceEnd;
    uint256 mintPriceStep;
    uint256 mintStart;
    uint256 mintEnd;
    IERC20 mintTokenAddress;
  }

  bool private initialized;
  AxelarSeaProjectRegistry public registry;
  AxelarSeaNftMintData public mintData;
  AxelarSeaNftBase public nft;

  event UpdateConfigMerkleMinter(
    address indexed nftAddress,
    bytes32 indexed collectionId,
    bytes32 indexed projectId,
    AxelarSeaNftMintData mintData
  );
  function _updateConfig(
    bytes memory data
  ) internal {
    mintData = abi.decode(data, (AxelarSeaNftMintData));

    require(mintData.mintEnd >= mintData.mintStart, "Invalid timestamp");

    emit UpdateConfigMerkleMinter(
      address(nft),
      nft.collectionId(),
      nft.projectId(),
      mintData
    );
  }

  function updateConfig(
    bytes memory data
  ) public onlyOwner {
    _updateConfig(data);
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

    _updateConfig(data);
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
    if (block.timestamp < mintData.mintStart || block.timestamp > mintData.mintEnd) {
      revert NotMintingTime();
    }

    if (mintData.mintPriceStart > 0 || mintData.mintPriceEnd > 0) {
      uint256 totalPrice = mintPrice() * amount;
      uint256 fee = totalPrice * mintFee() / 1e18;

      console.log(totalPrice);

      mintData.mintTokenAddress.safeTransferFrom(from, registry.feeAddress(), fee);
      mintData.mintTokenAddress.safeTransferFrom(from, nft.fundAddress(), totalPrice - fee);
    }
  }

  function checkMerkle(address toCheck, uint256 maxAmount, bytes32[] calldata proof) public view returns(bool) {
    return MerkleProof.verify(proof, mintData.merkleRoot, keccak256(abi.encodePacked(toCheck, maxAmount)));
  }

  function mintMerkle(address to, uint256 maxAmount, uint256 amount, bytes32[] calldata proof) public nonReentrant {
    if(!checkMerkle(to, maxAmount, proof)) revert NotWhitelisted();
    _pay(msg.sender, amount);
    nft.mint(to, maxAmount, amount);
  }

  function recoverETH() external onlyOwner {
    payable(msg.sender).call{value: address(this).balance}("");
  }

  function recoverERC20(IERC20 token) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }
}