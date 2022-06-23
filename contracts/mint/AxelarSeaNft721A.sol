//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./AxelarSeaNftBase.sol";

contract AxelarSeaNft721A is ERC721AQueryable, AxelarSeaNftBase {
  constructor() ERC721A("_", "_") {}

  function _mintInternal(address to, uint256 maxAmount, uint256 amount) internal override {
    walletMinted[to] += amount;
    require(walletMinted[to] <= maxAmount, "Mint Limited");

    uint256 supply = totalSupply();
    require(supply + amount <= maxSupply, "Supply maxed");

    _safeMint(to, amount);
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721A) {
    AxelarSeaNftBase._beforeTokenTransferCheck(from);
    super.transferFrom(from, to, tokenId);
  }

  function exists(uint256 tokenId) public override view returns(bool) {
    return _exists(tokenId);
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view override(AxelarSeaNftBase, ERC721A) virtual returns (string memory) {
    return AxelarSeaNftBase.tokenURI(tokenId);
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view override(AxelarSeaNftBase, ERC721A) virtual returns (string memory) {
    return AxelarSeaNftBase.name();
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view override(AxelarSeaNftBase, ERC721A) virtual returns (string memory) {
    return AxelarSeaNftBase.symbol();
  }
}