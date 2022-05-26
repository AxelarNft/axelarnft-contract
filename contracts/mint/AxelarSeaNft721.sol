//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IAxelarSeaNftInitializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AxelarSeaNft721 is Ownable, ERC721, IAxelarSeaNftInitializable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  bool private initialized;

  bytes32 public collectionId;
  bytes32 public projectId;
  string private nftName;
  string private nftSymbol;

  uint256 public exclusiveLevel;
  bytes32 public merkleRoot;
  uint256 public mintPriceStart;
  uint256 public mintPriceEnd;
  uint256 public mintPriceStep;
  address public mintTokenAddress;
  uint256 public mintStart;
  uint256 public mintEnd;

  Counters.Counter private supply;

  constructor() ERC721("_", "_") {}

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked("https://api-nftdrop.axelarsea.com/contractMetadata/", uint256(collectionId).toHexString()));
  }

  function initialize(
    address owner,
    bytes32 _collectionId,
    bytes32 _projectId,
    string memory _nftName, 
    string memory _nftSymbol,
    bytes memory data
  ) public {
    require(initialized, "Initialized");
    
    collectionId = _collectionId;
    projectId = _projectId;
    nftName = _nftName;
    nftSymbol = _nftSymbol;

    (
      uint256 _exclusiveLevel,
      bytes32 _merkleRoot,
      uint256 _mintPriceStart,
      uint256 _mintPriceEnd,
      uint256 _mintPriceStep,
      address _mintTokenAddress,
      uint256 _mintStart,
      uint256 _mintEnd
    ) = abi.decode(
      data,
      (
        uint256,
        bytes32,
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        uint256
      )
    );

    transferOwnership(owner);

    exclusiveLevel = _exclusiveLevel;
    merkleRoot = _merkleRoot;
    mintPriceStart = _mintPriceStart;
    mintPriceEnd = _mintPriceEnd;
    mintPriceStep = _mintPriceStep;
    mintTokenAddress = _mintTokenAddress;
    mintStart = _mintStart;
    mintEnd = _mintEnd;
  }

  function exists(uint256 tokenId) public view returns(bool) {
    return _exists(tokenId);
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked("https://api-nftdrop.axelarsea.com/tokenMetadata/", uint256(collectionId).toHexString(), "/", tokenId.toString()));
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view virtual override returns (string memory) {
      return nftName;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view virtual override returns (string memory) {
      return nftSymbol;
  }
}