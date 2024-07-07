import hre from "hardhat";
import { expect } from "chai";
import type * as ethers from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { Syndication } from "@/typechain-types";

async function getAccounts() {
  return await hre.ethers.getSigners()
}

async function getFilterLastEventArgs(contract: Syndication, filter: any) {
  // filter the emitted distributor created event
  const events = await contract.queryFilter(filter)
  const lastEvent = events.pop() as ethers.EventLog
  return lastEvent?.args
}

async function deploySyndication() {
  // Contracts are deployed using the first signer/account by default
  const contractFactory = await hre.ethers.getContractFactory("Syndication")
  const factory = await contractFactory.deploy();
  await factory.waitForDeployment();
  return factory
}

async function distributorRegisteredWithLastEvent(syndication: Syndication) {
  const syndicationFilter = syndication.filters.DistributorRegistered()
  const lastEvent = await getFilterLastEventArgs(syndication, syndicationFilter)
  return lastEvent?.distributor.toString()
}

async function deployDistributor() {
  // Contracts are deployed using the first signer/account by default
  const contractFactory = await hre.ethers.getContractFactory("Distributor")
  const distributor = await contractFactory.deploy("watchit.movie");
  await distributor.waitForDeployment();
  return distributor
}


describe("Syndication", function () {

  it("Should register successfully with valid distributor contract.", async function () {
    const distributor = await loadFixture(deployDistributor)
    const syndication = await loadFixture(deploySyndication)
    await (await syndication.register(distributor)).wait()

    const registeredDistributor = await distributorRegisteredWithLastEvent(syndication)
    expect(registeredDistributor).to.be.equal(await distributor.getAddress());

  });

  it("Should fail with invalid distributor contract.", async function () {
    const distributor = '0x0000000000000000000000000000000000000001' // invalid contract
    const syndication = await loadFixture(deploySyndication)

    await expect(syndication.register(distributor)).to.be.revertedWithCustomError(
      syndication, "InvalidDistributorContract"
    );

  });

  //should fail if status is pending during register
  //should fail revoke if not registered governance
  //is active

});
