//SPDX-License-Identifier: BUSL
pragma solidity ^0.8.0;

import "./lib/IAxelarSeaNftInitializable.sol";
import "../meta-transactions/NativeMetaTransaction.sol";
import "../meta-transactions/ContextMixin.sol";
import "../lib/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./lib/AxelarSeaMintingErrors.sol";

contract AxelarSeaProjectRegistry is OwnableUpgradeable, NativeMetaTransaction, ContextMixin, ReentrancyGuardUpgradeable {
  using SafeTransferLib for IERC20;

  mapping(address => bool) public operators;
  mapping(address => bool) public templates;
  mapping(address => bool) public minterTemplates;
  mapping(address => bool) public axelarSeaContract;

  mapping(bytes32 => address) public projectOwner;
  mapping(address => bytes32) public nftProject;

  // 1 = Member, 2 = Admin
  mapping(bytes32 => mapping(address => uint256)) public projectMember;

  // Collection ID -> contract address
  mapping(bytes32 => address) public collectionMapping;

  // Minting fee
  address public feeAddress;
  uint256 public baseMintFee;

  string public baseContractURI;
  string public baseTokenURI;

  // Deployment fee
  address public newProjectFeeAddress;
  uint256 public newProjectFeeAmount;

  address public newCollectionFeeAddress;
  uint256 public newCollectionFeeAmount;

  // Best practice to leave room for more variable if upgradeable
  uint256[200] private __GAP;

  function initialize() public initializer {
    baseMintFee = 0.02 ether; // 2%
    baseContractURI = "https://api-nftdrop.axelarsea.com/contractMetadata/"; // TODO
    baseTokenURI = "https://api-nftdrop.axelarsea.com/tokenMetadata/"; // TODO

    feeAddress = msg.sender;
    _initializeEIP712("AxelarSeaProjectRegistry");

    __Ownable_init();
    __ReentrancyGuard_init();
  }

  modifier onlyOperator {
    require(operators[msgSender()], "Not Operator");
    _;
  }

  event SetNewProjectFee(address indexed token, uint256 fee);
  function setNewProjectFee(address token, uint256 fee) public onlyOwner {
    newProjectFeeAddress = token;
    newProjectFeeAmount = fee;
    emit SetNewProjectFee(token, fee);
  }

  event SetNewCollectionFee(address indexed token, uint256 fee);
  function setNewCollectionFee(address token, uint256 fee) public onlyOwner {
    newCollectionFeeAddress = token;
    newCollectionFeeAmount = fee;
    emit SetNewCollectionFee(token, fee);
  }

  event SetMintFee(address indexed addr, uint256 fee);
  function setMintFee(address addr, uint256 fee) public onlyOwner {
    require(fee <= 1 ether, "Too much fee");
    feeAddress = addr;
    baseMintFee = fee;
    emit SetMintFee(addr, fee);
  }

  event SetOperator(address indexed operator, bool enabled);
  function setOperator(address operator, bool enabled) public onlyOwner {
    operators[operator] = enabled;
    emit SetOperator(operator, enabled);
  }

  event SetMinterTemplate(address indexed template, bool enabled);
  function setMinterTemplate(address template, bool enabled) public onlyOwner {
    minterTemplates[template] = enabled;
    emit SetMinterTemplate(template, enabled);
  }

  event SetTemplate(address indexed template, bool enabled);
  function setTemplate(address template, bool enabled) public onlyOwner {
    templates[template] = enabled;
    emit SetTemplate(template, enabled);
  }

  event SetAxelarSeaContract(address indexed addr, bool enabled);
  function setAxelarSeaContract(address addr, bool enabled) public onlyOwner {
    axelarSeaContract[addr] = enabled;
    emit SetAxelarSeaContract(addr, enabled);
  }

  event NewProject(address indexed owner, bytes32 projectId);
  function _newProject(address owner, bytes32 projectId) public onlyOperator {
    projectOwner[projectId] = owner;
    projectMember[projectId][owner] = 2;

    // New project fee only paid once per chain
    if (newProjectFeeAddress != address(0) && newProjectFeeAmount > 0) {
      IERC20(newProjectFeeAddress).safeTransferFrom(msgSender(), address(this), newProjectFeeAmount);
    }

    emit NewProject(owner, projectId);
  }

  function newProject(address owner, bytes32 projectId) public onlyOperator {
    if (owner == address(0)) revert Forbidden();
    _newProject(owner, projectId);
  }

  event SetProjectMember(bytes32 indexed projectId, address indexed member, uint256 level);
  function setProjectMember(bytes32 projectId, address member, uint256 level) public {
    // Invalid level || Not admin || Change owner || Invalid project -> Forbidden || Invalid member -> Forbidden
    if(level > 2 || projectMember[projectId][msgSender()] != 2 || member == projectOwner[projectId] || projectOwner[projectId] == address(0) || member == address(0)) revert Forbidden();
    projectMember[projectId][member] = level;
    emit SetProjectMember(projectId, member, level);
  }

  event SetProjectOwner(bytes32 indexed projectId, address indexed owner);
  function setProjectOwner(bytes32 projectId, address owner) public {
    // Not owner || New member not admin || Invalid project || Invalid owner -> Forbidden
    if(msgSender() != projectOwner[projectId] || projectMember[projectId][owner] != 2 || projectOwner[projectId] == address(0) || owner == address(0)) revert Forbidden();
    projectOwner[projectId] = owner;
    emit SetProjectOwner(projectId, owner);
  }

  // Only linkable if that NFT implement Ownable
  event LinkProject(address indexed contractAddress, bytes32 projectId);
  function _linkProject(address contractAddress, bytes32 projectId) internal {
    address owner = Ownable(contractAddress).owner();

    // If no owner || owner of nft is not a member of project -> Forbidden
    if(owner == address(0) || projectMember[projectId][owner] == 0) revert Forbidden();

    nftProject[contractAddress] = projectId;

    emit LinkProject(contractAddress, projectId);
  }

  function linkProject(address contractAddress, bytes32 projectId) public nonReentrant {
    // Check support interface
    require(IERC165(contractAddress).supportsInterface(0x80ac58cd) || IERC165(contractAddress).supportsInterface(0xd9b67a26), "Not NFT");

    _linkProject(contractAddress, projectId);
  }

  event DeployNft(address indexed template, address indexed owner, address indexed contractAddress, bytes32 collectionId, bytes32 projectId);
  function deployNft(
    address template,
    address owner,
    bytes32 collectionId,
    bytes32 projectId,
    uint256 exclusiveLevel,
    uint256 maxSupply,
    string memory name,
    string memory symbol
  ) public onlyOperator nonReentrant returns(IAxelarSeaNftInitializable nft) {
    if (!templates[template]) {
      revert InvalidTemplate(template);
    }

    if (collectionMapping[collectionId] != address(0)) {
      revert DuplicatedCollection(collectionId);
    }

    // Collection deployment fee
    if (newCollectionFeeAddress != address(0) && newCollectionFeeAmount > 0) {
      IERC20(newCollectionFeeAddress).safeTransferFrom(msgSender(), address(this), newCollectionFeeAmount);
    }

    nft = IAxelarSeaNftInitializable(Clones.clone(template));
    nft.initialize(owner, collectionId, exclusiveLevel, maxSupply, name, symbol);

    if (projectOwner[projectId] == address(0)) {
      _newProject(owner, projectId);
    }
    
    _linkProject(address(nft), projectId);

    collectionMapping[collectionId] = address(nft);

    emit DeployNft(template, owner, address(nft), collectionId, projectId);
  }

  function deployNftWithMinter(
    address template,
    address minterTemplate,
    address owner,
    bytes32 collectionId,
    bytes32 projectId,
    uint256 exclusiveLevel,
    uint256 maxSupply,
    string memory name,
    string memory symbol,
    bytes memory data
  ) public onlyOperator nonReentrant returns(IAxelarSeaNftInitializable nft, IAxelarSeaMinterInitializable minter) {
    if (!templates[template]) {
      revert InvalidTemplate(template);
    }

    if (!minterTemplates[minterTemplate]) {
      revert InvalidTemplate(minterTemplate);
    }
  
    if (collectionMapping[collectionId] != address(0)) {
      revert DuplicatedCollection(collectionId);
    }

    // Collection deployment fee
    if (newCollectionFeeAddress != address(0) && newCollectionFeeAmount > 0) {
      IERC20(newCollectionFeeAddress).safeTransferFrom(msgSender(), address(this), newCollectionFeeAmount);
    }

    nft = IAxelarSeaNftInitializable(Clones.clone(template));
    nft.initialize(owner, collectionId, exclusiveLevel, maxSupply, name, symbol);

    if (projectOwner[projectId] == address(0)) {
      _newProject(owner, projectId);
    }
    
    _linkProject(address(nft), projectId);

    minter = nft.deployMinter(minterTemplate, data);

    collectionMapping[collectionId] = address(nft);

    emit DeployNft(template, owner, address(nft), collectionId, projectId);
  }

  function setBaseContractURI(string memory _uri) public onlyOwner {
    baseContractURI = _uri;
  }

  function setBaseTokenURI(string memory _uri) public onlyOwner {
    baseTokenURI = _uri;
  }
}