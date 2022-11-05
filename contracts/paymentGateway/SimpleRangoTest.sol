// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../lib/SafeTransferLib.sol";
import "./AxelarSeaMetaWalletFactory.sol";

interface IRangoMessageReceiver {
    enum ProcessStatus { SUCCESS, REFUND_IN_SOURCE, REFUND_IN_DESTINATION }

    function handleRangoMessage(
        address _token,
        uint _amount,
        ProcessStatus _status,
        bytes memory _message
    ) external;
}

contract SimpleRangoTest is IRangoMessageReceiver, OwnableUpgradeable {
    using SafeTransferLib for IERC20;

    address payable public rangoContract;

    function initialize(address payable _rangoContract) public initializer {
        rangoContract = _rangoContract;
        __Ownable_init();
    }

    receive() external payable { }

    // Source chain (Likely to be called from a token aggregator)
    function buy(IERC20 token, uint256 amount, bytes calldata rangoData) external payable {
        // 1. Receive fund and approve rango
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeApprove(rangoContract, 0);
        token.safeApprove(rangoContract, amount);

        // 2. Send the money via Rango
        (bool success, bytes memory retData) = rangoContract.call{value: msg.value}(rangoData);
        if (!success) revert(_getRevertMsg(retData));
    }

    // Destination chain
    event HandleRangoMessage(address indexed token, uint amount, uint status, bytes message);
    function handleRangoMessage(
        address _token,
        uint _amount,
        ProcessStatus _status,
        bytes memory _message
    ) external {
        emit HandleRangoMessage(_token, _amount, uint(_status), _message);
    }

    function refundTo(address _to, IERC20 _token, uint256 _amount) internal {
        if (address(_token) == address(0)) {
            refundNativeTo(payable(_to), _amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    function refundNativeTo(address payable _to, uint256 _amount) internal {
        SafeTransferLib.safeTransferETH(_to, _amount);
    }

    function recoverETH() external onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverERC721(IERC721 token, uint256 tokenId, bytes calldata data) external onlyOwner {
        token.safeTransferFrom(address(this), msg.sender, tokenId, data);
    }

    function recoverERC1155(IERC1155 token, uint256 tokenId, uint256 amount, bytes calldata data) external onlyOwner {
        token.safeTransferFrom(address(this), msg.sender, tokenId, amount, data);
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }


}