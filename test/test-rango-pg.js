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

const AxelarRangoPgMockSourceABI = require("../artifacts/contracts/paymentGateway/AxelarSeaRangoPGMockSource.sol/AxelarSeaRangoPGMockSource.json").abi
const AxelarRangoPgMockDestABI = require("../artifacts/contracts/paymentGateway/AxelarSeaRangoPGMockDest.sol/AxelarSeaRangoPGMockDest.json").abi
const TestERC721ABI = require("../artifacts/contracts/test/TestERC721.sol/TestERC721.json").abi
const AxelarSeaMarketplaceABI = require("../artifacts/contracts/Marketplace.sol/AxelarSeaMarketplace.json").abi

const axelarSeaRangoPgMockSourceInterface = new ethers.utils.Interface(AxelarRangoPgMockSourceABI)
const axelarSeaRangoPgMockDestInterface = new ethers.utils.Interface(AxelarRangoPgMockDestABI)
const testERC721Interface = new ethers.utils.Interface(TestERC721ABI)
const axelarSeaMarketplaceInterface = new ethers.utils.Interface(AxelarSeaMarketplaceABI)

describe(`AxelarSea — Test MetaWallet`, function () {
  const provider = ethers.provider;
  let accounts = [];
  let contracts = {};

  let owner;
  let seller;

  before(async() => {
    accounts = await ethers.getSigners();
    contracts = await deployMetaWallet(true);

    owner = accounts[0];
    seller = accounts[1];

    // Deploy old Marketplace for mock purpose
    contracts.testERC20 = await deployContract("TestERC20", owner);
    contracts.testERC721 = await deployContract("TestERC721", owner);
    contracts.sampleNft = await deployContract("AxelarSeaSampleNft", owner, "Text NFT", "TEST");
    contracts.marketplaceMetaWallet = await deployContract("MarketplaceMetaWallet", owner);
    contracts.marketplace = await deployContract("AxelarSeaMarketplace", owner, contracts.marketplaceMetaWallet.address);

    // console.log(contracts)
  })

  it('Should create order in the marketplace', async () => {
    // Mint money
    await contracts.testERC20.mint(accounts[0].address, ethers.utils.parseEther("1000000000")).then(tx => tx.wait());

    // Mint NFT
    await contracts.sampleNft.connect(seller).mint().then(tx => tx.wait());
    await contracts.sampleNft.connect(seller).mint().then(tx => tx.wait());
    await contracts.sampleNft.connect(seller).mint().then(tx => tx.wait());
    await contracts.sampleNft.connect(seller).mint().then(tx => tx.wait());
    await contracts.sampleNft.connect(seller).mint().then(tx => tx.wait());
    await contracts.sampleNft.connect(seller).mint().then(tx => tx.wait());

    // Approve NFT
    await contracts.sampleNft.connect(seller).setApprovalForAll(contracts.marketplace.address, true).then(tx => tx.wait());

    // List NFT
    await contracts.marketplace.connect(seller).list(contracts.sampleNft.address, 1, 1, contracts.testERC20.address, ethers.utils.parseEther("100")).then(tx => tx.wait());
    await contracts.marketplace.connect(seller).list(contracts.sampleNft.address, 2, 1, contracts.testERC20.address, ethers.utils.parseEther("100")).then(tx => tx.wait());
    await contracts.marketplace.connect(seller).list(contracts.sampleNft.address, 3, 1, contracts.testERC20.address, ethers.utils.parseEther("100")).then(tx => tx.wait());
    await contracts.marketplace.connect(seller).list(contracts.sampleNft.address, 4, 1, contracts.testERC20.address, ethers.utils.parseEther("100")).then(tx => tx.wait());
  });

  it('Should be able to accept fund and perform cross-chain swap with rango and mint NFT', async () => {
    // Must be tested 3 times to confirm
    for (let i = 1; i <= 3; i++) {
      // Approve to payment gateway
      await contracts.testERC20.approve(contracts.axelarSeaRangoPg.address, ethers.utils.parseEther("1000000000")).then(tx => tx.wait());

      const bridgeAmount = ethers.utils.parseEther("100");
      const mintTestERC721Signature = testERC721Interface.encodeFunctionData("mintToSender", [i]);

      const appMessage = ethers.utils.AbiCoder.prototype.encode(["tuple(address,address,bytes)"], [[owner.address, contracts.testERC721.address, mintTestERC721Signature]])

      const stealTokenSignature = axelarSeaRangoPgMockSourceInterface.encodeFunctionData("stealToken", [
        ethers.utils.defaultAbiCoder.encode(["address", "uint256", "bytes"], [contracts.testERC20.address, bridgeAmount, appMessage])
      ]);

      await contracts.axelarSeaRangoPg.buyNFTCrosschain(contracts.testERC20.address, bridgeAmount, stealTokenSignature).then(tx => tx.wait());

      // Unlock NFT on the destination chain
      await contracts.testERC20.mint(contracts.axelarSeaRangoPgMockDest.address, bridgeAmount).then(tx => tx.wait());
      await contracts.axelarSeaRangoPgMockDest.mockMessage(contracts.testERC20.address, bridgeAmount, 0, appMessage).then(tx => tx.wait());
    }
  });

  it('Should be able to accept fund and perform cross-chain swap with rango and buy NFT', async () => {
    const metaWallet = await contracts.axelarSeaMetaWalletFactory.metaWalletAddress(owner.address);

    // Must be tested 3 times to confirm
    for (let i = 1; i <= 3; i++) {
      // Approve to payment gateway
      await contracts.testERC20.approve(contracts.axelarSeaRangoPg.address, ethers.utils.parseEther("1000000000")).then(tx => tx.wait());

      const bridgeAmount = ethers.utils.parseEther("100");

      // Note: in testing we test transferring to metawallet to test capability with any other marketplaces
      const buySignature = axelarSeaMarketplaceInterface.encodeFunctionData("buyERC721", [metaWallet, contracts.sampleNft.address, seller.address, i]);

      const appMessage = ethers.utils.AbiCoder.prototype.encode(["tuple(address,address,bytes)"], [[owner.address, contracts.marketplace.address, buySignature]])

      const stealTokenSignature = axelarSeaRangoPgMockSourceInterface.encodeFunctionData("stealToken", [
        ethers.utils.defaultAbiCoder.encode(["address", "uint256", "bytes"], [contracts.testERC20.address, bridgeAmount, appMessage])
      ]);

      await contracts.axelarSeaRangoPg.buyNFTCrosschain(contracts.testERC20.address, bridgeAmount, stealTokenSignature).then(tx => tx.wait());

      // Unlock NFT on the destination chain
      await contracts.testERC20.mint(contracts.axelarSeaRangoPgMockDest.address, bridgeAmount).then(tx => tx.wait());
      await contracts.axelarSeaRangoPgMockDest.mockMessage(contracts.testERC20.address, bridgeAmount, 0, appMessage).then(tx => tx.wait());
    }
  });
});