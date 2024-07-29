

import hre from "hardhat";


export async function deployTreasury() {
    const treasuryFactory = await hre.ethers.getContractFactory("Repository")
    const treasury = await treasuryFactory.deploy()
    await treasury.waitForDeployment();
    return treasury;
}

export async function deployRepository() {
    // Distributor implementation
    const contractRepo = await hre.ethers.getContractFactory("Repository")
    const repo = await hre.upgrades.deployProxy(contractRepo, { kind: 'uups' })
    await repo.waitForDeployment();
    return repo;
}

export async function deployPopulatedRepository() {
    const repo = await deployRepository()
    const treasury = await deployTreasury()
    // 2 = TREASURE
    repo.populate([2], [await treasury.getAddress()])
    return repo;



}

