//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// import "../meta-transactions/MetaTransactionVerifier.sol";
import "./IAxelarSeaNftInitializable.sol";
import "./AxelarSeaProjectRegistry.sol";

import "./AxelarSeaMintingErrors.sol";

abstract contract AxelarSeaNftBase is Ownable, IAxelarSeaNftInitializable, ReentrancyGuard {
  using Strings for uint256;
  using SafeERC20 for IERC20;

  bool private initialized;

  bool public newMinterStopped = false;

  AxelarSeaProjectRegistry public registry;
  address public fundAddress;

  bytes32 public collectionId;
  string private nftName;
  string private nftSymbol;
  uint256 public exclusiveLevel;
  uint256 public maxSupply;

  mapping(address => bool) public exclusiveContract;
  mapping(address => bool) public minters;
  mapping(address => uint256) public walletMinted;

  uint256 public mintFeeOverride = 0;
  bool public enableMintFeeOverride = false;

  string public baseTokenUriPrefix = "";
  string public baseTokenUriSuffix = "";

  modifier onlyMinter(address addr) {
    require(minters[addr], "Forbidden");
    _;
  }

  constructor() {}

  function initialize(
    address owner,
    bytes32 _collectionId,
    uint256 _exclusiveLevel,
    uint256 _maxSupply,
    string memory _nftName,
    string memory _nftSymbol
  ) public {
    require(!initialized, "Initialized");

    initialized = true;
    registry = AxelarSeaProjectRegistry(msg.sender);
    collectionId = _collectionId;
    exclusiveLevel = _exclusiveLevel;
    maxSupply = _maxSupply;
    nftName = _nftName;
    nftSymbol = _nftSymbol;

    fundAddress = owner;

    _transferOwnership(owner);
  }

  event StopNewMinter();
  function stopNewMinter() public onlyOwner {
    newMinterStopped = true;
    emit StopNewMinter();
  }

  event SetMaxSupply(uint256 supply);
  function setMaxSupply(uint256 newSupply) public onlyOwner {
    if (newMinterStopped) {
      revert Forbidden();
    }

    maxSupply = newSupply;
    emit SetMaxSupply(newSupply);
  }

  event SetMinter(address indexed minter, bool enabled);
  function setMinter(address minter, bool enabled) public onlyOwner {
    if (newMinterStopped) {
      revert Forbidden();
    }

    minters[minter] = enabled;
    emit SetMinter(minter, enabled);
  }

  function deployMinter(address template, bytes memory data) public nonReentrant returns(IAxelarSeaMinterInitializable minter) {
    if (msg.sender != owner() && msg.sender != address(registry)) {
      revert Forbidden();
    }

    if (!registry.minterTemplates(template)) {
      revert InvalidTemplate(template);
    }

    minter = IAxelarSeaMinterInitializable(Clones.clone(template));
    minter.initialize(address(this), owner(), data);

    minters[address(minter)] = true;
    emit SetMinter(address(minter), true);
  }

  event SetExclusiveContract(address indexed addr, bool enabled);
  function setExclusiveContract(address addr, bool enabled) public {
    if (msg.sender != owner() && !registry.operators(msg.sender)) {
      revert Forbidden();
    }

    exclusiveContract[addr] = enabled;
    emit SetExclusiveContract(addr, enabled);
  }

  event OverrideMintFee(address indexed overrider, uint256 newFee, bool overrided);
  function overrideMintFee(uint256 newFee, bool overrided) public {
    if (!registry.operators(msg.sender)) {
      revert Forbidden();
    }

    enableMintFeeOverride = overrided;
    mintFeeOverride = newFee;
    emit OverrideMintFee(msg.sender, newFee, overrided);
  }

  function _beforeTokenTransferCheck(address from) internal view {
    if (from != address(0)) {
      require(exclusiveLevel < 2, "Soulbound");
      require(exclusiveLevel < 1 || registry.axelarSeaContract(msg.sender) || exclusiveContract[msg.sender], "Forbidden");
    }
  }

  function _mintInternal(address to, uint256 maxAmount, uint256 amount) internal virtual;

  function mintFee() public view returns(uint256) {
    return (enableMintFeeOverride ? mintFeeOverride : registry.baseMintFee());
  }

  function mint(address to, uint256 maxAmount, uint256 amount) public onlyMinter(msg.sender) nonReentrant {
    _mintInternal(to, maxAmount, amount);
  }

  function setBaseTokenUriPrefix(string memory newPrefix) public onlyOwner {
    baseTokenUriPrefix = newPrefix;
  }

  function setBaseTokenUriSuffix(string memory newSuffix) public onlyOwner {
    baseTokenUriSuffix = newSuffix;
  }

  function recoverETH() external onlyOwner {
    payable(msg.sender).call{value: address(this).balance}("");
  }

  function recoverERC20(IERC20 token) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  function exists(uint256 tokenId) public virtual view returns(bool);

  function projectId() public view returns(bytes32) {
    return registry.nftProject(address(this));
  }

  // Opensea standard contractURI
  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked(registry.baseContractURI(), uint256(collectionId).toHexString()));
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (bytes(baseTokenUriPrefix).length == 0) {
      return string(abi.encodePacked(registry.baseTokenURI(), uint256(collectionId).toHexString(), "/", tokenId.toString()));
    } else {
      return string(abi.encodePacked(baseTokenUriPrefix, tokenId.toString(), baseTokenUriSuffix));
    }
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view virtual returns (string memory) {
      return nftName;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view virtual returns (string memory) {
      return nftSymbol;
  }
}