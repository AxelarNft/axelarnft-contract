//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../meta-transactions/NativeMetaTransaction.sol";
import "../meta-transactions/ContextMixin.sol";
import "./IAxelarSeaNftInitializable.sol";

contract AxelarSeaNft721 is Ownable, ERC721Enumerable, NativeMetaTransaction, ContextMixin, IAxelarSeaNftInitializable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  bool private initialized;

  bytes32 public collectionId;
  bytes32 public projectId;
  string private nftName;
  string private nftSymbol;

  uint256 public exclusiveLevel;
  bytes32 public merkleRoot;
  uint256 public mintPerWalletAddress;
  uint256 public mintPriceStart;
  uint256 public mintPriceEnd;
  uint256 public mintPriceStep;
  address public mintTokenAddress;
  uint256 public mintStart;
  uint256 public mintEnd;

  mapping(address => bool) public minters;
  mapping(address => uint256) public walletMinted;

  modifier onlyMinter {
    require(minters[msgSender()], "Forbidden");
    _;
  }

  constructor() ERC721("_", "_") {}

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
      uint256 _mintPerWalletAddress,
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
        uint256,
        address,
        uint256,
        uint256
      )
    );

    transferOwnership(owner);

    exclusiveLevel = _exclusiveLevel;
    merkleRoot = _merkleRoot;
    mintPerWalletAddress = _mintPerWalletAddress;
    mintPriceStart = _mintPriceStart;
    mintPriceEnd = _mintPriceEnd;
    mintPriceStep = _mintPriceStep;
    mintTokenAddress = _mintTokenAddress;
    mintStart = _mintStart;
    mintEnd = _mintEnd;
  }

  function _mintInternal(address to, uint256 amount) internal {
    walletMinted[to] += amount;
    require(walletMinted[to] <= mintPerWalletAddress, "Mint Limited");

    unchecked {
      uint256 supply = totalSupply();

      if (amount == 1) {
        _safeMint(to, supply + 1);
      } else {
        for (uint256 i = 1; i <= amount; i++) {
          _safeMint(to, supply + i);
        }
      }
    }
  }

  function _pay(address from, uint256 amount) internal {
    
  }

  function merkleMint(bytes32[] calldata proof, uint256 amount) public {
    address sender = msgSender();
    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(sender))), "Not whitelisted");
    _mintInternal(sender, amount);
  }

  function mint(address to, uint256 amount) public onlyMinter {
    _mintInternal(to, amount);
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