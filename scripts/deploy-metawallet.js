// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms))

async function deployUpgradeable(contractName, ...args) {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await upgrades.deployProxy(Contract, args, { initializer: 'initialize' });
  console.log(contractName, " deployed to:", contract.address);
  return contract;
}

async function deploy(contractName, ...args) {
  // Deploy contract
  const Contract = await hre.ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  await contract.deployed();
  console.log(contractName + "deployed to:", contract.address);

  return contract;
}

async function main(IS_DEV = false) {
  const accounts = await hre.ethers.getSigners();
  const chainId = hre.network.config.chainId;

  const contracts = {};

  let rangoContract = ""; // TODO

  const axelarSeaMetaWallet = contracts.axelarSeaMetaWallet = await deploy("AxelarSeaMetaWallet");
  const axelarSeaMetaWalletFactory = contracts.axelarSeaMetaWalletFactory = await deployUpgradeable("AxelarSeaMetaWalletFactory", axelarSeaMetaWallet.address);

  // Rango mock
  if (IS_DEV) {
    const axelarSeaRangoPgMockSource = contracts.axelarSeaRangoPgMockSource = await deploy("AxelarSeaRangoPGMockSource");
    rangoContract = axelarSeaRangoPgMockSource.address;
  }

  // Rango payment gateway
  const axelarSeaRangoPg = contracts.axelarSeaRangoPg = await deployUpgradeable("AxelarSeaRangoPG", rangoContract, axelarSeaMetaWalletFactory.address);

  // Rango mock
  if (IS_DEV) {
    const axelarSeaRangoPgMockDest = contracts.axelarSeaRangoPgMockDest = await deploy("AxelarSeaRangoPGMockDest", axelarSeaRangoPg.address);
  }

  return contracts;
}

module.exports = {
  deployMetaWallet: main,
}