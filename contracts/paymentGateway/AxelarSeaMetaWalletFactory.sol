// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./AxelarSeaMetaWallet.sol";

contract AxelarSeaMetaWalletFactory is Ownable {
  address public metaWalletTemplate;

  // Address of AxelarSeaMetaWallet contract for a particular user
  mapping(address => address) public metaWalletAddress;

  // Operator is a contract that can perform any operation on behalf of MetaWallet
  mapping(address => bool) public operators;

  constructor(address _metaWalletTemplate) {
    metaWalletTemplate = _metaWalletTemplate;
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