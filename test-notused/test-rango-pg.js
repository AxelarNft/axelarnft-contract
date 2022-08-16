/* eslint-disable no-unused-expressions */
const { expect } = require("chai");
const {
  constants,
  utils: { parseEther, keccak256, toUtf8Bytes },
  Contract,
} = require("ethers");
const { ethers, network, getChainId } = require("hardhat");
const { faucet, whileImpersonating } = require("./utils/impersonate");
const { merkleTreeForMint, merkleKeyForMint } = require("./utils/merkle");
const {
  randomHex,
  random128,
  toAddress,
  toKey,
  convertSignatureToEIP2098,
  getBasicOrderParameters,
  getItemETH,
  toBN,
  randomBN,
  toFulfillment,
  toFulfillmentComponents,
  getBasicOrderExecutions,
  buildResolver,
  buildOrderStatus,
  defaultBuyNowMirrorFulfillment,
  defaultAcceptOfferMirrorFulfillment,
} = require("./utils/encoding");
const { randomInt } = require("crypto");
const {
  fixtureERC20,
  fixtureERC721,
  fixtureERC1155,
  seaportFixture,
} = require("./utils/fixtures");
const { deployContract } = require("./utils/contracts");
const { testPermission } = require("./utils/permission");
const { getBlockTimestamp } = require("./utils/blockTimestamp");
const {
  generateNewProjectSignature,
  generateDeployNftSignature,
  generateDeployNftWithMinterSignature,
} = require("./utils/signature");
const {
  merkleMinterData,
} = require("./utils/minterPayload");

const {
  deployMetaWallet
} = require("../scripts/deploy-metawallet");

describe(`AxelarSea — Test MetaWallet`, function () {
  const provider = ethers.provider;
  let accounts = [];
  let contracts = {};

  before(async() => {
    accounts = await ethers.getSigners();
    contracts = await deployMetaWallet();
    console.log(contracts)
  })

  it('Should pass', async () => {});
});