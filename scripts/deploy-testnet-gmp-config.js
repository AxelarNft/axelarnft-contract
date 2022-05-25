// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const marketplaceAddress = {
  3: '0x5fA3b915A19D4a56417C06ba6617a8E90Ea149fD',
  80001: "0x5C3B75f5656bB6b82FF4839E52491b9A575C0670",
  43113: "0xA32a90B0ec1232c69388AA1Bd5FEE6E8570a3726",
  4002: "0x5fA3b915A19D4a56417C06ba6617a8E90Ea149fD",
  1287: "0x5fA3b915A19D4a56417C06ba6617a8E90Ea149fD",
}

const axelarGateway = {
  "3": "0xBC6fcce7c5487d43830a219CA6E7B83238B41e71",
  "1287": "0x5769D84DD62a6fD969856c75c7D321b84d455929",
  "4002": "0x97837985Ec0494E7b9C71f5D3f9250188477ae14",
  "43113": "0xC249632c2D40b9001FE907806902f63038B737Ab",
  "80001": "0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B"
}

const axelarGasReceiver = {
  "3": "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6",
  "1287": "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6",
  "4002": "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6",
  "43113": "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6",
  "80001": "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6"
}

const marketplaceMetaWalletAddress = {
  3: '0x25d546Cf3AC6FDeBD8f1bf5F38fa4b8c4A059266',
  80001: "0xF064fB56d1841e88B71D60fC08af663035B96D7B",
  43113: "0x8D013ac025C8f949CaFe11F935f24130D3330008",
  4002: "0x6e865C4e7079405EF5082217ACEFe6568d12a93c",
  1287: "0x3269B478744C069E1cfA4c6246B8cBB948Ef9cEC",
}

const axelarChainName = {
  "3": "Ethereum",
  "1287": "Moonbeam",
  "4002": "Fantom",
  "43113": "Avalanche",
  "80001": "Polygon",
}

async function main() {
  const accounts = await hre.ethers.getSigners();
  const chainId = hre.network.config.chainId;

  console.log('CHAIN', chainId);

  const MarketplaceMetaWallet = await hre.ethers.getContractFactory("MarketplaceMetaWalletGMP");
  const marketplaceMetaWallet = await MarketplaceMetaWallet.attach(marketplaceMetaWalletAddress[chainId]);
  await marketplaceMetaWallet.deployed();

  for (let destChainId in marketplaceMetaWalletAddress) {
    await marketplaceMetaWallet.addWhitelist(axelarChainName[destChainId], marketplaceMetaWalletAddress[destChainId]).then(tx => tx.wait());
    console.log("DEST", destChainId);
  }

  console.log("MarketplaceMetaWallet deployed to:", marketplaceMetaWallet.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
