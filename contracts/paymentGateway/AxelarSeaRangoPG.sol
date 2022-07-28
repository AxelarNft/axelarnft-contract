// SPDX-License-Identifier: BUSL
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

contract AxelarSeaRangoPG is IRangoMessageReceiver, OwnableUpgradeable {
    using SafeTransferLib for IERC20;

    struct AppMessage { 
      address buyer;
      address targetContract;
      bytes payload;
    }
    enum PurchaseType { BOUGHT, SOLD_OUT }
    event NFTPurchaseStatus(uint assetId, address buyer, PurchaseType purchaseType);

    mapping(address => bool) public whitelistedRelayer;
    address payable public rangoContract;
    AxelarSeaMetaWalletFactory public metaWalletFactory;

    function initialize(address payable _rangoContract, AxelarSeaMetaWalletFactory _metaWalletFactory) public initializer {
        rangoContract = _rangoContract;
        metaWalletFactory = _metaWalletFactory;
        __Ownable_init();
    }

    event WhitelistedRelayer(address indexed relayer, bool whitelisted);
    function whitelistRelayer(address relayer, bool whitelisted) public onlyOwner {
        whitelistedRelayer[relayer] = whitelisted;
        emit WhitelistedRelayer(relayer, whitelisted);
    }

    receive() external payable { }

    // Source chain (Likely to be called from a token aggregator)
    function buyNFTCrosschain(IERC20 token, uint256 amount, bytes calldata rangoData) external payable {
        // 1. Receive fund and approve rango
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeApprove(rangoContract, 0);
        token.safeApprove(rangoContract, amount);

        // 2. Send the money via Rango
        (bool success, bytes memory retData) = rangoContract.call{value: msg.value}(rangoData);
        if (!success) revert(_getRevertMsg(retData));
    }

    // Destination chain
    function handleRangoMessage(
        address _token,
        uint _amount,
        ProcessStatus _status,
        bytes memory _message
    ) external {
        AppMessage memory m = abi.decode((_message), (AppMessage));

        if (_status == ProcessStatus.REFUND_IN_SOURCE || _status == ProcessStatus.REFUND_IN_DESTINATION) {
            refundTo(m.buyer, IERC20(_token), _amount);
        } else {
            AxelarSeaMetaWallet metaWallet = AxelarSeaMetaWallet(metaWalletFactory.deployMetaWallet(m.buyer));

            uint256 nativeAmount = _amount;

            if (_token != address(0)) {
                nativeAmount = 0;
                try IERC20(_token).approve(address(metaWallet), _amount) returns(bool) {} catch {
                    IERC20(_token).safeApprove(address(metaWallet), 0);
                    IERC20(_token).safeApprove(address(metaWallet), _amount);
                }
            }

            try metaWallet.executeWithToken{value: nativeAmount}(IERC20(_token), _amount, m.targetContract, m.payload) returns(bytes memory) {}
            catch {
                refundTo(m.buyer, IERC20(_token), _amount);
            }
        }
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