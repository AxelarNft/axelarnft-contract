// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../lib/SafeTransferLib.sol";
import "../lib/RevertReason.sol";
import "./AxelarSeaPGError.sol";

interface IAxelarSeaMetaWalletFactoryOperator {
  function operator(address op) external view returns(bool);
}

contract AxelarSeaMetaWallet is Initializable, IERC721Receiver, IERC1155Receiver {
  using SafeTransferLib for IERC20;

  // Not allowed to change the owner
  address public owner;
  address public factory;

  function initialize(
    address _owner
  ) public initializer {
    factory = msg.sender;
    owner = _owner;
  }

  modifier onlyOperator(address op) {
    if (op != owner && !IAxelarSeaMetaWalletFactoryOperator(factory).operator(op)) {
      revert NotOperator();
    }

    _;
  }

  modifier onlyOwner {
    if (msg.sender != owner) {
      revert NotOwner();
    }

    _;
  }

  function execute(address target, uint256 value, bytes calldata payload) public onlyOperator(msg.sender) returns(bytes memory) {
    (bool success, bytes memory data) = target.call{value: value}(payload);

    if (!success) {
      // Revert and pass reason along if one was returned.
      RevertReason.revertWithReasonIfOneIsReturned();

      // Otherwise, revert with a generic error message.
      revert LowLevelCallFailed();
    }
    
    return data;
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
    return (
      interfaceId == type(IERC1155Receiver).interfaceId ||
      interfaceId == type(IERC721Receiver).interfaceId
    );
  }

  /**
    * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
    * by `operator` from `from`, this function is called.
    *
    * It must return its Solidity selector to confirm the token transfer.
    * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
    *
    * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
    */
  function onERC721Received(
    address,
    address,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    IERC721(msg.sender).safeTransferFrom(address(this), owner, tokenId, data);
    return IERC721Receiver.onERC721Received.selector;
  }

  /**
    * @dev Handles the receipt of a single ERC1155 token type. This function is
    * called at the end of a `safeTransferFrom` after the balance has been updated.
    *
    * NOTE: To accept the transfer, this must return
    * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * (i.e. 0xf23a6e61, or its own function selector).
    *
    * @param operator The address which initiated the transfer (i.e. msg.sender)
    * @param from The address which previously owned the token
    * @param id The ID of the token being transferred
    * @param amount The amount of tokens being transferred
    * @param data Additional data with no specified format
    * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external returns (bytes4) {
    operator;
    from;

    IERC1155(msg.sender).safeTransferFrom(address(this), owner, id, amount, data);

    return IERC1155Receiver.onERC1155Received.selector;
  }

  /**
    * @dev Handles the receipt of a multiple ERC1155 token types. This function
    * is called at the end of a `safeBatchTransferFrom` after the balances have
    * been updated.
    *
    * NOTE: To accept the transfer(s), this must return
    * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * (i.e. 0xbc197c81, or its own function selector).
    *
    * @param operator The address which initiated the batch transfer (i.e. msg.sender)
    * @param from The address which previously owned the token
    * @param ids An array containing ids of each token being transferred (order and length must match values array)
    * @param values An array containing amounts of each token being transferred (order and length must match ids array)
    * @param data Additional data with no specified format
    * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4) {
    operator;
    from;

    IERC1155(msg.sender).safeBatchTransferFrom(address(this), owner, ids, values, data);

    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }

  function recoverETH(uint256 amount) external onlyOwner {
    SafeTransferLib.safeTransferETH(msg.sender, amount);
  }

  function recoverERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.safeTransfer(msg.sender, amount);
  }

  function recoverERC721(IERC721 token, uint256 tokenId, bytes calldata data) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, data);
  }

  function recoverERC1155(IERC1155 token, uint256 tokenId, uint256 amount, bytes calldata data) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, amount, data);
  }
}