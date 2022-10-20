//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./lib/AxelarSeaNftBase.sol";

contract AxelarSeaNft721Enumerable is ERC721Enumerable, AxelarSeaNftBase {
  constructor() ERC721("_", "_") {}

  function _mintInternal(address to, uint256 maxAmount, uint256 amount) internal override {
    walletMinted[to] += amount;
    require(walletMinted[to] <= maxAmount, "Mint Limited");

    uint256 supply = totalSupply();
    require(supply + amount <= maxSupply, "Supply maxed");

    unchecked {
      if (amount == 1) {
        _safeMint(to, supply + 1);
      } else {
        for (uint256 i = 1; i <= amount; i++) {
          _safeMint(to, supply + i);
        }
      }
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    AxelarSeaNftBase._beforeTokenTransferCheck(from);
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function exists(uint256 tokenId) public override view returns(bool) {
    return _exists(tokenId);
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view override(AxelarSeaNftBase, ERC721) virtual returns (string memory) {
    return AxelarSeaNftBase.tokenURI(tokenId);
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view override(AxelarSeaNftBase, ERC721) virtual returns (string memory) {
    return AxelarSeaNftBase.name();
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view override(AxelarSeaNftBase, ERC721) virtual returns (string memory) {
    return AxelarSeaNftBase.symbol();
  }

  function _msgSender() internal view override(Context, ContextUpgradeable) virtual returns (address) {
    return ContextUpgradeable._msgSender();
  }

  function _msgData() internal view override(Context, ContextUpgradeable) virtual returns (bytes calldata) {
    return ContextUpgradeable._msgData();
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AxelarSeaNftBase, ERC721Enumerable) returns (bool) {
    return AxelarSeaNftBase.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
  }
}