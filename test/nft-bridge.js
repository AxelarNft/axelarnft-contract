const { expect } = require("chai");
const { ethers } = require("hardhat");

const { createNetwork: createChain, relay, getGasPrice, utils: { deployContract} } = require('@axelar-network/axelar-local-dev');
const { constants: {AddressZero} } = require('ethers');

const AxelarSeaERC721 = require('../artifacts/contracts/nft-bridge/tokens/AxelarSeaERC721.sol/AxelarSeaERC721.json');

const AxelarSeaNftBridgeController = require('../artifacts/contracts/nft-bridge/AxelarSeaNftBridgeController.sol/AxelarSeaNftBridgeController.json');
const AxelarSeaNftAxelarBridge = require('../artifacts/contracts/nft-bridge/bridges/AxelarSeaNftAxelarBridge.sol/AxelarSeaNftAxelarBridge.json');

describe("NFT Bridge", function () {
  it("Should be enabled", async function () {
    // Create two chains and get a funded user for each
    const chain1 = await createChain({ seed: "chain1" });
    const [user1] = chain1.userWallets;
    const chain2 = await createChain({ seed: "chain2" });
    const [user2] = chain2.userWallets;

    // Deploy our template contracts
    const erc721template1 = await deployContract(user1, AxelarSeaERC721, []);
    const erc721template2 = await deployContract(user2, AxelarSeaERC721, []);

    // Deploy our AxelarSeaNftBridgeController contracts
    // const controller1 = await deployContract(user1, AxelarSeaNftBridgeController, [erc721template1.address, chain1.gasReceiver.address]);
    // const controller2 = await deployContract(user2, AxelarSeaNftBridgeController, [chain2.gateway.address, chain2.gasReceiver.address]);

    // // Deploy our AxelarSeaNftAxelarBridge contracts
    // const bridge1 = await deployContract(user1, AxelarSeaNftAxelarBridge, [chain1.gateway.address, chain1.gasReceiver.address]);
    // const bridge2 = await deployContract(user2, AxelarSeaNftAxelarBridge, [chain2.gateway.address, chain2.gasReceiver.address]);

    // const Greeter = await ethers.getContractFactory("Greeter");
    // Greeter.interface
    // const greeter = await Greeter.deploy("Hello, world!");
    // await greeter.deployed();

    // expect(await greeter.greet()).to.equal("Hello, world!");

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});