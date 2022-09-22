// SPDX-License-Identifier: BUSL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AxelarSeaMetaWallet.sol";

contract AxelarSeaMetaWalletFactory is OwnableUpgradeable {
  address public metaWalletTemplate;

  // Address of AxelarSeaMetaWallet contract for a particular user
  mapping(address => address) public metaWalletAddress;
  mapping(address => uint256) public metaWalletVersion;
  uint256 public version;

  // Operator is a contract that can perform any operation on behalf of MetaWallet
  mapping(address => bool) public operators;

  // GAP is not neccessary since this contract operate on its own

  function initialize(address _metaWalletTemplate) public initializer {
    version = 1;
    metaWalletTemplate = _metaWalletTemplate;
    __Ownable_init();
  }

  event SetOperator(address indexed operator, bool enabled);
  function setOperator(address operator, bool enabled) external onlyOwner {
    operators[operator] = enabled;
    emit SetOperator(operator, enabled);
  }

  event DeployMetaWallet(address indexed metaWalletOwner, address indexed metaWallet);
  function deployMetaWallet(address metaWalletOwner) public returns(address metaWallet) {
    if (metaWalletAddress[metaWalletOwner] != address(0) && metaWalletVersion[metaWalletOwner] == version) {
      return metaWalletAddress[metaWalletOwner];
    }

    metaWallet = Clones.clone(metaWalletTemplate);

    // AxelarSeaMetaWallet(metaWallet).initialize(metaWalletOwner);

    metaWalletAddress[metaWalletOwner] = metaWallet;
    metaWalletVersion[metaWalletOwner] = version;

    emit DeployMetaWallet(metaWalletOwner, metaWallet);
  }
}