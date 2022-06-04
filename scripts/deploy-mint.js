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

async function main() {
  const ERC721EnumerableTemplate = await deploy("AxelarSeaNft721Enumerable");

  const axelarSeaProjectRegistry = await deploy("AxelarSeaProjectRegistry");

  await axelarSeaProjectRegistry.setTemplate(ERC721EnumerableTemplate.address, true).then(tx => tx.wait());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
