
import hre from 'hardhat'


export async function deployToken() {
    const initialSupply = 1_000_000_000; // 1 billion
    const mmc = await hre.ethers.getContractFactory('MMC')
    // repository address, initialFees 0.3 native coin, 1000 bps = 10% penalty
    const factory = await mmc.deploy(initialSupply)
    await factory.waitForDeployment()
    return factory
}