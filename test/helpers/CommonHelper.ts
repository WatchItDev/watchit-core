import hre from 'hardhat'
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'

// This function is needed because loadFixture can be used in hardhat local only
// OnlyHardhatNetworkError: This helper can only be used with Hardhat Network. You are connected to 'localhost'.
// https://github.com/NomicFoundation/hardhat/issues/3788
export async function switcher (decorable: any): Promise<any> {
  const networkName = hre.network.name
  if (networkName === 'hardhat') { return await loadFixture(decorable) }
  return await decorable()
}

export async function getAccounts() {
  return await hre.ethers.getSigners()
}
