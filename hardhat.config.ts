import * as dotenv from "dotenv";

import "hardhat-typechain";
import "@nomiclabs/hardhat-ethers";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

import { INFURA_TOKEN } from "./utils/keys";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    rinkeby: {
      chainId: 4,
      url: "https://rinkeby.infura.io/v3/" + INFURA_TOKEN,
      accounts: [process.env.PRIVATE_KEY!],
    },
    goerli: {
      chainId: 5,
      url: "https://goerli.infura.io/v3/" + INFURA_TOKEN,
      accounts: [process.env.PRIVATE_KEY!],
    },
    bsc: {
      chainId: 97,
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [process.env.PRIVATE_KEY!],
    },
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts: [process.env.PRIVATE_KEY!, process.env.PRIVATE_KEY1!],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
