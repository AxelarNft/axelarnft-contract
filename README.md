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

* deploying "DefaultProxyAdmin" (tx: 0x36e46670ab827ce5c4e6cb792246443e280fdb39ba44c67eb735a4854c502786)...: deployed at 0x5257a7877Fb3DBe1FB2Bf3e30c19e2Eb2A763668 with 643983 gas
* deploying "AxelarSeaProjectRegistry_Implementation" (tx: 0x8f774361bb15f87f2befd91002c5c10cad828013ecfa7f9fe66b45ba3dc648b8)...: deployed at 0xC426C8222D6Cf19Fe23428025Cb7F6D736f39b3E with 2589991 gas
* deploying "AxelarSeaProjectRegistry_Proxy" (tx: 0xd40c87badff62596aaf82640ea62ba99626a54823c106a7d27f24223a37699c0)...: deployed at 0xc1a7202C360DBC48E0f67C3eED6E8eE002a44AB3 with 895293 gas
* deploying "AxelarSeaNft721Enumerable" (tx: 0x34df00c356269c6501729b4733d2b615f4314441d5e99a1ea7788d660f20e7da)...: deployed at 0xDa38F62aa981b884F30dcfE7CC3EbeB8f0BBE53A with 3151707 gas
* deploying "AxelarSeaNft721A" (tx: 0x64f7818cc7f290533cb3ff001993d6152dc2ca6eb9b407671bead2ddf62e38c5)...: deployed at 0x35f27aeaF14FFC401e66e7A3d7F1739c275D05a3 with 3211399 gas
* deploying "AxelarSeaNftMerkleMinter" (tx: 0x1cde943e3e8b36244a4775a956914c53e9b7237990b589b1c75495dcc23cd6ea)...: deployed at 0x0F77126c95b69F997AbeAB4DC0b03d08af454D73 with 1215368 gas
* deploying "AxelarSeaNftMerkleMinterNative" (tx: 0x7095199f53ab424e69a38a5b749b2bb53c5234720ff42878167d54649bbbbe97)...: deployed at 0x94A03c5BD9226639C59A04f5b51AdE908F2404d2 with 1171786 gas
* deploying "AxelarSeaNftSignatureMinter" (tx: 0x0b8b97c1f33bd403623b17981ad707e3d24ca54d1988c2787a6a0c103981ef32)...: deployed at 0x42F4B7A5c14f3629119A364fa699548e80bf2915 with 1430797 gas
* deploying "AxelarSeaNftSignatureMinterNative" (tx: 0xfaa2cf1bf70287302d9b7b05b5b2b72c4e9c50ea50f319f3d75cbaede7b8423b)...: deployed at 0xE8999de9CA5BC62350baF3d8571188b66e10a4dC with 1387220 gas
* deploying "AxelarSeaNftPublicMinter" (tx: 0x3450ce6c89a42105d50844baa8e4150ed9ead6aa016276368964ed4cb7d11239)...: deployed at 0x98D43B67A2B8EF2782A8a614b3c100B7113a5E3E with 1074181 gas
* deploying "AxelarSeaNftPublicMinterNative" (tx: 0x936997c48a943e81a5f1f68a6ee4fc3ebef6ad20f6f2a3b5ff0b06a46f385440)...: deployed at 0x9e119dB13E3956EA0A256E70313bF4520f9a2743 with 1030630 gas

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
