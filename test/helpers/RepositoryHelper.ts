
import hre from 'hardhat'
import { deployTreasury } from './TreasuryHelper'
import { deployOwnership } from './OwnershipHelper'
import { deployMMC } from './MMCHelper'

export async function deployRepository() {
  // Distributor implementation
  const contractRepo = await hre.ethers.getContractFactory('Repository')
  const repo = await hre.upgrades.deployProxy(contractRepo, { kind: 'uups' })
  await repo.waitForDeployment()
  return repo
}

export async function deployPopulatedRepository() {
  const repo = await deployRepository()
  const repoAddress = await repo.getAddress()

  const treasury = await deployTreasury()
  const ownership = await deployOwnership(repoAddress)
  const mmc = await deployMMC()
  // 3 = TREASURE
  repo.populate([2, 3, 6], [await ownership.getAddress(), await treasury.getAddress(), await mmc.getAddress()])
  return repo
}
