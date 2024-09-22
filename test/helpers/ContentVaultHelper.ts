
import hre from 'hardhat'

export async function deployContentVault(repoAddress: string) {
    // Distributor implementation
    const contentVault = await hre.ethers.getContractFactory('ContentVault')
    const deployedContract = await hre.upgrades.deployProxy(contentVault, [repoAddress], { kind: 'uups' })
    await deployedContract.waitForDeployment()
    return deployedContract
}
