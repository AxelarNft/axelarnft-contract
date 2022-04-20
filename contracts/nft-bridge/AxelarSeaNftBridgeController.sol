//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./tokens/AxelarSeaERC721.sol";
import "./tokens/AxelarSeaERC1155.sol";
import "./tokens/IAxelarSeaNft.sol";

import "./IAxelarSeaNftExecutable.sol";
import "./bridges/IAxelarSeaNftBridge.sol";

contract AxelarSeaNftBridgeController is Ownable {
  address public immutable erc721Template;
  address public immutable erc1155template;

  mapping(uint128 => address) public registeredBridge;

  mapping(address => uint256) public address2nftId; // Clones
  mapping(address => uint256) public nftId721; // Origin
  mapping(address => uint256) public nftId1155; // Origin
  mapping(uint256 => address) public nftId2address;
  uint128 public nftIdCounter = 0;

  modifier onlyRegisteredBridge(address bridge, uint128 chainId) {
    require(registeredBridge[chainId] == bridge, "Bridge Forbidden");
    _;
  }

  constructor(
    address _erc721Template,
    address _erc1155template
  ) {
    erc721Template = _erc721Template;
    erc1155template = _erc1155template;
  }

  event RegisterBridge(address indexed caller, uint128 indexed chainId, address indexed bridge);
  function registerBridge(uint128 chainId, address bridge) public onlyOwner {
    registeredBridge[chainId] = bridge;
    emit RegisterBridge(msg.sender, chainId, bridge);
  }

  function encodeNftId(uint128 chainId, uint128 nftIdPartial) public pure returns(uint256) {
    return chainId << 128 | nftIdPartial;
  }

  function decodeNftId(uint256 nftId) public pure returns(uint128 chainId, uint128 nftIdPartial) {
    nftIdPartial = uint128(nftId);
    chainId = uint128(nftId >> 128);
  }

  event NewERC721(uint256 indexed nftId, address indexed nftAddress);
  event NewERC1155(uint256 indexed nftId, address indexed nftAddress);
  event Unlock(uint256 indexed nftId, address indexed nftAddress, uint256 indexed tokenId, uint256 amount);

  function unlockERC721WithPayload(
    address to, 
    uint128 chainId, 
    uint128 nftIdPartial, 
    uint256 tokenId, 
    uint256 amount, 
    string memory from, 
    bytes calldata payload
  ) public onlyRegisteredBridge(msg.sender, chainId) {
    uint256 nftId = encodeNftId(chainId, nftIdPartial);
    address nft = nftId2address[nftId];

    if (chainId == block.chainid) {
      IERC721(nft).safeTransferFrom(address(this), to, tokenId);
    } else {
      IAxelarSeaNft(nft).unlock(to, tokenId, amount);
    }

    IAxelarSeaNftExecutable(to).execute(nft, chainId, nftId, tokenId, amount, from, payload);
  }

  function unlockERC721(
    address to, 
    uint128 chainId, 
    uint128 nftIdPartial, 
    uint256 tokenId, 
    uint256 amount
  ) public onlyRegisteredBridge(msg.sender, chainId) {
    uint256 nftId = encodeNftId(chainId, nftIdPartial);
    address nft = nftId2address[nftId];

    if (chainId == block.chainid) {
      IERC721(nft).safeTransferFrom(address(this), to, tokenId);
    } else {
      IAxelarSeaNft(nft).unlock(to, tokenId, amount);
    }
  }

  function unlockERC1155WithPayload(
    address to, 
    uint128 chainId, 
    uint128 nftIdPartial, 
    uint256 tokenId, 
    uint256 amount, 
    string memory from, 
    bytes calldata payload
  ) public onlyRegisteredBridge(msg.sender, chainId) {
    uint256 nftId = encodeNftId(chainId, nftIdPartial);
    address nft = nftId2address[nftId];

    if (chainId == block.chainid) {
      IERC1155(nft).safeTransferFrom(address(this), to, tokenId, amount, "");
    } else {
      IAxelarSeaNft(nft).unlock(to, tokenId, amount);
    }

    IAxelarSeaNftExecutable(to).execute(nft, chainId, nftId, tokenId, amount, from, payload);
  }

  function unlockERC1155(
    address to, 
    uint128 chainId, 
    uint128 nftIdPartial, 
    uint256 tokenId, 
    uint256 amount
  ) public onlyRegisteredBridge(msg.sender, chainId) {
    uint256 nftId = encodeNftId(chainId, nftIdPartial);
    address nft = nftId2address[nftId];

    if (chainId == block.chainid) {
      IERC1155(nft).safeTransferFrom(address(this), to, tokenId, amount, "");
    } else {
      IAxelarSeaNft(nft).unlock(to, tokenId, amount);
    }
  }

  function deployERC721(uint128 chainId, uint128 nftIdPartial, string memory name, string memory symbol) public onlyRegisteredBridge(msg.sender, chainId) {
    uint256 nftId = encodeNftId(chainId, nftIdPartial);

    // Deploy if not available
    if (chainId != block.chainid && nftId2address[nftId] == address(0)) {
      address erc721 = Clones.cloneDeterministic(erc721Template, bytes32(nftId));
      AxelarSeaERC721(erc721).initialize(
        address(this),
        nftId,
        name,
        symbol
      );

      address2nftId[erc721] = nftId;
      nftId2address[nftId] = erc721;

      emit NewERC721(nftId, erc721);
    }
  }

  function deployERC1155(uint128 chainId, uint128 nftIdPartial) public onlyRegisteredBridge(msg.sender, chainId) {
    uint256 nftId = encodeNftId(chainId, nftIdPartial);

    // Deploy if not available
    if (chainId != block.chainid && nftId2address[nftId] == address(0)) {
      address erc1155 = Clones.cloneDeterministic(erc721Template, bytes32(nftId));
      AxelarSeaERC1155(erc1155).initialize(
        address(this),
        nftId
      );

      address2nftId[erc1155] = nftId;
      nftId2address[nftId] = erc1155;

      emit NewERC1155(nftId, erc1155);
    }
  }

  function enableERC721(uint128 chainId, ERC721 nft) public {
    require(nft.supportsInterface(0x80ac58cd), "Not ERC721");
    IAxelarSeaNftBridge(registeredBridge[chainId]).bridge(chainId, abi.encodeWithSelector(
      AxelarSeaNftBridgeController(address(this)).deployERC721.selector,
      chainId,
      nftIdCounter++,
      nft.name(),
      nft.symbol()
    ));
  }

  function enableERC1155(uint128 chainId, IERC1155 nft) public {
    require(nft.supportsInterface(0xd9b67a26), "Not ERC1155");
    IAxelarSeaNftBridge(registeredBridge[chainId]).bridge(chainId, abi.encodeWithSelector(
      AxelarSeaNftBridgeController(address(this)).deployERC1155.selector,
      chainId,
      nftIdCounter++
    ));
  }

  function bridgeERC721(uint128 chainId, IERC721 nft, uint256 tokenId) public {
    
  }
}