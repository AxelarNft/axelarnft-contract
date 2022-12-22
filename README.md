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

* deploying "DefaultProxyAdmin" (tx: 0xdd17de93b1c4bb74da45b0757d5e601bb6f4d4058195f533daaccd4a6b1b8e86)...: deployed at 0x407f4aA03c675e23583A37D565801C495f98fC46 with 643983 gas
* deploying "AxelarSeaProjectRegistry_Implementation" (tx: 0x3522cca1ee9d3ee51630d3ef1863864468035360a29d2acbb2b900030b0ba5b0)...: deployed at 0x568A88Cb8A56268bda844D49937fe068B6A1649A with 2589991 gas
* deploying "AxelarSeaProjectRegistry_Proxy" (tx: 0xc57ec293a7ee12b484c141cfffddc8c2edd9aee486f95a0bf815edbb3e96512e)...: deployed at 0x841C2b3F324173d93b5f70D9039bDB02fCD923d5 with 895293 gas
* deploying "AxelarSeaNft721Enumerable" (tx: 0xcfc90f6a00519b9e1cfdb413424c1b642611df953b99ff8cbbdff2b0f251ed89)...: deployed at 0xC0A2374146C0f042a9f557337f130aED2721C31d with 3151707 gas
* deploying "AxelarSeaNft721A" (tx: 0x39f4e0f2940f614f4ed6fd2ee5777bee4c39574fc530b60e14cb8720f74e56a7)...: deployed at 0x0e36a1F1a38781705f739ef0eaDDb394De81013B with 3211399 gas
* deploying "AxelarSeaNftMerkleMinter" (tx: 0x8a851a2e214edaefd80fbfad3acefde4e502a30c299bff44d943851d68bbd6e0)...: deployed at 0xF60c3Aa52Fe8bc82E670549f80245f438Aa80a50 with 1247543 gas
* deploying "AxelarSeaNftMerkleMinterNative" (tx: 0xade0dfc757b634a82f1fc6117e36714953d905d46f08525099922b7f13b9398b)...: deployed at 0x21482Ca9169e9d8813f20B3faE394D7954d0d59d with 1203931 gas
* deploying "AxelarSeaNftSignatureMinter" (tx: 0x27e8cae9b6140b885eece7e15badf79a02a6e035695ad558a9b3e100e19ce26b)...: deployed at 0x6C0254f2908aB27A7615d2cdED9C9c263424892f with 1443998 gas
* deploying "AxelarSeaNftSignatureMinterNative" (tx: 0xa71ac2039f07fb4382dd90f2b37da615df3351161d5a9157d18c7781bd9be904)...: deployed at 0x2291424bC8Bb2E598C19FAd2A69CEf36Cb469932 with 1400391 gas
* deploying "AxelarSeaNftPublicMinter" (tx: 0xbc501b90294c87a1cf92ec3879b3def9fdbf10959c175a8fb57493a195be5197)...: deployed at 0x891e8eb568dF7655d541a51f287E1b8fB9268A8E with 1106374 gas
* deploying "AxelarSeaNftPublicMinterNative" (tx: 0xb2e34dafaf84a8b2c401abedb07b1fe78dd2f8eb4c11d2e25fc3536ca3ffc97d)...: deployed at 0xD8d247663033858933A2366A3ef21fad788d2E32 with 1062811 gas

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
