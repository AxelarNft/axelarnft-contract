// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms))

async function deploy(contractName, ...args) {
  // Deploy contract
  const Contract = await hre.ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  await contract.deployed();
  console.log(contractName + " deployed to:", contract.address);

  await wait(6000);

  return contract;
}

async function deployUpgradeable(contractName, ...args) {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await upgrades.deployProxy(Contract, args, { initializer: 'initialize' });
  console.log(contractName, "deployed to:", contract.address);

  await wait(6000);

  return contract;
}

async function main() {
  const accounts = await hre.ethers.getSigners();
  const chainId = hre.network.config.chainId;

  const ERC721EnumerableTemplate = await deploy("AxelarSeaNft721Enumerable");
  const ERC721ATemplate = await deploy("AxelarSeaNft721A");

  const axelarSeaProjectRegistry = await deployUpgradeable("AxelarSeaProjectRegistry");

  const AxelarSeaNftMerkleMinter = await deploy("AxelarSeaNftMerkleMinter");
  const AxelarSeaNftMerkleMinterNative = await deploy("AxelarSeaNftMerkleMinterNative");
  const AxelarSeaNftSignatureMinter = await deploy("AxelarSeaNftSignatureMinter");
  const AxelarSeaNftSignatureMinterNative = await deploy("AxelarSeaNftSignatureMinterNative");
  const AxelarSeaNftPublicMinter = await deploy("AxelarSeaNftPublicMinter");
  const AxelarSeaNftPublicMinterNative = await deploy("AxelarSeaNftPublicMinterNative");

  await axelarSeaProjectRegistry.setOperator(accounts[0].address, true).then(tx => tx.wait());
  await axelarSeaProjectRegistry.setTemplate(ERC721EnumerableTemplate.address, true).then(tx => tx.wait());
  await axelarSeaProjectRegistry.setTemplate(ERC721ATemplate.address, true).then(tx => tx.wait());

  await axelarSeaProjectRegistry.setMinterTemplate(AxelarSeaNftMerkleMinter.address, true).then(tx => tx.wait());
  await axelarSeaProjectRegistry.setMinterTemplate(AxelarSeaNftMerkleMinterNative.address, true).then(tx => tx.wait());
  await axelarSeaProjectRegistry.setMinterTemplate(AxelarSeaNftSignatureMinter.address, true).then(tx => tx.wait());
  await axelarSeaProjectRegistry.setMinterTemplate(AxelarSeaNftSignatureMinterNative.address, true).then(tx => tx.wait());
  await axelarSeaProjectRegistry.setMinterTemplate(AxelarSeaNftPublicMinter.address, true).then(tx => tx.wait());
  await axelarSeaProjectRegistry.setMinterTemplate(AxelarSeaNftPublicMinterNative.address, true).then(tx => tx.wait());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
