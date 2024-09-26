
import hre from 'hardhat'
import { deployOwnership } from './OwnershipHelper'
import { deployReferendum } from './ReferendumHelper'

export async function deployContentVault(repoAddress: string) {
    // Distributor implementation
    const contentVault = await hre.ethers.getContractFactory('ContentVault')
    const deployedContract = await hre.upgrades.deployProxy(contentVault, [repoAddress], { kind: 'uups' })
    await deployedContract.waitForDeployment()
    return deployedContract
}


export async function deployInitializedContentVault() {
    // Contracts are deployed using the first signer/account by default
    const referendum = await deployReferendum()
    const ownership = await deployOwnership(await referendum.getAddress())
    const factory = await deployContentVault(await ownership.getAddress())
    return [factory, ownership, referendum]
  }
  