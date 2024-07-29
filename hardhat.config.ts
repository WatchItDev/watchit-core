import dotenv from 'dotenv'
import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades"
import '@typechain/hardhat'

dotenv.config()
const OWNER_KEY = process.env.PK
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY
const HARDHAT_AUTOMINE = process.env.HARDHAT_AUTOMINE

if (HARDHAT_AUTOMINE === 'true' && !process.env.CI) {
  console.warn('WARN: HARDHAT_AUTOMINE is on. This should only be in CI or selectively on local')
}

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.24',
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
      },
    }
  },
  gasReporter: {
    currency: 'USD',
    showTimeSpent: true,
    L1: "polygon",
    enabled: true,
    coinmarketcap: '6ffc3d5b-865e-482d-a05c-144ba7fe319e'
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  networks: {
    hardhat: {
      throwOnTransactionFailures: true,
      throwOnCallFailures: true
    },
    polygon: {
      url: `https://polygon-amoy.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [`0x${OWNER_KEY}`],
    }
  },
  mocha: {
    timeout: 40000
  }
}


export default config;