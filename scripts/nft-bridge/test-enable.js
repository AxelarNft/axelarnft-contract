// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { cloneDeep } = require('lodash');
const data = cloneDeep(require("./data.json"));
const fs = require('fs');
const { ethers } = require("hardhat");

const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms))

async function attach(contractName, address) {
  // Deploy contract
  const Contract = await hre.ethers.getContractFactory(contractName);
  const contract = await Contract.attach(address);
  await contract.deployed();
  console.log(contractName + " attached to:", contract.address);

  // await wait(6000);

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

  contracts.erc721template = await attach("AxelarSeaERC721", data.sampleNft[chainId]);
  // contracts.erc1155template = await attach("AxelarSeaERC1155", data.erc1155template[chainId]);
  contracts.bridgeController = await attach("AxelarSeaNftBridgeController", data.bridgeController[chainId]);
  contracts.bridgeAxelar = await attach("AxelarSeaNftAxelarBridge", data.bridgeAxelar[chainId]);

  // console.log(await contracts.bridgeAxelar.siblings(43113));

  // let iface = new ethers.utils.Interface(ABI);
  // iface.encodeFunctionData(functionName, [param1, param2, ...]);
  // ethers.utils.defaultAbiCoder.encode

  const gasLimit = 300000;

  await contracts.bridgeController.enable(43113, data.sampleNft[chainId], { value: ethers.utils.parseEther("0.01") }).then(tx => tx.wait());
  await contracts.bridgeController.enable(4002, data.sampleNft[chainId], { value: ethers.utils.parseEther("0.01") }).then(tx => tx.wait());
  await contracts.bridgeController.enable(80001, data.sampleNft[chainId], { value: ethers.utils.parseEther("0.01") }).then(tx => tx.wait());
  await contracts.bridgeController.enable(1287, data.sampleNft[chainId], { value: ethers.utils.parseEther("0.01") }).then(tx => tx.wait());
  // await contracts.bridgeController.enable(3, data.sampleNft[chainId], { value: ethers.utils.parseEther("1") }).then(tx => tx.wait());

  // for (let destChainId in data.bridgeAxelar) {
  //   if (destChainId != chainId) {
  //     await contracts.bridgeController.enable(destChainId, data.sampleNft[chainId], { value: ethers.utils.parseEther("0.01") }).then(tx => tx.wait());
  //   }
  // }

  // for (let destChainId in data.bridgeAxelar) {
  //   await contracts.bridgeController.registerBridge(destChainId, data.bridgeAxelar[chainId]).then(tx => tx.wait());
  //   await contracts.bridgeAxelar.addSibling(destChainId, data.axelarChainName[destChainId], data.bridgeAxelar[destChainId]).then(tx => tx.wait());
  // }

  // fs.writeFileSync(__dirname + '/data.json', JSON.stringify(data, undefined, 2));

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
