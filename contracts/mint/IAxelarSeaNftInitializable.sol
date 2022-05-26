//SPDX-License-Identifier: BUSL
pragma solidity ^0.8.0;

interface IAxelarSeaNftInitializable {
  function initialize(
    address owner,
    bytes32 collectionId,
    bytes32 projectId,
    string memory name, 
    string memory symbol,
    bytes memory data
  ) external;
}