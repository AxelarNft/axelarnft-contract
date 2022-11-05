// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AxelarSeaRangoPG.sol";
import "../lib/SafeTransferLib.sol";

contract AxelarSeaRangoPGMockSource is Ownable {
  using SafeTransferLib for IERC20;

  function stealToken(bytes calldata rangoData) public {
    (address token, uint256 amount, ) = abi.decode(rangoData, (address, uint256, bytes));
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
  }
}