//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IAxelarSeaNftBridge.sol";

import "sgn-v2-contracts/contracts/message/framework/MessageReceiverApp.sol";
import "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import "sgn-v2-contracts/contracts/message/libraries/MsgDataTypes.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageReceiverApp.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";

contract AxelarSeaNftCelerBridge is IAxelarSeaNftBridge, MessageReceiverApp {
  constructor(address _controller, address _msgBus) IAxelarSeaNftBridge(_controller) {
    messageBus = _msgBus;
  }

  struct SiblingData {
    uint128 chainId;
    address bridgeAddress;
  }
  mapping(uint128 => SiblingData) public siblings;

  event AddSibling(uint128 indexed chainId, address indexed bridgeAddress);
  function addSibling(uint128 chainId, address bridgeAddress) public onlyOwner {
    siblings[chainId] = SiblingData({
      chainId: chainId,
      bridgeAddress: bridgeAddress
    });

    emit AddSibling(chainId, bridgeAddress);
  }

  // check fee and call msgbus sendMessage
  function msgBus(
    address _dstBridge,
    uint64 _dstChid,
    bytes memory message
  ) internal {
    IMessageBus(messageBus).sendMessage{value: msg.value}(_dstBridge, _dstChid, message);
  }

  function _bridge(uint128 chainId, address from, bytes calldata payload) override internal {
    require(msg.sender == address(controller), "F");
    msgBus(siblings[chainId].bridgeAddress, uint64(chainId), payload);
  }

  // ===== called by msgbus
  function executeMessage(
    address sender,
    uint64 srcChid,
    bytes memory payload,
    address // executor
  ) external payable override onlyMessageBus returns (ExecutionStatus) {
    require(sender == siblings[uint128(srcChid)].bridgeAddress, "WRONG_SENDER");

    // Low level call with payload
    (bool success, bytes memory returndata) = address(controller).call(payload);

    // TODO: Revert if not success
    require(success, string(returndata));
  }
}