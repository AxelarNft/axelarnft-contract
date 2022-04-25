//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAxelarSeaNftBridge.sol";
import {IAxelarExecutable} from "@axelar-network/axelar-cgp-solidity/src/interfaces/IAxelarExecutable.sol";
import {IAxelarGasReceiver} from "@axelar-network/axelar-cgp-solidity/src/interfaces/IAxelarGasReceiver.sol";

contract AxelarSeaNftAxelarBridge is IAxelarExecutable, IAxelarSeaNftBridge, Ownable {
  IAxelarGasReceiver public immutable gasReceiver;

  constructor(address _controller, address _gateway, address _gasReceiver) IAxelarExecutable(_gateway) IAxelarSeaNftBridge(_controller) {
    gasReceiver = IAxelarGasReceiver(_gasReceiver);
  }

  struct SiblingData {
    uint128 chainId;
    string chainName;
    string bridgeAddress;
  }
  mapping(uint128 => SiblingData) public siblings;
  mapping(bytes32 => uint128) public chainNameLookup;

  event AddSibling(uint128 indexed chainId, string chainName, string bridgeAddress);
  function addSibling(uint128 chainId, string memory chainName, string memory bridgeAddress) public onlyOwner {
    siblings[chainId] = SiblingData({
      chainId: chainId,
      chainName: chainName,
      bridgeAddress: bridgeAddress
    });
    chainNameLookup[keccak256(bytes(chainName))] = chainId;

    emit AddSibling(chainId, chainName, bridgeAddress);
  }

  function _bridgeAxelar(string memory destinationChain, string memory destinationAddress, bytes calldata payload) internal {
    gasReceiver.payNativeGasForContractCall{value: msg.value}(
      address(this),
      destinationChain,
      destinationAddress,
      payload
    );
    gateway.callContract(destinationChain, destinationAddress, payload);
  }

  function _bridge(uint128 chainId, bytes calldata payload) override internal {
    require(msg.sender == address(controller), "F");
    _bridgeAxelar(siblings[chainId].chainName, siblings[chainId].bridgeAddress, payload);
  }

  function _execute(
    string memory sourceChain,
    string memory sourceAddress,
    bytes calldata payload
  ) internal virtual override {
    require(keccak256(bytes(sourceAddress)) == keccak256(bytes(siblings[chainNameLookup[keccak256(bytes(sourceChain))]].bridgeAddress)), "WRONG_SENDER");

    // Low level call with payload
    (bool success, bytes memory returndata) = address(controller).call(payload);

    // Revert if not success
    require(success, string(returndata));
    if (!success) {
      _bridgeAxelar(sourceChain, sourceAddress, payload);
    }
  }

  function _executeWithToken(
    string memory sourceChain,
    string memory sourceAddress,
    bytes calldata payload,
    string memory tokenSymbol,
    uint256 amount
  ) internal virtual override {
    _execute(sourceChain, sourceAddress, payload);
  }
}