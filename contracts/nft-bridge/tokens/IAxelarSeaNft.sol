//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAxelarSeaNft {
  function unlock(address to, uint256 tokenId, uint256 amount) external;
  function lock(address from, uint256 tokenId, uint256 amount) external;
}