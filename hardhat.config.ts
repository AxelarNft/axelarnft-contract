import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@openzeppelin/hardhat-upgrades";
import { task } from "hardhat/config";
const { privateKey, bscscanApiKey } = require('./secrets.json');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "localhost",
  solidity: {
    compilers: [
      {
        version: "0.4.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 300
          }
        }
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 300
          }
        }
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 300
          }
        }
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 300
          }
        }
      },
      {
        version: "0.8.13",
        settings: {
          optimizer: {
            enabled: true,
            runs: 300
          }
        }
      }
    ],
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
    apiKey: bscscanApiKey
  },
  networks: {
    hardhat: {
      chainId: 31337,
      // forking: {
      //   url: "https://speedy-nodes-nyc.moralis.io/301eb738d0e9755bd1c8b3e8/bsc/mainnet/archive",
      // }
    },
    localhost:{
      
    },

		ropsten: {
      url: "https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
      chainId: 3,
      accounts: [privateKey]
    },
		goerli: {
      url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
      chainId: 5,
      accounts: [privateKey]
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-2-s3.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [privateKey]
    },
    polygontestnet: {
      url: "https://matic-mumbai.chainstacklabs.com",
      chainId: 80001,
      accounts: [privateKey]
    },
    avaxtestnet: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: [privateKey]
    },
    fantomtestnet: {
      url: "https://rpc.testnet.fantom.network/",
      chainId: 4002,
      accounts: [privateKey]
    },
    moonbeamtestnet: {
      url: "https://rpc.testnet.moonbeam.network/",
      chainId: 1287,
      accounts: [privateKey]
    },
    arbitrumtestnet: {
      url: "https://rinkeby.arbitrum.io/rpc",
      chainId: 421611,
      accounts: [privateKey]
    },

    polygon: {
      url: "https://polygon-rpc.com",
      chainId: 137,
      accounts: [privateKey]
    },
    fantom: {
      url: "https://rpcapi.fantom.network",
      chainId: 250,
      accounts: [privateKey]
    },

    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 5000000000,
      accounts: [privateKey]
    },
		bscfork: {
			url: `http://104.248.144.44`,
			chainId: 56,
			accounts: [privateKey],
		},
  }
};

