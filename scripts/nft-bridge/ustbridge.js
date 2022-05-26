// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { cloneDeep } = require('lodash');
const data = cloneDeep(require("./data.json"));
const fs = require('fs')

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
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');
  console.log("HARDHAT_NETWORK", process.env.HARDHAT_NETWORK);
  const accounts = await hre.ethers.getSigners();
  const chainId = hre.network.config.chainId;

  console.log('CHAIN', chainId);

  const contracts = {};

  contracts.bridgeAxelar = await deploy("AxelarSeaNftAxelarUSTBridge", data.bridgeController[chainId], data.axelarGateway[chainId], data.axelarGasReceiver[chainId], data.ust[chainId]);

  data.bridgeAxelar[chainId] = contracts.bridgeAxelar.address;

  fs.writeFileSync(__dirname + '/data.json', JSON.stringify(data, undefined, 2));

  return contracts;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = {deploy2048: main};
