import hre from 'hardhat'
import { expect } from 'chai'
import type * as ethers from 'ethers'

import { deployDistributorFactory, commitRegister } from './helpers/DistributorHelper'
import { deployPopulatedRepository } from './helpers/RepositoryHelper'
import { deploySyndication } from './helpers/SyndicationHelper'
import { switcher } from './helpers/CommonHelper'

async function getAccounts () {
  return await hre.ethers.getSigners()
}

async function getFilterLastEventArgs (contract: ethers.Contract, filter: any) {
  // filter the emitted distributor created event
  const events = await contract.queryFilter(filter)
  const lastEvent = events.pop() as ethers.EventLog
  return lastEvent?.args
}

async function deployInitializedSyndication () {
  // Contracts are deployed using the first signer/account by default
  const repo = await deployPopulatedRepository()
  const factory = await deploySyndication(await repo.getAddress())
  return factory
}

async function deployDistributor () {
  // Contracts are deployed using the first signer/account by default
  const beacon = await switcher(deployDistributorFactory)
  const beaconProxy = await commitRegister(beacon, 'watchit6.movie')
  return beaconProxy
}

describe('Syndication', function () {
  it('Should register successfully with valid Registered distributor contract with valid enrollment fees.', async function () {
    const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
    const distributor: string = await switcher(deployDistributor)
    const syndication = await switcher(deployInitializedSyndication)
    expect(await syndication.register(distributor, { value: fees })).to.emit(syndication, 'Registered')
  })

  it('Should fail register with FailDuringEnrollment with invalid fees.', async function () {
    const fees = hre.ethers.parseUnits('0.2', 'ether') // expected 0.3 ether fees paid in contract..
    const distributor: string = await switcher(deployDistributor)
    const syndication = await switcher(deployInitializedSyndication)

    await expect(
      syndication.register(distributor, { value: fees })
    ).to.revertedWithCustomError(syndication, 'FailDuringEnrollment')
  })

  it('Should fail with InvalidDistributorContract.', async function () {
    const distributor = hre.ethers.ZeroAddress // invalid contract
    const syndication = await switcher(deployInitializedSyndication)
    await expect(syndication.register(distributor)).to.be.revertedWithCustomError(
      syndication, 'InvalidDistributorContract'
    )
  })

  it('Should quit successfully with valid Resigned enrollment.', async function () {
    const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
    const distributor: string = await switcher(deployDistributor)
    const syndication = await switcher(deployInitializedSyndication)
    // const registeredDistributor = await distributorRegisteredWithLastEvent(syndication)
    await syndication.register(distributor, { value: fees })
    expect(await syndication.quit(distributor)).to.emit(syndication, 'Resigned')
  })

  it('Should fail quit with FailDuringQuit invalid enrollment.', async function () {
    const distributor: string = await switcher(deployDistributor)
    const syndication = await switcher(deployInitializedSyndication)
    // const registeredDistributor = await distributorRegisteredWithLastEvent(syndication)
    await expect(syndication.quit(distributor)).to.be.revertedWithCustomError(
      syndication, 'FailDuringQuit' // no registered enrollment
    )
  })

  it('Should retain the correct penalty amount after quit.', async function () {
    const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
    const distributor: string = await switcher(deployDistributor)
    const syndication = await switcher(deployInitializedSyndication)

    // register the distributor
    await (await syndication.register(distributor, { value: fees })).wait()
    // receive the enrollment fees..
    const afterRegisterBalance = await hre.ethers.provider.getBalance(await syndication.getAddress())
    // quit after enrollment after some time X.
    await (await syndication.quit(distributor)).wait()
    // rollback the enrollment fees minus a penalty..
    const afterQuitBalance = await hre.ethers.provider.getBalance(await syndication.getAddress())

    // 1000 bps = 10% nominal
    // original fees paid on registration - 10% penalty
    const penal = (fees * BigInt(1000)) / BigInt(10000)
    expect(afterRegisterBalance).to.be.equal(fees)
    // the contract keep the 10%
    expect(afterQuitBalance).to.be.equal(penal)
  })

  // should fail if status is pending during register
  // should fail revoke if not registered governance
  // is active
})
