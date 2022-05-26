//SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.0;

contract HelloWorld {
  uint256 private counter = 0;

  function hello() public {
    unchecked {
      counter++;
    }
  }
}