//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IAxelarSeaNft.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AxelarSeaERC721 is ERC721, IAxelarSeaNft {
  address public controller;
  uint256 public nftId;
  string private nftName;
  string private nftSymbol;

  modifier onlyController {
    require(msg.sender == controller, "Not Controller");
    _;
  }

  constructor() ERC721("_", "_") {}

  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked("https://api.axelarsea.com/nftbridge/sharedmetadata/", Strings.toString(nftId)));
  }

  function initialize(
    address _controller,
    uint256 _nftId,
    string memory _nftName,
    string memory _nftSymbol
  ) public {
    require(controller == address(0), "Initialized");
    
    controller = _controller;
    nftId = _nftId;
    nftName = _nftName;
    nftSymbol = _nftSymbol;
  }

  function unlock(address to, uint256 tokenId, uint256) public override onlyController {
    _safeMint(to, tokenId);
  }

  function lock(address from, uint256 tokenId, uint256) public override onlyController {
    require(ownerOf(tokenId) == from, "Not owner");
    _burn(tokenId);
  }

  function exists(uint256 tokenId) public view returns(bool) {
    return _exists(tokenId);
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked("https://api.axelarsea.com/nftbridge/tokenmetadata/", Strings.toString(nftId), "/", Strings.toString(tokenId)));
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view virtual override returns (string memory) {
      return nftName;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view virtual override returns (string memory) {
      return nftSymbol;
  }
}