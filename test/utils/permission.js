const { expect } = require("chai");
const {
  constants,
  utils: { parseEther, keccak256, toUtf8Bytes },
} = require("ethers");

async function testPermission({ contract, fn, authorized, unauthorized, revertMessage }, ...args) {
  await contract.connect(authorized)[fn](...args);

  expect(contract.connect(unauthorized)[fn](...args))
    .to.be.revertedWith(revertMessage)
}

module.exports = { testPermission }