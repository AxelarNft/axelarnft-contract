//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../meta-transactions/MetaTransactionVerifier.sol";
import "./IAxelarSeaNftInitializable.sol";

contract AxelarSeaNft721 is Ownable, ERC721Enumerable, MetaTransactionVerifier, IAxelarSeaNftInitializable {
  using Strings for uint256;

  bool private initialized;

  address public fundAddress;

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
  IERC20 public mintTokenAddress;
  uint256 public mintStart;
  uint256 public mintEnd;

  mapping(address => bool) public minters;
  mapping(address => uint256) public walletMinted;

  modifier onlyMinter(address addr) {
    require(minters[addr], "Forbidden");
    _;
  }

  constructor() ERC721("_", "_") {}

  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked("https://api-nftdrop.axelarsea.com/contractMetadata/", uint256(collectionId).toHexString()));
  }

  event UpdateConfig(
    bytes32 indexed collectionId,
    uint256 exclusiveLevel,
    bytes32 merkleRoot,
    uint256 mintPerWalletAddress,
    uint256 mintPriceStart,
    uint256 mintPriceEnd,
    uint256 mintPriceStep,
    IERC20 mintTokenAddress,
    uint256 mintStart,
    uint256 mintEnd
  );
  function updateConfig(
    bytes32 _merkleRoot,
    uint256 _mintPerWalletAddress,
    uint256 _mintPriceStart,
    uint256 _mintPriceEnd,
    uint256 _mintPriceStep,
    IERC20 _mintTokenAddress,
    uint256 _mintStart,
    uint256 _mintEnd
  ) public onlyOwner {
    require(_mintEnd >= _mintStart, "Invalid timestamp");

    merkleRoot = _merkleRoot;
    mintPerWalletAddress = _mintPerWalletAddress;
    mintPriceStart = _mintPriceStart;
    mintPriceEnd = _mintPriceEnd;
    mintPriceStep = _mintPriceStep;
    mintTokenAddress = _mintTokenAddress;
    mintStart = _mintStart;
    mintEnd = _mintEnd;

    emit UpdateConfig(
      collectionId,
      exclusiveLevel,
      _merkleRoot,
      _mintPerWalletAddress,
      _mintPriceStart,
      _mintPriceEnd,
      _mintPriceStep,
      _mintTokenAddress,
      _mintStart,
      _mintEnd
    );
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
      IERC20 _mintTokenAddress,
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
        IERC20,
        uint256,
        uint256
      )
    );

    transferOwnership(owner);

    exclusiveLevel = _exclusiveLevel;

    updateConfig(
      _merkleRoot,
      _mintPerWalletAddress,
      _mintPriceStart,
      _mintPriceEnd,
      _mintPriceStep,
      _mintTokenAddress,
      _mintStart,
      _mintEnd
    );
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

  function mintPrice() public view returns(uint256) {
    unchecked {
      if (mintPriceStep == 0) {
        return mintPriceStart;
      }

      if (block.timestamp < mintStart) {
        return mintPriceStart;
      }
      
      // block.timestamp >= mintStart
      uint256 priceChange = mintPriceStep * (block.timestamp - mintStart);
      uint256 priceDiff = mintPriceEnd <= mintPriceStart ? mintPriceStart - mintPriceEnd : mintPriceEnd - mintPriceStart;

      if (priceChange < priceDiff) {
        return mintPriceEnd <= mintPriceStart ? mintPriceStart - priceChange : mintPriceStart + priceChange; 
      } else {
        return mintPriceEnd;
      }
    }
  }

  function _pay(address from, uint256 amount) internal {
    require(block.timestamp >= mintStart && block.timestamp <= mintEnd, "Not started");

    if (mintPriceStart > 0 || mintPriceEnd > 0) {
      uint256 price = mintPrice();
      mintTokenAddress.transferFrom(from, fundAddress, price * amount);
    }
  }

  function mint(address to, uint256 amount) public onlyMinter(msg.sender) {
    _pay(msg.sender, amount);
    _mintInternal(to, amount);
  }

  function checkMerkle(address toCheck, bytes32[] calldata proof) public view returns(bool) {
    return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(toCheck)));
  }

  function mintMerkle(address to, uint256 amount, bytes32[] calldata proof) public {
    require(checkMerkle(to, proof), "Not whitelisted");
    _pay(msg.sender, amount);
    _mintInternal(to, amount);
  }

  function mintSignature(
    address operatorAddress,
    uint256 nonce,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV,
    bytes memory payload
  ) public 
    onlyMinter(operatorAddress)
    verifyMetaTransaction(
      operatorAddress,
      payload,
      nonce,
      sigR,
      sigS,
      sigV
    )
  {
    (address to, uint256 amount) = abi.decode(payload, (address, uint256));
    _pay(msg.sender, amount);
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