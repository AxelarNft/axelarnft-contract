//SPDX-License-Identifier: BUSL
pragma solidity ^0.8.0;

import "./IAxelarSeaNftInitializable.sol";
import "../meta-transactions/NativeMetaTransaction.sol";
import "../meta-transactions/ContextMixin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AxelarSeaProjectRegistry is Ownable, NativeMetaTransaction, ContextMixin, ReentrancyGuard {
  using SafeERC20 for IERC20;

  mapping(address => bool) public operators;
  mapping(address => bool) public templates;
  mapping(address => bool) public axelarSeaContract;

  mapping(bytes32 => address) public projectOwner;
  mapping(address => bytes32) public nftProject;

  // 1 = Member, 2 = Admin
  mapping(bytes32 => mapping(address => uint256)) public projectMember;

  // Minting fee
  address public feeAddress;
  uint256 public baseMintFee = 0.02 ether;

  string public baseContractURI = "https://api-nftdrop.axelarsea.com/contractMetadata/";
  string public baseTokenURI = "https://api-nftdrop.axelarsea.com/tokenMetadata/";

  constructor() {
    feeAddress = msg.sender;
  }

  modifier onlyOperator {
    require(operators[msgSender()], "Not Operator");
    _;
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
  function newProject(address owner, bytes32 projectId) public onlyOperator {
    projectOwner[projectId] = owner;
    projectMember[projectId][owner] = 2;

    emit NewProject(owner, projectId);
  }

  event SetProjectMember(bytes32 indexed projectId, address indexed member, uint256 level);
  function setProjectMember(bytes32 projectId, address member, uint256 level) public {
    require(projectMember[projectId][member] == 2 && member != projectOwner[projectId], "Forbidden");
    projectMember[projectId][member] = level;
    emit SetProjectMember(projectId, member, level);
  }

  // Only linkable if that NFT implement Ownable
  event LinkProject(address indexed contractAddress, bytes32 projectId);
  function linkProject(address contractAddress, bytes32 projectId) public {
    // Check support interface
    require(IERC165(contractAddress).supportsInterface(0x80ac58cd) || IERC165(contractAddress).supportsInterface(0xd9b67a26), "Not NFT");

    address owner = Ownable(contractAddress).owner();

    require(owner != address(0) && owner == projectOwner[projectId], "Not owner");

    nftProject[contractAddress] = projectId;

    emit LinkProject(contractAddress, projectId);
  }

  event DeployNft(address indexed template, address indexed owner, address indexed contractAddress, bytes32 collectionId, bytes32 projectId);
  function deployNft(
    address template,
    address owner,
    bytes32 collectionId,
    bytes32 projectId,
    string memory name,
    string memory symbol,
    bytes memory data
  ) public onlyOperator {
    IAxelarSeaNftInitializable nft = IAxelarSeaNftInitializable(Clones.clone(template));
    nft.initialize(owner, collectionId, projectId, name, symbol, data);
    linkProject(address(nft), projectId);
    emit DeployNft(template, owner, address(nft), collectionId, projectId);
  }

  function setBaseContractURI(string memory _uri) public onlyOwner {
    baseContractURI = _uri;
  }

  function setBaseTokenURI(string memory _uri) public onlyOwner {
    baseTokenURI = _uri;
  }
}