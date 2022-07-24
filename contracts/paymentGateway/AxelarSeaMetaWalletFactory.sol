// SPDX-License-Identifier: MIT
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

  // Operator is a contract that can perform any operation on behalf of MetaWallet
  mapping(address => bool) public operators;

  function initialize(address _metaWalletTemplate) public initializer {
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
    if (metaWalletAddress[metaWalletOwner] != address(0)) {
      return metaWalletAddress[metaWalletOwner];
    }

    metaWallet = Clones.clone(metaWalletTemplate);

    AxelarSeaMetaWallet(metaWallet).initialize(metaWalletOwner);

    emit DeployMetaWallet(metaWalletOwner, metaWallet);
  }
}