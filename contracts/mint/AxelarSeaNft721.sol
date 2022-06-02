//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../meta-transactions/MetaTransactionVerifier.sol";
import "./IAxelarSeaNftInitializable.sol";

import "./AxelarSeaProjectRegistry.sol";

contract AxelarSeaNft721 is Ownable, ERC721Enumerable, MetaTransactionVerifier, IAxelarSeaNftInitializable {
  using Strings for uint256;

  bool private initialized;

  AxelarSeaProjectRegistry public registry;
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
  uint256 public maxSupply;

  mapping(address => bool) public exclusiveContract;
  mapping(address => bool) public minters;
  mapping(address => uint256) public walletMinted;

  uint256 public mintFeeOverride = 0;
  bool public enableMintFeeOverride = false;

  modifier onlyMinter(address addr) {
    require(minters[addr], "Forbidden");
    _;
  }

  constructor() ERC721("_", "_") {}

  event UpdateConfig(
    bytes32 indexed collectionId,
    bytes32 indexed projectId,
    uint256 exclusiveLevel,
    bytes32 merkleRoot,
    uint256 mintPerWalletAddress,
    uint256 mintPriceStart,
    uint256 mintPriceEnd,
    uint256 mintPriceStep,
    IERC20 mintTokenAddress,
    uint256 mintStart,
    uint256 mintEnd,
    uint256 maxSupply
  );
  function updateConfig(
    bytes32 _merkleRoot,
    uint256 _mintPerWalletAddress,
    uint256 _mintPriceStart,
    uint256 _mintPriceEnd,
    uint256 _mintPriceStep,
    IERC20 _mintTokenAddress,
    uint256 _mintStart,
    uint256 _mintEnd,
    uint256 _maxSupply
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
    maxSupply = _maxSupply;

    emit UpdateConfig(
      collectionId,
      projectId,
      exclusiveLevel,
      _merkleRoot,
      _mintPerWalletAddress,
      _mintPriceStart,
      _mintPriceEnd,
      _mintPriceStep,
      _mintTokenAddress,
      _mintStart,
      _mintEnd,
      _maxSupply
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

    initialized = true;
    registry = AxelarSeaProjectRegistry(msg.sender);
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
      uint256 _mintEnd,
      uint256 _maxSupply
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
      _mintEnd,
      _maxSupply
    );
  }

  event SetMinter(address indexed minter, bool enabled);
  function setMinter(address minter, bool enabled) public onlyOwner {
    minters[minter] = enabled;
    emit SetMinter(minter, enabled);
  }

  event SetExclusiveContract(address indexed addr, bool enabled);
  function setExclusiveContract(address addr, bool enabled) public {
    require(msg.sender == owner() || registry.operators(msg.sender), "Forbidden");
    exclusiveContract[addr] = enabled;
    emit SetExclusiveContract(addr, enabled);
  }

  event OverrideMintFee(address indexed overrider, uint256 newFee, bool overrided);
  function overrideMintFee(uint256 newFee, bool overrided) public {
    require(registry.operators(msg.sender), "Forbidden");
    enableMintFeeOverride = overrided;
    mintFeeOverride = newFee;
    emit OverrideMintFee(msg.sender, newFee, overrided);
  }

  function _beforeTokenTransfer(
    address,
    address,
    uint256
  ) internal override {
    require(exclusiveLevel < 2, "Soulbound");
    require(exclusiveLevel < 1 || registry.axelarSeaContract(msg.sender) || exclusiveContract[msg.sender], "Forbidden");
  }

  function _mintInternal(address to, uint256 amount) internal {
    walletMinted[to] += amount;
    require(walletMinted[to] <= mintPerWalletAddress, "Mint Limited");

    uint256 supply = totalSupply();
    require(supply + amount <= maxSupply, "Supply maxed");

    unchecked {
      if (amount == 1) {
        _safeMint(to, supply + 1);
      } else {
        for (uint256 i = 1; i <= amount; i++) {
          _safeMint(to, supply + i);
        }
      }
    }
  }

  function mintFee() public view returns(uint256) {
    return (enableMintFeeOverride ? mintFeeOverride : registry.baseMintFee());
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
      uint256 totalPrice = mintPrice() * amount;
      uint256 fee = totalPrice * mintFee() / 1e18;

      mintTokenAddress.transferFrom(from, registry.feeAddress(), fee);
      mintTokenAddress.transferFrom(from, fundAddress, totalPrice - fee);
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

  // Opensea standard contractURI
  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked(registry.baseContractURI(), uint256(collectionId).toHexString()));
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(registry.baseTokenURI(), uint256(collectionId).toHexString(), "/", tokenId.toString()));
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