import hre from 'hardhat'
import { expect } from 'chai'
import { switcher } from './helpers/CommonHelper'
import { DistributorFactory } from '@/typechain-types'
import {
  deployDistributorFactory,
  getFilterLastEventArgs,
  commitRegister,
  attachBeaconDistributorContract,
  deployAndInitializeDistributorContract
} from './helpers/DistributorHelper'

const DISTRIBUTOR_INTERFACE_ID = '0x3a8b2846'

async function getAccounts() {
  return await hre.ethers.getSigners()
}

describe('Distributor', function () {
  describe('Beacon', function () {
    it("Should create a valid 'Distributor'.", async function () {
      const beacon = await switcher(deployDistributorFactory)
      const beaconProxy = await commitRegister(beacon, 'watchit.movie')
      const distributor = await attachBeaconDistributorContract(beaconProxy)

      expect(await distributor.supportsInterface(DISTRIBUTOR_INTERFACE_ID)).to.be.true
      expect(await distributor.getEndpoint()).to.be.equal('watchit.movie')
    })

    it("Should add a new contract to 'contracts' list.", async function () {
      const beacon = (await switcher(deployDistributorFactory)) as DistributorFactory
      const beaconProxy1 = await commitRegister(beacon, 'watchit.movie')
      const beaconProxy2 = await commitRegister(beacon, 'watchit2.movie')

      // check if the first registered contract is the same as the last event
      const contract1 = await beacon.contracts(0)
      const contract2 = await beacon.contracts(1)

      expect(contract1).to.equal(beaconProxy1)
      expect(contract2).to.equal(beaconProxy2)
    })

    it('Should add the distributor correctly in registry mapping.', async function () {
      const registeredDomain = 'watchit.movie'
      const beacon = await switcher(deployDistributorFactory)
      const [owner] = await hre.ethers.getSigners()

      await commitRegister(beacon, registeredDomain)
      const registeredOwner = await beacon.registry(registeredDomain)
      expect(registeredOwner).to.be.equal(owner)
    })

    it('Should fail if domain is already registered with DistributorAlreadyRegistered.', async function () {
      const duplicatedDomain = 'watchit.movie'
      const beacon = await switcher(deployDistributorFactory)

      await commitRegister(beacon, duplicatedDomain)
      await expect(beacon.register(duplicatedDomain)).to.be.revertedWithCustomError(
        beacon, 'DistributorAlreadyRegistered'
      )
    })

    it('Should emit a valid DistributorCreated after register distributor.', async function () {
      const beacon = await switcher(deployDistributorFactory)
      expect(beacon.register('watchit.movie')).to.emit(beacon, 'DistributorCreated')
    })

    it('Should pause/unpause properly.', async function () {
      const beacon = await switcher(deployDistributorFactory)
      const pause = await beacon.pause()
      await pause.wait()
      expect(await beacon.paused()).to.be.true

      const unpause = await beacon.unpause()
      await unpause.wait()
      expect(await beacon.paused()).to.be.false
    })
  })

  describe('Implementation', function () {
    it("Should implement a valid 'Distributor'.", async function () {
      const distributor = await deployAndInitializeDistributorContract('watchit.com')
      expect(await distributor.supportsInterface(DISTRIBUTOR_INTERFACE_ID)).to.be.true
    })

    it('Should update a valid endpoint successfully.', async function () {
      const newEndpoint = 'watchit4.movie'
      // initial endpoint set by beacon proxy initialization.
      const distributor = await deployAndInitializeDistributorContract('watchit.com')
      const updater = await distributor.setEndpoint(newEndpoint)
      await updater.wait()

      const distributorEndpoint = await distributor.getEndpoint()
      expect(newEndpoint).to.be.equal(distributorEndpoint)
    })

    it('Should emit a valid EndpointUpdated after update endpoint.', async function () {
      const newEndpoint = 'watchit3.movie'
      const distributor = await deployAndInitializeDistributorContract('watchit.movie')
      const updater = await distributor.setEndpoint(newEndpoint)
      await updater.wait()

      const filter = distributor.filters.EndpointUpdated()
      const lastEvent = await getFilterLastEventArgs(distributor, filter)
      const old = lastEvent?.oldEndpoint.toString()
      const new_ = lastEvent?.newEndpoint.toString()

      expect(updater).to.emit(distributor, 'EndpointUpdated')
      expect(old).to.be.equal('watchit.movie')
      expect(new_).to.be.equal('watchit3.movie')
    })

    it('Should fail if `updateEndpoint` is called with invalid empty endpoint.', async function () {
      const distributor = await deployAndInitializeDistributorContract('watchit.movie')
      await expect(distributor.setEndpoint('')).to.be.revertedWithCustomError(
        distributor, 'InvalidEndpoint'
      )
    })

    it('Should fail if `updateEndpoint` is called with invalid owner.', async function () {
      const [, secondary] = await switcher(getAccounts)
      const distributor = await deployAndInitializeDistributorContract('watchit.movie')
      await expect(distributor.connect(secondary).setEndpoint('check.com')).to.be.revertedWithCustomError(
        distributor, 'OwnableUnauthorizedAccount'
      )
    })
  })


})
