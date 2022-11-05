//SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./tokens/AxelarSeaERC721.sol";
import "./tokens/AxelarSeaERC1155.sol";
import "./tokens/IAxelarSeaNft.sol";

import "./IAxelarSeaNftExecutable.sol";
import "./bridges/IAxelarSeaNftBridge.sol";

contract AxelarSeaNftBridgeController is Ownable, ERC721Holder, ERC1155Holder {
  address public immutable erc721Template;
  address public immutable erc1155template;

  mapping(uint128 => address) public registeredBridge;
  mapping(address => bool) public enabledBridge;

  mapping(address => uint256) public address2nftId;
  mapping(uint256 => address) public nftId2address;
  mapping(uint256 => bool) public isERC721;
  uint128 public nftIdCounter = 1;

  modifier onlyRegisteredBridge(address _bridge) {
    require(enabledBridge[_bridge], "Bridge Forbidden");
    _;
  }

  constructor(
    address _erc721Template,
    address _erc1155template
  ) {
    erc721Template = _erc721Template;
    erc1155template = _erc1155template;
  }

  event EnableBridge(address indexed caller, address indexed bridge, bool enabled);
  function enableBridge(address _bridge, bool enabled) public onlyOwner {
    enabledBridge[_bridge] = enabled;
    emit EnableBridge(msg.sender, _bridge, enabled);
  }

  event RegisterBridge(address indexed caller, uint128 indexed chainId, address indexed bridge);
  function registerBridge(uint128 chainId, address _bridge) public onlyOwner {
    registeredBridge[chainId] = _bridge;
    emit RegisterBridge(msg.sender, chainId, _bridge);

    if (!enabledBridge[_bridge]) {
      enableBridge(_bridge, true);
    }
  }

  function encodeNftId(uint128 chainId, uint128 nftIdPartial) public pure returns(uint256) {
    return uint256(chainId) << 128 | uint256(nftIdPartial);
  }

  function decodeNftId(uint256 nftId) public pure returns(uint128 chainId, uint128 nftIdPartial) {
    nftIdPartial = uint128(nftId);
    chainId = uint128(nftId >> 128);
  }

  event EnableERC721(uint256 indexed nftId, address indexed nftAddress, uint128 indexed chainId);
  event EnableERC1155(uint256 indexed nftId, address indexed nftAddress, uint128 indexed chainId);
  event NewERC721(uint256 indexed nftId, address indexed nftAddress);
  event NewERC1155(uint256 indexed nftId, address indexed nftAddress);
  event Unlock(uint256 indexed nftId, address indexed nftAddress, uint256 indexed tokenId, uint256 amount);

  function unlockWithPayload(
    uint256 nftId,
    uint256 tokenId, 
    uint256 amount,
    string memory from,
    bytes calldata header, // Split for flexibility
    bytes calldata payload
  ) public onlyRegisteredBridge(msg.sender) {
    require(!isERC721[nftId] || amount == 1, "Forbidden");

    uint128 chainId = uint128(nftId >> 128);
    (address to) = abi.decode(header,(address));
    address nft = nftId2address[nftId];

    if (chainId == block.chainid) {
      if (isERC721[nftId]) {
        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
      } else {
        IERC1155(nft).safeTransferFrom(address(this), to, tokenId, amount, "");
      }
    } else {
      IAxelarSeaNft(nft).unlock(to, tokenId, amount);
    }

    IAxelarSeaNftExecutable(to).execute(nft, chainId, nftId, tokenId, amount, from, payload);

    emit Unlock(nftId, nft, tokenId, amount);
  }

  function unlock(
    uint256 nftId,
    uint256 tokenId,
    uint256 amount,
    bytes calldata header // Split for flexibility
  ) public onlyRegisteredBridge(msg.sender) {
    require(!isERC721[nftId] || amount == 1, "Forbidden");

    uint128 chainId = uint128(nftId >> 128);
    (address to) = abi.decode(header,(address));
    address nft = nftId2address[nftId];

    if (chainId == block.chainid) {
      if (isERC721[nftId]) {
        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
      } else {
        IERC1155(nft).safeTransferFrom(address(this), to, tokenId, amount, "");
      }
    } else {
      IAxelarSeaNft(nft).unlock(to, tokenId, amount);
    }

    emit Unlock(nftId, nft, tokenId, amount);
  }

  function deployERC721(uint256 nftId, string memory name, string memory symbol) public onlyRegisteredBridge(msg.sender) {
    uint128 chainId = uint128(nftId >> 128);

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
      isERC721[nftId] = true;

      emit NewERC721(nftId, erc721);
    }
  }

  function deployERC1155(uint256 nftId) public onlyRegisteredBridge(msg.sender) {
    uint128 chainId = uint128(nftId >> 128);

    // Deploy if not available
    if (chainId != block.chainid && nftId2address[nftId] == address(0)) {
      address erc1155 = Clones.cloneDeterministic(erc1155template, bytes32(nftId));
      AxelarSeaERC1155(erc1155).initialize(
        address(this),
        nftId
      );

      address2nftId[erc1155] = nftId;
      nftId2address[nftId] = erc1155;
      isERC721[nftId] = false;

      emit NewERC1155(nftId, erc1155);
    }
  }

  function _newNftId() internal returns(uint256) {
    return encodeNftId(uint128(block.chainid), nftIdCounter++);
  }

  function enable(uint128 chainId, IERC165 nft) public payable {
    uint256 nftId = address2nftId[address(nft)] == 0 ? _newNftId() : address2nftId[address(nft)];

    if (nft.supportsInterface(0x80ac58cd)) {
      IAxelarSeaNftBridge(registeredBridge[chainId]).bridge{value: msg.value}(chainId, msg.sender, abi.encodeWithSelector(
        AxelarSeaNftBridgeController(address(this)).deployERC721.selector,
        nftId,
        ERC721(address(nft)).name(),
        ERC721(address(nft)).symbol()
      ));

      isERC721[nftId] = true;

      emit EnableERC721(nftId, address(nft), chainId);
    } else if (nft.supportsInterface(0xd9b67a26)) {
      IAxelarSeaNftBridge(registeredBridge[chainId]).bridge{value: msg.value}(chainId, msg.sender, abi.encodeWithSelector(
        AxelarSeaNftBridgeController(address(this)).deployERC1155.selector,
        nftId
      ));

      isERC721[nftId] = false;

      emit EnableERC1155(nftId, address(nft), chainId);
    } else {
      revert("Not supported");
    }

    address2nftId[address(nft)] = nftId;
    nftId2address[nftId] = address(nft);
  }

  function _lock(uint256 nftId, uint256 tokenId, uint256 amount) internal {
    require(!isERC721[nftId] || amount == 1, "Forbidden");
    address nft = nftId2address[nftId];

    if (nftId >> 128 == block.chainid) {
      if (isERC721[nftId]) {
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);
      } else {
        IERC1155(nft).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
      }
    } else {
      IAxelarSeaNft(nft).lock(msg.sender, tokenId, amount);
    }
  }

  function bridge(uint128 chainId, uint256 nftId, uint256 tokenId, uint256 amount, bytes calldata header) public payable {
    _lock(nftId, tokenId, amount);

    IAxelarSeaNftBridge(registeredBridge[chainId]).bridge{value: msg.value}(chainId, msg.sender, abi.encodeWithSelector(
      AxelarSeaNftBridgeController(address(this)).unlock.selector,
      nftId,
      tokenId,
      amount,
      header
    ));
  }

  function bridgeWithPayload(uint128 chainId, uint256 nftId, uint256 tokenId, uint256 amount, bytes calldata header, bytes calldata payload) public payable {
    _lock(nftId, tokenId, amount);

    IAxelarSeaNftBridge(registeredBridge[chainId]).bridge{value: msg.value}(chainId, msg.sender, abi.encodeWithSelector(
      AxelarSeaNftBridgeController(address(this)).unlockWithPayload.selector,
      nftId,
      tokenId,
      amount,
      Strings.toHexString(uint160(msg.sender), 20),
      header,
      payload
    ));
  }
}