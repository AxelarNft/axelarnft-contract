const { ethers } = require("ethers");
const keccak256 = require("keccak256")
const { MerkleTree } = require('merkletreejs')

const merkleKeyForMint = (address, amount) => {
  return ethers.utils.solidityKeccak256(["address", "uint256"], [address, amount]);
}

const merkleTreeForMint = (addresses, amounts = []) => {
  const zipped = [];

  for (let i = 0; i < addresses.length; i++) {
    zipped.push([addresses[i], amounts[i] || 1]);
  }

  const elements = zipped.map((x) => Buffer.from(
    ethers.utils.solidityKeccak256(["address", "uint256"], [x[0], x[1]]).slice(2),
    "hex"
  ))

  const tree = new MerkleTree(elements, keccak256, { sortPairs: true })

  return tree;
}

module.exports = Object.freeze({
  merkleTreeForMint,
  merkleKeyForMint,
});
