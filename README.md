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

* deploying "DefaultProxyAdmin" (tx: 0x467ee5b91f672680037bc082c8945225886711c2bd8f114d42c66177bff24306)...: deployed at 0x9e8160874163F3004EA160A8015a75c5336BAADe with 643983 gas
* deploying "AxelarSeaProjectRegistry_Implementation" (tx: 0xb0b4ab359110998ff798a6d9f3f8842ea61804bc300a2f4a3b593da0573eb46d)...: deployed at 0x4701207344A065d6c1c663824731f05f1a3016E9 with 2518893 gas
* deploying "AxelarSeaProjectRegistry_Proxy" (tx: 0xe934436e25d52cff606de7929adff5f554dfd7b1ef8889679777845c5a724bd4)...: deployed at 0x54032E22d61ada3095531C12224795A1258657D5 with 895259 gas
* deploying "AxelarSeaNft721Enumerable" (tx: 0x3d8213261aa2fe2a4ed5e8e4010377ddba1c76cdd5f58bddba91d4a41d36a617)...: deployed at 0x8e78E9F51b75B2e478F66579722B8B48748b5447 with 3182782 gas
* deploying "AxelarSeaNft721A" (tx: 0x15b5a9e894cd5edd2a1100f6409659bc798727625bc3f6d76516a1f7ba37890b)...: deployed at 0x439DA988417526D20f40EF4077056bE1F5c7Cd4e with 3219351 gas
* deploying "AxelarSeaNftMerkleMinter" (tx: 0x31c2601a984998a95e02f3e8507eda42086440dbfa098e21db17ffc52b1185cf)...: deployed at 0xbBc01A64277Eb1706574918dc3CE674da61F1ef1 with 1173244 gas
* deploying "AxelarSeaNftMerkleMinterNative" (tx: 0xe6188e5dc5eaf73afa7dc082c8fa5a5fdf71f4c3c95289ee5a00c68c4bbcc3c6)...: deployed at 0x619F3c9a1C031F0bDC348eC8c2fEEAd9fAC5B30e with 1129218 gas
* deploying "AxelarSeaNftSignatureMinter" (tx: 0xf0186ec3b6f08275f14966e6af7f1562e901d3f4288f11fd050ebf56a5e83812)...: deployed at 0xfDA20b1e033300ee07eB1FB2381C3cD16d055ABd with 1389308 gas
* deploying "AxelarSeaNftSignatureMinterNative" (tx: 0x466c999f7edc8f8d2f2172588a8c1d6d62fd1fd23566a2349ece4391e6959912)...: deployed at 0x46DED0143f98FCf603936431dFd92B2Cf11d352d with 1346404 gas
* deploying "AxelarSeaNftPublicMinter" (tx: 0xe48326892d7f4eb12a8ab90ae75bbe72c60512755c377dd909c4ac3670329c0a)...: deployed at 0x8c77174A93D3F97b63aDF9cCc23d4F2bbFeab562 with 1031794 gas
* deploying "AxelarSeaNftPublicMinterNative" (tx: 0xc56f0f3d5bae420f9aec698ff351d4b649e0c6d2856f9cf203611a1bfa7ef04c)...: deployed at 0xa4A1eBfeADDe626f56eEa55770Eb433B599D8429 with 987775 gas

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
