// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const MarketplaceMetaWallet = await hre.ethers.getContractFactory("MarketplaceMetaWallet");
  const marketplaceMetaWallet = await MarketplaceMetaWallet.deploy();
  await marketplaceMetaWallet.deployed();

  console.log("MarketplaceMetaWallet deployed to:", marketplaceMetaWallet.address);

  const Marketplace = await hre.ethers.getContractFactory("AxelarSeaMarketplace");
  const marketplace = await Marketplace.deploy(marketplaceMetaWallet.address);
  await marketplace.deployed();

  console.log("Marketplace deployed to:", marketplace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
