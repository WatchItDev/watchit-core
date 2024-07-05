import hre from "hardhat";
import { expect } from "chai";
import type * as ethers from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { Distributor, DistributorFactory } from "@/typechain-types";

const DISTRIBUTOR_INTERFACE_ID = "0xf2d97449"


async function getAccounts() {
  return await hre.ethers.getSigners()
}

async function deployDistributorFactory() {
  // Contracts are deployed using the first signer/account by default
  const contractFactory = await hre.ethers.getContractFactory("DistributorFactory")
  const factory = await contractFactory.deploy();
  await factory.waitForDeployment();
  return factory
}

async function deployDistributor() {
  // Contracts are deployed using the first signer/account by default
  const contractFactory = await hre.ethers.getContractFactory("Distributor")
  const distributor = await contractFactory.deploy("watchit.movie");
  await distributor.waitForDeployment();
  return distributor
}

async function getFilterLastEventArgs(contract: DistributorFactory | Distributor, filter: any) {
  // filter the emitted distributor created event
  const events = await contract.queryFilter(filter)
  const lastEvent = events.pop() as ethers.EventLog
  return lastEvent?.args
}

async function commitRegister(factory: DistributorFactory, domain: string) {
  // filter indexed event the emitted distributor created event
  await (await factory.register(domain)).wait()
  // Unfortunately, it's not possible to get the return value of a state-changing function outside the off-chain.
  return distributorCreatedWithLastEvent(factory)
}

async function distributorCreatedWithLastEvent(factory: DistributorFactory) {
  const distributorFilter = factory.filters.DistributorCreated()
  const lastEvent = await getFilterLastEventArgs(factory, distributorFilter)
  return lastEvent?.distributor.toString()
}

describe("Distributor", function () {

  describe("Factory", function () {

    it("Should create a valid 'Distributor'.", async function () {
      const factory = await loadFixture(deployDistributorFactory)
      const registered = await commitRegister(factory, 'watchit.movie')
      const contractFactory = await hre.ethers.getContractFactory("Distributor")

      const distributor = contractFactory.attach(registered) as Distributor
      expect(await distributor.supportsInterface(DISTRIBUTOR_INTERFACE_ID)).to.be.true
      expect(await distributor.getEndpoint()).to.be.equal("watchit.movie")
    })

    it("Should add a new contract to 'contracts' list.", async function () {
      const factory = (await loadFixture(deployDistributorFactory)) as DistributorFactory
      const createdContractAddress = await commitRegister(factory, 'watchit.movie')
      const createdContractAddress2 = await commitRegister(factory, 'watchit2.movie')

      // check if the first registered contract is the same as the last event
      const contract1 = await factory.contracts(0)
      const contract2 = await factory.contracts(1)

      expect(contract1).to.equal(createdContractAddress)
      expect(contract2).to.equal(createdContractAddress2)
    });

    it("Should add the distributor correctly in registry mapping.", async function () {
      const registeredDomain = 'watchit.movie'
      const factory = await loadFixture(deployDistributorFactory)
      const [owner,] = await hre.ethers.getSigners();

      await commitRegister(factory, registeredDomain)
      const registeredOwner = await factory.registry(registeredDomain)
      expect(registeredOwner).to.be.equal(owner)
    })


    it("Should should fail if domain is already registered.", async function () {
      const duplicatedDomain = 'watchit.movie'
      const factory = await loadFixture(deployDistributorFactory)

      await commitRegister(factory, duplicatedDomain)
      await expect(factory.register(duplicatedDomain)).to.be.revertedWithCustomError(
        factory, "DistributorAlreadyRegistered"
      );

    })

    it("Should emit a valid 'DistributorCreated' after register distributor.", async function () {
      const factory = await loadFixture(deployDistributorFactory)
      expect(factory.register('watchit.movie')).to.emit(factory, 'DistributorCreated')
    })

    it("Should pause/unpause properly.", async function () {
      const factory = await loadFixture(deployDistributorFactory)
      const pause = await factory.pause()
      await pause.wait()
      expect(await factory.paused()).to.be.true

      const unpause = await factory.unpause()
      await unpause.wait()
      expect(await factory.paused()).to.be.false
    })
  });

  describe("Distributor", function () {

    it("Should update a valid endpoint successfully.", async function () {
      const newEndpoint = 'watchit2.movie';
      const distributor = await loadFixture(deployDistributor)
      const updater = await distributor.updateEndpoint(newEndpoint);
      await updater.wait();

      const distributorEndpoint = await distributor.getEndpoint()
      expect(newEndpoint).to.be.equal(distributorEndpoint);

    });

    it("Should emit a valid EndpointUpdated after update endpoint.", async function () {
      const newEndpoint = 'watchit3.movie';
      const distributor = await loadFixture(deployDistributor)
      const updater = await distributor.updateEndpoint(newEndpoint);
      await updater.wait();

      const filter = distributor.filters.EndpointUpdated()
      const lastEvent = await getFilterLastEventArgs(distributor, filter)
      const old = lastEvent?.oldEndpoint.toString()
      const new_ = lastEvent?.newEndpoint.toString()

      expect(updater).to.emit(distributor, 'EndpointUpdated')
      expect(old).to.be.equal("watchit.movie");
      expect(new_).to.be.equal("watchit3.movie");

    });

    it("Should fail if `updateEndpoint` is called with invalid empty endpoint.", async function () {
      const distributor = await loadFixture(deployDistributor)
      await expect(distributor.updateEndpoint('')).to.be.revertedWithCustomError(
        distributor, "InvalidEndpoint"
      );
    })

    it("Should fail if `updateEndpoint` is called with invalid owner.", async function () {
      const [, secondary] = await loadFixture(getAccounts)
      const distributor = await loadFixture(deployDistributor)
      await expect(distributor.connect(secondary).updateEndpoint('check.com')).to.be.revertedWithCustomError(
        distributor, "OwnableUnauthorizedAccount"
      );
    })
  })

});
