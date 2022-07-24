// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../lib/SafeTransferLib.sol";
import "./AxelarSeaMetaWalletFactory.sol";

error NotRegisteredPG();

contract AxelarSeaPGBase is OwnableUpgradeable {
  using SafeTransferLib for IERC20;

  event ExecutionFailed(address indexed target, address indexed metaWallet, address indexed token, uint256 amount, bytes payload, bytes errorMessage);
  event ExecutionSuccess(address indexed target, address indexed metaWallet, address indexed token, uint256 amount, bytes payload, bytes returnData);

  AxelarSeaMetaWalletFactory public metaWalletFactory;
  mapping(address => bool) public registeredPG;

  function initialize(AxelarSeaMetaWalletFactory _metaWalletFactory) public initializer {
    metaWalletFactory = _metaWalletFactory;
    __Ownable_init();
  }

  event SetRegisteredPG(address indexed pg, bool enabled);
  function setRegisteredPG(address pg, bool enabled) external onlyOwner {
    registeredPG[pg] = enabled;
    emit SetRegisteredPG(pg, enabled);
  }

  function handleMessage(
    IERC20 token,
    uint256 amount,
    address buyer,
    address targetContract,
    bytes calldata payload
  ) external returns(bytes memory) {
    if (!registeredPG[msg.sender]) revert NotRegisteredPG();

    uint256 nativeAmount = address(token) == address(0) ? amount : 0;
    AxelarSeaMetaWallet metaWallet = AxelarSeaMetaWallet(metaWalletFactory.deployMetaWallet(buyer));

    if (address(token) != address(0)) {
      token.safeTransferFrom(msg.sender, address(metaWallet), amount);
      metaWallet.approveERC20(token, targetContract, amount);
    }

    (bool success, bytes memory data) = address(metaWallet).call{value: nativeAmount}(abi.encodeWithSelector(AxelarSeaMetaWallet.execute.selector, targetContract, payload));

    try metaWallet.execute{value: nativeAmount}(targetContract, payload) returns(bytes memory returnData) {
      success = true;
      data = returnData;

      emit ExecutionSuccess(targetContract, address(metaWallet), address(0), amount, payload, returnData);
    } catch (bytes memory err) {
      emit ExecutionFailed(targetContract, address(metaWallet), address(0), amount, payload, err);

      
    }
  }
}