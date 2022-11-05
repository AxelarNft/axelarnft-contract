//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IAxelarSeaNftInitializable {
  function initialize(
    address owner,
    bytes32 collectionId,
    uint256 exclusiveLevel,
    uint256 maxSupply,
    string memory name, 
    string memory symbol
  ) external;

  function deployMinter(
    address template,
    bytes memory data
  ) external returns(IAxelarSeaMinterInitializable minter);

  function mint(address to, uint256 amount) external;
}

interface IAxelarSeaMinterInitializable {
  function initialize(
    address targetNft,
    address owner,
    bytes memory data
  ) external;
}
