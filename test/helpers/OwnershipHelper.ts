
import hre from 'hardhat'
import { Ownership } from '@/typechain-types'

export async function deployOwnership(referendumAddress: string) {
    const ownershipFactory = await hre.ethers.getContractFactory('Ownership')
    const factory = await hre.upgrades.deployProxy(ownershipFactory, [referendumAddress], { kind: 'uups' })
    await factory.waitForDeployment()
    return factory
}


export async function attachOwnershipContract (ownershipAddress: string) {
    const contractFactory = await hre.ethers.getContractFactory('Ownership')
    const ownership = contractFactory.attach(ownershipAddress) as Ownership
    return ownership
  }