require("@openzeppelin/hardhat-upgrades");
require("dotenv").config({ path: ".env" });
import { HardhatUserConfig } from "hardhat/config";

const RPC_URL = process.env.RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  networks: {
    testnet: {
      url: RPC_URL,
      accounts: [PRIVATE_KEY!],
    },
  },
  etherscan: {
    apiKey: {
      goerli: 'WT6D4T5GSPEBJWTBZC6EV1CYERGCCW72UF',
    },
  },
};

export default config;
