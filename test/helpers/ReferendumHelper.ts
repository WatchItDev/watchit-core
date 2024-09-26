
import hre from 'hardhat'


export async function deployReferendum() {
    const referendumFactory = await hre.ethers.getContractFactory('Referendum')
    const factory = await hre.upgrades.deployProxy(referendumFactory, [], { kind: 'uups' })
    await factory.waitForDeployment()
    return factory
}