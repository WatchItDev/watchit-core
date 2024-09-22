
import hre from 'hardhat'


export async function deployMMC() {
    const mmc = await hre.ethers.getContractFactory('MMC')
    // repository address, initialFees 0.3 native coin, 1000 bps = 10% penalty
    const factory = await mmc.deploy()
    await factory.waitForDeployment()
    return factory
}