const { createNetwork: createChain, relay, getGasPrice, utils: { deployContract} } = require('@axelar-network/axelar-local-dev');
const { constants: {AddressZero}, ethers } = require('ethers');

const AxelarSeaERC721 = require('../build/AxelarSeaERC721.json');
const AxelarSeaERC1155 = require('../build/AxelarSeaERC1155.json');

const AxelarSeaNftBridgeController = require('../build/AxelarSeaNftBridgeController.json');
const AxelarSeaNftAxelarBridge = require('../build/AxelarSeaNftAxelarBridge.json');

function printSeperator() {
  console.log('\n====================================\n');
}

async function deployContractAndLog(user, abi, name, arguments) {
  let contract = await deployContract(user, abi, arguments);
  console.log(name, 'deployed to', contract.address);
  return contract
}

let provider = ethers.getDefaultProvider();

(async () => {
  const chain1 = await createChain({ seed: "chain1" });
  const [user1] = chain1.userWallets;
  const chain2 = await createChain({ seed: "chain2" });
  const [user2] = chain2.userWallets;
  const chain3 = await createChain({ seed: "chain3" });
  const [user3] = chain3.userWallets;

  //Set the gasLimit to 1e6 (a safe overestimate) and get the gas price (this is constant and always 1).
  const gasLimit = 1e6;
  const gasPrice = getGasPrice(chain1, chain2, AddressZero);

  printSeperator();

  // Deploy our template contracts
  const erc721template1 = await deployContractAndLog(user1, AxelarSeaERC721, '1-ERC721', []);
  const erc721template2 = await deployContractAndLog(user2, AxelarSeaERC721, '2-ERC721', []);
  const erc721template3 = await deployContractAndLog(user3, AxelarSeaERC721, '3-ERC721', []);

  const erc1155template1 = await deployContractAndLog(user1, AxelarSeaERC1155, '1-ERC1155', []);
  const erc1155template2 = await deployContractAndLog(user2, AxelarSeaERC1155, '2-ERC1155', []);
  const erc1155template3 = await deployContractAndLog(user3, AxelarSeaERC1155, '3-ERC1155', []);

  // Mint dummy NFT for test
  await erc721template1.initialize(user1.address, 0, '_', '_');
  await erc721template2.initialize(user2.address, 0, '_', '_');
  await erc721template3.initialize(user3.address, 0, '_', '_');
  await erc1155template1.initialize(user1.address, 0);
  await erc1155template2.initialize(user2.address, 0);
  await erc1155template3.initialize(user3.address, 0);

  for (let i = 1; i <= 3; i++) {
    await erc721template1.unlock(user1.address, i, 1);
    await erc721template2.unlock(user2.address, i, 1);
    await erc721template3.unlock(user3.address, i, 1);
    await erc1155template1.unlock(user1.address, i, 10);
    await erc1155template2.unlock(user2.address, i, 10);
    await erc1155template3.unlock(user3.address, i, 10);
  }

  printSeperator();

  // Deploy our AxelarSeaNftBridgeController contracts
  const controller1 = await deployContractAndLog(user1, AxelarSeaNftBridgeController, '1-BridgeController', [erc721template1.address, erc1155template1.address]);
  const controller2 = await deployContractAndLog(user2, AxelarSeaNftBridgeController, '2-BridgeController', [erc721template2.address, erc1155template2.address]);
  const controller3 = await deployContractAndLog(user3, AxelarSeaNftBridgeController, '3-BridgeController', [erc721template3.address, erc1155template3.address]);

  printSeperator();

  // Deploy our AxelarSeaNftAxelarBridge contracts
  const bridge1 = await deployContractAndLog(user1, AxelarSeaNftAxelarBridge, '1-BridgeAxelar', [controller1.address, chain1.gateway.address, chain1.gasReceiver.address]);
  const bridge2 = await deployContractAndLog(user2, AxelarSeaNftAxelarBridge, '2-BridgeAxelar', [controller2.address, chain2.gateway.address, chain2.gasReceiver.address]);
  const bridge3 = await deployContractAndLog(user3, AxelarSeaNftAxelarBridge, '3-BridgeAxelar', [controller3.address, chain3.gateway.address, chain3.gasReceiver.address]);

  await controller1.registerBridge(1, bridge1.address);
  await controller1.registerBridge(2, bridge1.address);
  await controller1.registerBridge(3, bridge1.address);

  await controller2.registerBridge(1, bridge2.address);
  await controller2.registerBridge(2, bridge2.address);
  await controller2.registerBridge(3, bridge2.address);

  await controller3.registerBridge(1, bridge3.address);
  await controller3.registerBridge(2, bridge3.address);
  await controller3.registerBridge(3, bridge3.address);

  await bridge1.addSibling(1, chain1.name, bridge1.address);
  await bridge1.addSibling(2, chain2.name, bridge2.address);
  await bridge1.addSibling(3, chain3.name, bridge3.address);

  await bridge2.addSibling(1, chain1.name, bridge1.address);
  await bridge2.addSibling(2, chain2.name, bridge2.address);
  await bridge2.addSibling(3, chain3.name, bridge3.address);

  await bridge3.addSibling(1, chain1.name, bridge1.address);
  await bridge3.addSibling(2, chain2.name, bridge2.address);
  await bridge3.addSibling(3, chain3.name, bridge3.address);

  console.log(await bridge3.siblings(2));

  printSeperator();

  // Test NFT Linking
  await controller1.enable(2, erc721template1.address, {value: gasLimit * gasPrice}).then((tx) => tx.wait());
  console.log('ERC721 ENABLE FROM CHAIN 1 -> 2');

  await relay();

  const erc721chain1nftId = await controller1.address2nftId(erc721template1.address);
  const erc721chain1address2 = await controller2.nftId2address(erc721chain1nftId);
  const erc721chain1contract2 = new ethers.Contract(erc721chain1address2, AxelarSeaERC721.abi, user2);

  await controller2.enable(3, erc721chain1address2, {value: gasLimit * gasPrice}).then((tx) => tx.wait());
  console.log('ERC721 ENABLE FROM CHAIN 2 -> 3');

  await relay();

  const erc721chain1address3 = await controller3.nftId2address(erc721chain1nftId);
  const erc721chain1contract3 = new ethers.Contract(erc721chain1address3, AxelarSeaERC721.abi, user3);

  console.log('ERC721 LINKED', erc721chain1nftId._hex, erc721template1.address, erc721chain1address2, erc721chain1address3);

  await controller1.enable(2, erc1155template1.address, {value: gasLimit * gasPrice}).then((tx) => tx.wait());
  console.log('ERC1155 ENABLE FROM CHAIN 1 -> 2');

  await relay();

  const erc1155chain1nftId = await controller1.address2nftId(erc1155template1.address);
  const erc1155chain1address2 = await controller2.nftId2address(erc1155chain1nftId);
  const erc1155chain1contract2 = new ethers.Contract(erc1155chain1address2, AxelarSeaERC1155.abi, user2);

  await controller2.enable(3, erc1155chain1address2, {value: gasLimit * gasPrice}).then((tx) => tx.wait());
  console.log('ERC1155 ENABLE FROM CHAIN 2 -> 3');

  await relay();

  const erc1155chain1address3 = await controller3.nftId2address(erc1155chain1nftId);
  const erc1155chain1contract3 = new ethers.Contract(erc1155chain1address3, AxelarSeaERC1155.abi, user3);

  console.log('ERC1155 LINKED', erc1155chain1nftId._hex, erc1155template1.address, erc1155chain1address2, erc1155chain1address3);

  printSeperator();

  // Test bridge ERC721
  await erc721template1.setApprovalForAll(controller1.address, true);
  await controller1.bridge(2, erc721chain1nftId, 2, 1, ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [user2.address],
  ), {value: gasLimit * gasPrice});
  console.log('ERC721 BRIDGE FROM CHAIN 1 -> 2');

  await relay();

  console.log('ERC721 CHAIN1 LOCKED', await erc721template1.ownerOf(2) == controller1.address);
  console.log('ERC721 CHAIN2 UNLOCKED', await erc721chain1contract2.ownerOf(2) == user2.address);

  await controller2.bridge(3, erc721chain1nftId, 2, 1, ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [user3.address],
  ), {value: gasLimit * gasPrice});
  console.log('ERC721 BRIDGE FROM CHAIN 2 -> 3');

  await relay();

  console.log('ERC721 CHAIN1 LOCKED', await erc721template1.ownerOf(2) == controller1.address);
  console.log('ERC721 CHAIN2 LOCKED', !(await erc721chain1contract2.exists(2)));
  console.log('ERC721 CHAIN3 UNLOCKED', await erc721chain1contract3.ownerOf(2) == user3.address);

  await controller3.bridge(1, erc721chain1nftId, 2, 1, ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [user1.address],
  ), {value: gasLimit * gasPrice});
  console.log('ERC721 BRIDGE FROM CHAIN 3 -> 1');

  await relay();

  console.log('ERC721 CHAIN1 UNLOCKED', await erc721template1.ownerOf(2) == user1.address);
  console.log('ERC721 CHAIN2 LOCKED', !(await erc721chain1contract2.exists(2)));
  console.log('ERC721 CHAIN3 LOCKED', !(await erc721chain1contract3.exists(2)));

  printSeperator();

  // Test bridge ERC1155
  await erc1155template1.setApprovalForAll(controller1.address, true);
  await controller1.bridge(2, erc1155chain1nftId, 2, 7, ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [user2.address],
  ), {value: gasLimit * gasPrice});
  console.log('ERC1155 BRIDGE FROM CHAIN 1 -> 2');

  await relay();

  console.log('ERC1155 CHAIN1 CONTROLLER', await erc1155template1.balanceOf(controller1.address, 2) == 7);
  console.log('ERC1155 CHAIN1 USER', await erc1155template1.balanceOf(user1.address, 2) == 3);
  console.log('ERC1155 CHAIN2 CONTROLLER', await erc1155chain1contract2.balanceOf(controller2.address, 2) == 0);
  console.log('ERC1155 CHAIN2 USER', await erc1155chain1contract2.balanceOf(user2.address, 2) == 7);

  await controller2.bridge(3, erc1155chain1nftId, 2, 5, ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [user3.address],
  ), {value: gasLimit * gasPrice});
  console.log('ERC1155 BRIDGE FROM CHAIN 2 -> 3');

  await relay();

  console.log('ERC1155 CHAIN1 CONTROLLER', await erc1155template1.balanceOf(controller1.address, 2) == 7);
  console.log('ERC1155 CHAIN1 USER', await erc1155template1.balanceOf(user1.address, 2) == 3);
  console.log('ERC1155 CHAIN2 CONTROLLER', await erc1155chain1contract2.balanceOf(controller2.address, 2) == 0);
  console.log('ERC1155 CHAIN2 USER', await erc1155chain1contract2.balanceOf(user2.address, 2) == 2);
  console.log('ERC1155 CHAIN3 CONTROLLER', await erc1155chain1contract3.balanceOf(controller3.address, 2) == 0);
  console.log('ERC1155 CHAIN3 USER', await erc1155chain1contract3.balanceOf(user3.address, 2) == 5);

  await controller3.bridge(1, erc1155chain1nftId, 2, 4, ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [user1.address],
  ), {value: gasLimit * gasPrice});
  console.log('ERC1155 BRIDGE FROM CHAIN 3 -> 1');

  await relay();

  console.log('ERC1155 CHAIN1 CONTROLLER', await erc1155template1.balanceOf(controller1.address, 2) == 3);
  console.log('ERC1155 CHAIN1 USER', await erc1155template1.balanceOf(user1.address, 2) == 7);
  console.log('ERC1155 CHAIN2 CONTROLLER', await erc1155chain1contract2.balanceOf(controller2.address, 2) == 0);
  console.log('ERC1155 CHAIN2 USER', await erc1155chain1contract2.balanceOf(user2.address, 2) == 2);
  console.log('ERC1155 CHAIN3 CONTROLLER', await erc1155chain1contract3.balanceOf(controller3.address, 2) == 0);
  console.log('ERC1155 CHAIN3 USER', await erc1155chain1contract3.balanceOf(user3.address, 2) == 1);

  // const Greeter = await ethers.getContractFactory("Greeter");
  // Greeter.interface
  // const greeter = await Greeter.deploy("Hello, world!");
  // await greeter.deployed();

  // expect(await greeter.greet()).to.equal("Hello, world!");

  // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

  // // wait until the transaction is mined
  // await setGreetingTx.wait();

  // expect(await greeter.greet()).to.equal("Hola, mundo!");
})();