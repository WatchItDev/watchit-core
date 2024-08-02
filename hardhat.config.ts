import dotenv from 'dotenv'
import type { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-chai-matchers'
import "@nomicfoundation/hardhat-foundry";
import '@nomicfoundation/hardhat-toolbox'
import '@openzeppelin/hardhat-upgrades'
import '@typechain/hardhat'

dotenv.config()
const OWNER_KEY = process.env.PRIVATE_KEY ?? ''
const AMOY_ENDPOINT = process.env.AMOY_ENDPOINT ?? ''
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY ?? ''

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.24',
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 500
      }
    }
  },
  gasReporter: {
    currency: 'USD',
    showTimeSpent: true,
    L1: 'polygon',
    enabled: true,
    coinmarketcap: '6ffc3d5b-865e-482d-a05c-144ba7fe319e'
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  networks: {
    hardhat: {
      chainId: 31337,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true
    },
    polygon: {
      url: `${AMOY_ENDPOINT}${ALCHEMY_API_KEY}`,
      accounts: [`${OWNER_KEY}`]
    }
  },
  mocha: {
    timeout: 0
  }
}

export default config
