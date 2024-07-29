import hre from "hardhat";
import type * as ethers from "ethers";

export async function deploySyndication(repoAddress: string): Promise<ethers.Contract> {
    // Contracts are deployed using the first signer/account by default
    const initialFees = hre.ethers.parseUnits('0.3', 'ether') // wei
    const syndicationFactory = await hre.ethers.getContractFactory("Syndication")
    const factory = await hre.upgrades.deployProxy(syndicationFactory, [repoAddress, initialFees, 10], {kind: 'uups'});
    await factory.waitForDeployment();
    return factory
}