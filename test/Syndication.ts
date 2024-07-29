import hre from "hardhat";
import { expect } from "chai";
import type * as ethers from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { deployDistributorFactory, commitRegister } from "./helpers/DistributorHelper";
import { deployPopulatedRepository } from "./helpers/RepositoryHelper";
import { deploySyndication } from "./helpers/SyndicationHelper";

async function getAccounts() {
  return await hre.ethers.getSigners()
}

async function getFilterLastEventArgs(contract: ethers.Contract, filter: any) {
  // filter the emitted distributor created event
  const events = await contract.queryFilter(filter)
  const lastEvent = events.pop() as ethers.EventLog
  return lastEvent?.args
}

async function deployInitializedSyndication() {
  // Contracts are deployed using the first signer/account by default
  const repo = await deployPopulatedRepository();
  const factory = await deploySyndication(await repo.getAddress());
  return factory
}

async function distributorRegisteredWithLastEvent(syndication: ethers.Contract) {
  const syndicationFilter = syndication.filters.Registered()
  const lastEvent = await getFilterLastEventArgs(syndication, syndicationFilter)
  return lastEvent?.distributor.toString()
}

async function deployDistributor() {
  // Contracts are deployed using the first signer/account by default
  const beacon = await loadFixture(deployDistributorFactory)
  const beaconProxy = await commitRegister(beacon, 'watchit6.movie')
  return beaconProxy
}


describe("Syndication", function () {

  it("Should register successfully with valid distributor contract.", async function () {
    const fees = hre.ethers.parseUnits('0.3', 'ether'); // expected fees paid in contract..
    const distributor: string = await loadFixture(deployDistributor)
    const syndication = await loadFixture(deployInitializedSyndication)
    // const balance = await hre.ethers.provider.getBalance(await syndication.getAddress())
    // const registeredDistributor = await distributorRegisteredWithLastEvent(syndication)
    expect(await syndication.register(distributor, { value: fees })).to.emit(syndication, 'Registered')

  });

  it("Should quit successfully with valid enrollment.", async function () {
    const fees = hre.ethers.parseUnits('0.3', 'ether'); // expected fees paid in contract..
    const [owner,] = await getAccounts();

    const distributor: string = await loadFixture(deployDistributor)
    const syndication = await loadFixture(deployInitializedSyndication)
    // const registeredDistributor = await distributorRegisteredWithLastEvent(syndication)
    await syndication.register(distributor, { value: fees })
    const afterRegisterBalance = await hre.ethers.provider.getBalance(await syndication.getAddress())

    await syndication.quit(distributor);
    const afterQuitBalance = await hre.ethers.provider.getBalance(await syndication.getAddress())

    // 1000 bps = 10% nominal
    // original fees paid on registration - 10% penalty
    const penal = (fees * BigInt(1000)) / BigInt(10000);
    expect(afterRegisterBalance).to.be.equal(fees);
    // the contract keep the 10%
    expect(afterQuitBalance).to.be.equal(penal);




  });


  // it("Should fail with invalid distributor contract.", async function () {
  //   const distributor = '0x0000000000000000000000000000000000000001' // invalid contract
  //   const syndication = await loadFixture(deploySyndication)

  //   await expect(syndication.register(distributor)).to.be.revertedWithCustomError(
  //     syndication, "InvalidDistributorContract"
  //   );

  // });

  //should fail if status is pending during register
  //should fail revoke if not registered governance
  //is active

});
