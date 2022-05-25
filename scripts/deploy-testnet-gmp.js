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

const weth = {
  "3": "0xc778417E063141139Fce010982780140Aa0cD5Ab",
  "1287": "0x1436aE0dF0A8663F18c0Ec51d7e2E46591730715",
  "4002": "0x812666209b90344Ec8e528375298ab9045c2Bd08",
  "43113": "0xd00ae08403B9bbb9124bB305C09058E32C39A48c",
  "80001": "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889"
}

async function main() {
  const accounts = await hre.ethers.getSigners();
  const chainId = hre.network.config.chainId;

  console.log('CHAIN', chainId);

  const MarketplaceMetaWallet = await hre.ethers.getContractFactory("MarketplaceMetaWalletGMP");
  const marketplaceMetaWallet = await MarketplaceMetaWallet.deploy(marketplaceAddress[chainId], axelarGateway[chainId], axelarGasReceiver[chainId], weth[chainId]);
  await marketplaceMetaWallet.deployed();

  console.log("MarketplaceMetaWallet deployed to:", marketplaceMetaWallet.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
