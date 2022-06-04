//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AxelarSeaNftBase.sol";

contract AxelarSeaNft721Enumerable is ERC721Enumerable, AxelarSeaNftBase {
  constructor() ERC721("_", "_") {}

  function _mintInternal(address to, uint256 amount) internal override {
    walletMinted[to] += amount;
    require(walletMinted[to] <= mintPerWalletAddress, "Mint Limited");

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
    address,
    uint256
  ) internal override {
    AxelarSeaNftBase._beforeTokenTransferCheck(from);
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
}