//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "../meta-transactions/MetaTransactionVerifier.sol";
import "./IAxelarSeaNftInitializable.sol";
import "../AxelarSeaProjectRegistry.sol";

import "./AxelarSeaMintingErrors.sol";

// Use Upgradeable for minimal clone pattern but actually is is not upgradeable
abstract contract AxelarSeaNftBase is OwnableUpgradeable, IAxelarSeaNftInitializable, ReentrancyGuardUpgradeable, IERC2981, ERC165 {
  using Strings for uint256;
  using SafeTransferLib for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  bool public newMinterStopped; // default to false

  AxelarSeaProjectRegistry public registry;
  address public fundAddress;

  bytes32 public collectionId;
  string private nftName;
  string private nftSymbol;
  uint256 public exclusiveLevel;
  uint256 public maxSupply;

  mapping(address => bool) public exclusiveContract;
  EnumerableSet.AddressSet private minters;
  mapping(address => uint256) public walletMinted;

  uint256 public mintFeeOverride; // default to 0
  bool public enableMintFeeOverride; // default to false

  string public baseTokenUriPrefix;
  string public baseTokenUriSuffix;

  address public royaltyReceiver;
  uint256 public royaltyPercentage;

  modifier onlyMinter(address addr) {
    if (!minters.contains(addr)) revert Forbidden();
    _;
  }

  modifier onlyOwnerOrProjectRegistry() {
    if (msg.sender != owner() && msg.sender != address(registry)) {
      revert Forbidden();
    }
    _;
  }

  function initialize(
    address owner,
    bytes32 _collectionId,
    uint256 _exclusiveLevel,
    uint256 _maxSupply,
    string memory _nftName,
    string memory _nftSymbol
  ) public initializer {
    registry = AxelarSeaProjectRegistry(msg.sender);
    collectionId = _collectionId;
    exclusiveLevel = _exclusiveLevel;
    maxSupply = _maxSupply;
    nftName = _nftName;
    nftSymbol = _nftSymbol;

    fundAddress = owner;

    _transferOwnership(owner);
    __ReentrancyGuard_init();
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

    if (enabled) {
      minters.add(minter);
    } else {
      minters.remove(minter);
    }
    
    emit SetMinter(minter, enabled);
  }

  function isMinter(address minter) public view returns(bool) {
    return minters.contains(minter);
  }

  function mintersLength() public view returns(uint256) {
    return minters.length();
  }

  function getMinters(uint256 start, uint256 end) public view returns(address[] memory) {
    uint256 length = end - start;
    address[] memory result = new address[](length);

    unchecked {
      for (uint256 i = 0; i < length; i++) {
        result[i] = minters.at(start + i);
      }
    }

    return result;
  }

  function getAllMinters() public view returns(address[] memory) {
    return getMinters(0, mintersLength());
  }

  function deployMinter(address template, bytes memory data) public onlyOwnerOrProjectRegistry nonReentrant returns(IAxelarSeaMinterInitializable minter) {
    if (!registry.minterTemplates(template)) {
      revert InvalidTemplate(template);
    }

    minter = IAxelarSeaMinterInitializable(Clones.clone(template));
    minter.initialize(address(this), owner(), data);

    minters.add(address(minter));
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
      // Produce human readable message to be easier for debug
      require(exclusiveLevel < 2, "Soulbound");
      require(exclusiveLevel < 1 || registry.axelarSeaContract(msg.sender) || exclusiveContract[msg.sender], "Exclusive to AxelarSea");
    }
  }

  function _mintInternal(address to, uint256 amount) internal virtual;

  function mintFee() public view returns(uint256) {
    return (enableMintFeeOverride ? mintFeeOverride : registry.baseMintFee());
  }

  function mint(address to, uint256 amount) public onlyMinter(msg.sender) nonReentrant {
    _mintInternal(to, amount);
  }

  function setBaseTokenUriPrefix(string memory newPrefix) public onlyOwner {
    baseTokenUriPrefix = newPrefix;
  }

  function setBaseTokenUriSuffix(string memory newSuffix) public onlyOwner {
    baseTokenUriSuffix = newSuffix;
  }

  function recoverETH() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");

    if (!success) {
      revert TransferFailed();
    }
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

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
  }

  /**
    * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
    * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
    */
  function royaltyInfo(uint256, uint256 salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyReceiver;
    royaltyAmount = salePrice * royaltyPercentage / 1e18;
  }

  event SetRoyalty(address indexed receiver, uint256 indexed percentage);
  function setRoyalty(address receiver, uint256 percentage) public onlyOwnerOrProjectRegistry {
    royaltyReceiver = receiver;
    royaltyPercentage = percentage;

    emit SetRoyalty(royaltyReceiver, royaltyPercentage);
  }
}