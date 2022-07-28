// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms))

async function deployUpgradeable(contractName, ...args) {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await upgrades.deployProxy(Contract, ...args, { initializer: 'initialize' });
  console.log(contractName, " deployed to:", contract.address);
  return contract;
}

async function main() {
  const accounts = await hre.ethers.getSigners();
  const chainId = hre.network.config.chainId;

  const axelarSeaMetaWallet = await deployUpgradeable("AxelarSeaMetaWallet", "0x0000000000000000000000000000000000000000");
  const axelarSeaMetaWalletFactory = await deployUpgradeable("AxelarSeaMetaWallet", axelarSeaMetaWallet.address);
  const axelarSeaRangoPg = await deployUpgradeable("AxelarSeaRangoPg", axelarSeaMetaWalletFactory.address);
}