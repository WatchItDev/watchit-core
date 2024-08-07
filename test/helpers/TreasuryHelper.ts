
import hre from 'hardhat'


export async function deployTreasury() {
    // Distributor implementation
    // Contracts are deployed using the first signer/account by default
    const treasuryContract = await hre.ethers.getContractFactory('Treasury')
    // repository address, initialFees 0.3 native coin, 1000 bps = 10% penalty
    const factory = await hre.upgrades.deployProxy(treasuryContract, [], { kind: 'uups' })
    await factory.waitForDeployment()
    return factory
}