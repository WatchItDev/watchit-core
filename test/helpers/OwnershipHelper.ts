
import hre from 'hardhat'


export async function deployOwnership(repoAddress: string) {
    const ownershipFactory = await hre.ethers.getContractFactory('Ownership')
    const factory = await hre.upgrades.deployProxy(ownershipFactory, [repoAddress], { kind: 'uups' })
    await factory.waitForDeployment()
    return factory
}