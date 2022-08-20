# Axelarsea Contract

## Address

### Polygon testnet
* MarketplaceMetaWallet deployed to: 0xc873FA6c0068895f80C4A25021B94FCFA33E3268
* Marketplace deployed to: 0x5C3B75f5656bB6b82FF4839E52491b9A575C0670
* Sample NFT deployed to: 0x93fC46e9cc34094519983e529869ebAFb93F47bF

### Ropsten testnet
* MarketplaceMetaWallet deployed to: 0xD5062f2d506a651BEda655cBf649491116b8b99C
* Marketplace deployed to: 0x5fA3b915A19D4a56417C06ba6617a8E90Ea149fD
* Sample NFT deployed to: 0xe54bd661dda41649A1c84b9D22Eb95BD1fc9BB58

### Avax testnet
* MarketplaceMetaWallet deployed to: 0xC03a7ED392E02a9F404013593A3dae8234876874
* Marketplace deployed to: 0xA32a90B0ec1232c69388AA1Bd5FEE6E8570a3726
* Sample NFT deployed to: 0x7EE1704B30C7efE70e2cA7d143A4585F47E05eDf

* AxelarSeaNft721Enumerable deployed to: 0x3BF1b55E0b699D3fF6Df3a90EBd82fb521F7420a
* AxelarSeaNft721A deployed to: 0x36E06AE07FAd08FAFB61ee712819bB208454bcA6
* AxelarSeaProjectRegistry deployed to: 0x00762f7415577Ab004Ae9b926856bEee049EBAe7
* AxelarSeaNftMerkleMinter deployed to: 0x58Ed5e9aB1aC5Bcf448001eCDeB0038002CEeb6B
* AxelarSeaNftMerkleMinterNative deployed to: 0x4Bcd4C71f7f57c965Be9478C3E897942E0D11093
* AxelarSeaNftSignatureMinter deployed to: 0x85524BFE8e5282EF2f743179d64E6Af71a6Bd598
* AxelarSeaNftSignatureMinterNative deployed to: 0xF4082021B35B3cD002f3D373ca5f058A0eBbE460
* AxelarSeaNftPublicMinter deployed to: 0xaa940fC46E83F84Ed626Cb167C5985b6d0E2cDE5
* AxelarSeaNftPublicMinterNative deployed to: 0x23a6Fd2c8582Ec0EF8cAF18c2e3c8610F677cbBf

### Fantom testnet
* MarketplaceMetaWallet deployed to: 0xD5062f2d506a651BEda655cBf649491116b8b99C
* Marketplace deployed to: 0x5fA3b915A19D4a56417C06ba6617a8E90Ea149fD
* Sample NFT deployed to: 0xcdc110ff963e5c4508BeDcf5fF7795C9E526Dfd5

### Moonbeam testnet
* MarketplaceMetaWallet deployed to: 0xD5062f2d506a651BEda655cBf649491116b8b99C
* Marketplace deployed to: 0x5fA3b915A19D4a56417C06ba6617a8E90Ea149fD
* Sample NFT deployed to: 0xc873FA6c0068895f80C4A25021B94FCFA33E3268

### Goerli
* Sample NFT deployed to: 0xD5062f2d506a651BEda655cBf649491116b8b99C
* AxelarSeaERC721 deployed to: 0x5fA3b915A19D4a56417C06ba6617a8E90Ea149fD
* AxelarSeaERC1155 deployed to: 0x913fF316D6921438930e131b716344F42Cb79135
* AxelarSeaNftBridgeController deployed to: 0xe54bd661dda41649A1c84b9D22Eb95BD1fc9BB58
* AxelarSeaNftCelerBridge deployed to: 0xc873FA6c0068895f80C4A25021B94FCFA33E3268

## Hardhat 101

This project demonstrates an advanced Hardhat use case, integrating other tools commonly used alongside Hardhat in the ecosystem.

The project comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts. It also comes with a variety of other tools, preconfigured to work with the project code.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
