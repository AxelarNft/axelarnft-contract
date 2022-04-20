//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../AxelarSeaNftBridgeController.sol";

abstract contract IAxelarSeaNftBridge {
  AxelarSeaNftBridgeController public immutable controller;

  constructor(address _controller) {
    controller = AxelarSeaNftBridgeController(_controller);
  }

  modifier onlyController {
    require(msg.sender == address(controller), "Not Controller");
    _;
  }

  function _bridge(uint256 chainId, bytes calldata payload) virtual internal;
  function bridge(uint256 chainId, bytes calldata payload) public onlyController {
    _bridge(chainId, payload);
  }
}