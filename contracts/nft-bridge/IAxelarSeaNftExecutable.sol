//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IAxelarSeaNftExecutable {
  address public immutable controller;

  constructor(address _controller) {
    controller = _controller;
  }

  function execute(
    address tokenAddress,
    uint128 chainId, 
    uint256 nftId, 
    uint256 tokenId, 
    uint256 amount, 
    string memory from, 
    bytes calldata payload
  ) external {
    require(msg.sender == controller, "Controller");
    _execute(tokenAddress, chainId, nftId, tokenId, amount, from, payload);
  }

  function _execute(
    address tokenAddress,
    uint128 chainId, 
    uint256 nftId, 
    uint256 tokenId, 
    uint256 amount, 
    string memory from, 
    bytes calldata payload
  ) internal virtual;
}