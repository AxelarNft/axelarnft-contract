// SPDX-License-Identifier: BUSL
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AxelarSeaRangoPGMock {
  function stealToken(bytes calldata rangoData) public {
    (address token, uint256 amount) = abi.decode(rangoData, (address, uint256));
  }
}