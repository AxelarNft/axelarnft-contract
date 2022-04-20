//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IAxelarSeaNft.sol";

contract AxelarSeaERC1155 is ERC1155, IAxelarSeaNft {
  address public controller;
  uint256 public nftId;

  modifier onlyController {
    require(msg.sender == controller, "Not Controller");
    _;
  }

  constructor() ERC1155("_") {}

  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked("https://api.axelarsea.com/nftbridge/contractmetadata/", nftId));
  }

  function initialize(
    address _controller,
    uint256 _nftId
  ) public {
    require(controller == address(0), "Initialized");
    
    controller = _controller;
    nftId = _nftId;
  }

  function unlock(address to, uint256 tokenId, uint256 amount) public override onlyController {
    _mint(to, tokenId, amount, "");
  }

  function lock(address from, uint256 tokenId, uint256 amount) public override onlyController {
    _burn(from, tokenId, amount);
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked("https://api.axelarsea.com/nftbridge/tokenmetadata/", nftId, "/", tokenId));
  }
}