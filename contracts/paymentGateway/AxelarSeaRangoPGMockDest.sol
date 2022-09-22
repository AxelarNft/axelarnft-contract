// SPDX-License-Identifier: BUSL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AxelarSeaRangoPG.sol";
import "../lib/SafeTransferLib.sol";

contract AxelarSeaRangoPGMockDest is Ownable {
  using SafeTransferLib for IERC20;

  AxelarSeaRangoPG public immutable rangoPg;

  constructor(AxelarSeaRangoPG _rangoPg) {
    rangoPg = _rangoPg;
  }

  function stealToken(bytes calldata rangoData) public {
    (address token, uint256 amount) = abi.decode(rangoData, (address, uint256));
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
  }

  struct AppMessage { 
    address buyer;
    address targetContract;
    bytes payload;
  }

  function mockMessage(
    address _token,
    uint _amount,
    IRangoMessageReceiver.ProcessStatus _status,
    bytes memory _message
  ) public {
    IERC20(_token).safeTransfer(address(rangoPg), _amount);
    rangoPg.handleRangoMessage(_token, _amount, _status, _message);
  }

  function mockAppMessage(
    address _token,
    uint _amount,
    IRangoMessageReceiver.ProcessStatus _status,
    address buyer,
    address targetContract,
    bytes memory payload
  ) public {
    mockMessage(_token, _amount, _status, abi.encode(AppMessage({
      buyer: buyer,
      targetContract: targetContract,
      payload: payload
    })));
  }
}