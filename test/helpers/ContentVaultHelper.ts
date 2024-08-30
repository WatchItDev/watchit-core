
import hre from 'hardhat'

export async function deployContentVault() {
    // Distributor implementation
    const contentVault = await hre.ethers.getContractFactory('ContentVault')
    const deployedContract = await contentVault.deploy()
    await deployedContract.waitForDeployment()
    return deployedContract
}
