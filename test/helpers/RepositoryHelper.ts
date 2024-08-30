
import hre from 'hardhat'
import { deployTreasury } from './TreasuryHelper'

export async function deployRepository() {
  // Distributor implementation
  const contractRepo = await hre.ethers.getContractFactory('Repository')
  const repo = await hre.upgrades.deployProxy(contractRepo, { kind: 'uups' })
  await repo.waitForDeployment()
  return repo
}

export async function deployPopulatedRepository() {
  const repo = await deployRepository()
  const treasury = await deployTreasury()
  // 3 = TREASURE
  repo.populate([3], [await treasury.getAddress()])
  return repo
}
