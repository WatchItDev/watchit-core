import hre from 'hardhat'
import { deployToken } from './TokenHelper'
import { deployTreasury } from './TreasuryHelper'

export function expectedFees() {
  return hre.ethers.parseUnits('100', 18) // 100 mmc
}

export function expectedPenaltyBPS() {
  return 1000;
}

export async function deploySyndication(tokenAddress: string, treasuryAddress: string) {
  // Contracts are deployed using the first signer/account by default
  const syndicationFactory = await hre.ethers.getContractFactory('Syndication')
  // repository address, initialFees 0.3 native coin, 1000 bps = 10% penalty
  const factory = await hre.upgrades.deployProxy(syndicationFactory, [
    tokenAddress, treasuryAddress, expectedFees(), expectedPenaltyBPS()
  ], { kind: 'uups' })

  await factory.waitForDeployment()
  return factory
}


export async function deployInitializedSyndication() {
  // Contracts are deployed using the first signer/account by default
  const token = await deployToken()
  const treasury = await deployTreasury();
  const tokenAddress = await token.getAddress();
  const treasuryAddress = await token.getAddress();
  const factory = await deploySyndication(tokenAddress, treasuryAddress)
  return [factory, treasury, token]
}