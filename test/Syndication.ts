import hre from 'hardhat'
import { expect } from 'chai'
import type * as ethers from 'ethers'

import { deployInitializedSyndication, expectedFees, expectedPenaltyBPS } from './helpers/SyndicationHelper'
import { deployAndAttachDistributor } from './helpers/DistributorHelper'
import { switcher, getAccounts } from './helpers/CommonHelper'

async function deploySyndicationWithFakeGovernor() {
  const [owner] = await getAccounts()
  const [syndication, treasury, currency] = await switcher(deployInitializedSyndication)

  // !IMPORTANT the approval is only allowed for governance
  // A VALID GOVERNOR IS SET IN A REAL USE CASE..
  // eg: https://docs.openzeppelin.com/contracts/4.x/api/governance#GovernorTimelockControl
  // set the owner address as governor for test purposes..
  await (await syndication.setGovernance(owner)).wait()
  return [syndication, treasury, currency]
}

// helper function to approve a distributor by "governance"
async function deploySyndicationWithRegisteredDistributor() {
  const distributorContract = await switcher(deployAndAttachDistributor)
  const [syndication, , currency] = await deploySyndicationWithFakeGovernor();
  // first we need approve MMC fees syndication contract
  const syndicationAddress = await syndication.getAddress()
  const distAddress = await distributorContract.getAddress()
  await (await currency.approve(syndicationAddress, expectedFees())).wait()
  // register account and approve by "governance" 
  await (await syndication.register(distAddress, currency)).wait()
  return [syndication, distributorContract, currency];
}

describe('Syndication', function () {

  describe("Initialization", async () => {
    it('Should have been initialized with the right penalty rate and corresponding currency.', async function () {
      const [syndication, , currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()
      expect(await syndication.penaltyRates(currencyAddress)).to.be.equal(expectedPenaltyBPS()) // 10% nominal = 1000 bps
    })

    // it('Should have been initialized with the right treasury address.', async function () {
    //   const [syndication, repo] = await switcher(deployInitializedSyndication)
    //   const expectedTreasuryAddress = await repo.getContract(3) // 3 = ENUM TREASURY
    //   expect(await syndication.getTreasuryAddress()).to.be.equal(expectedTreasuryAddress)
    // })

    it('Should have been initialized with the right initial fees.', async function () {
      // hre.ethers.ZeroAddress means native coin..
      const [syndication, , currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()
      const initialFees = await syndication.getFees(currencyAddress)
      expect(initialFees).to.be.equal(expectedFees())
    })
  })


  describe('Penalty Rate', function () {

    it('Should set the penalty rate successfully', async () => {
      const [syndication, , currency] = await deploySyndicationWithFakeGovernor()
      const currencyAddress = await currency.getAddress()
      await syndication.setPenaltyRate(1500, currencyAddress) // MMC 15% nominal = 1500 bps
      expect(await syndication.penaltyRates(currencyAddress)).to.be.equal(1500) // MMC 15% nominal = 1500 bps
    })

    it('Should fail setting penalty rate if is not a base points', async () => {
      const [syndication, , currency] = await deploySyndicationWithFakeGovernor()
      const currencyAddress = await currency.getAddress()
      // min = 1 = 0.01; max = 10_000 = 100%
      await expect(syndication.setPenaltyRate(10_001, currencyAddress)).to.revertedWithCustomError(syndication, 'InvalidBasisPointRange')
    })

    it('Should fail setting penalty rate if not called by governor', async () => {
      const [syndication, , currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()
      await expect(syndication.setPenaltyRate(1500, currencyAddress)).to.revertedWithCustomError(
        syndication, 'AccessControlUnauthorizedAccount'
      )
    })
  })

  describe("Treasury Impl", () => {
    it('Should set the currency treasury fee successfully.', async function () {
      const [syndication, , currency] = await deploySyndicationWithFakeGovernor()
      const currencyAddress = await currency.getAddress()
      await (await syndication.setFees(expectedFees(), currencyAddress)).wait()
      expect(await syndication.getFees(currencyAddress)).to.be.equal(expectedFees()); //100 MMC
    })

  })

  describe("Treasurer Impl", () => {
    it('Should set the treasury address successfully.', async function () {
      const [sampleTestAddress,] = await getAccounts()
      // only governance can do this..
      const [syndication,] = await deploySyndicationWithFakeGovernor()
      await (await syndication.setTreasuryAddress(sampleTestAddress)).wait()
      expect(await syndication.getTreasuryAddress()).to.be.equal(sampleTestAddress);
    })

    it('Should collect funds and send them to treasury address successfully.', async function () {
      const [syndication, , currency] = await deploySyndicationWithRegisteredDistributor()
      const currencyAddress = await currency.getAddress()
      // the fees paid during registration. 
      // check in deploySyndicationWithRegisteredDistributor for more..
      const treasuryAddress = await syndication.getTreasuryAddress()
      await (await syndication.disburse(expectedFees(), currencyAddress)).wait()

      const filter = syndication.filters.FeesDisbursed()
      const events = await syndication.queryFilter(filter)
      const lastEvent = events.pop() as ethers.EventLog

      expect(lastEvent.args[0]).to.be.equal(treasuryAddress);
      expect(lastEvent.args[1]).to.be.equal(expectedFees());
      expect(lastEvent.args[2]).to.be.equal(currencyAddress);
    })
  })

  describe('Register', function () {

    it('Should emit Registered event after register successfully.', async function () {
      const distributor = await switcher(deployAndAttachDistributor)
      const [syndication, , currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()
      const syndicationAddress = await syndication.getAddress()
      const distributorAddress = await distributor.getAddress()
      // first we need approve MMC fees syndication contract
      await (await currency.approve(syndicationAddress, expectedFees())).wait()
      await expect(syndication.register(distributorAddress, currencyAddress)).to.emit(syndication, 'Registered')
    })

    it('Should fail register with invalid MMC allowance.', async function () {
      const distributor = await switcher(deployAndAttachDistributor)
      const [syndication, , currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()
      const distributorAddress = await distributor.getAddress()

      await expect(
        syndication.register(distributorAddress, currencyAddress)
      ).to.be.revertedWithCustomError(
        syndication, 'FailDuringTransfer'
      ).withArgs("Invalid allowance.")
    })

    it('Should register enrollment fees to distributor manager.', async function () {
      const distributor = await switcher(deployAndAttachDistributor)
      const [syndication, , currency] = await switcher(deployInitializedSyndication)

      const manager = await distributor.getManager()
      const currencyAddress = await currency.getAddress()
      const syndicationAddress = await syndication.getAddress()
      const distributorAddress = await distributor.getAddress()

      await (await currency.approve(syndicationAddress, expectedFees())).wait()
      await (await syndication.register(distributorAddress, currencyAddress)).wait()
      expect(await syndication.getLedgerBalance(manager, currencyAddress)).to.equal(expectedFees())
    })

    it('Should set waiting state during valid Distributor register.', async function () {
      const distributor = await switcher(deployAndAttachDistributor)
      const [syndication, , currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()
      const syndicationAddress = await syndication.getAddress()
      const distributorAddress = await distributor.getAddress()

      await (await currency.approve(syndicationAddress, expectedFees())).wait()
      await (await syndication.register(distributorAddress, currencyAddress)).wait()
      expect(await syndication.isWaiting(distributorAddress)).to.be.true
    })


    it('Should fail with InvalidDistributorContract.', async function () {
      const invalidDistributor = hre.ethers.ZeroAddress // invalid contract
      const [syndication, , currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()

      await expect(
        syndication.register(invalidDistributor, currencyAddress)
      ).to.be.revertedWithCustomError(
        syndication, 'InvalidDistributorContract'
      )
    })

    it('Should subtract the correct enrollment fees amount.', async function () {
      const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
      const [owner] = await getAccounts()
      const [distributorAddress] = await switcher(deployAndAttachDistributor)
      const [syndication,, currency] = await switcher(deployInitializedSyndication)
      const currencyAddress = await currency.getAddress()

      // the balance before register contract..
      // TODO refactorizar y pasar a una funcion el approve register
      
      const initialRegisterBalance = await hre.ethers.provider.getBalance(owner.address)
      const registerTx = await (await syndication.register(distributorAddress, currencyAddress)).wait()

      const { gasPrice: quitGasPrice, gasUsed: quitGasUsed } = registerTx;
      const totalRegisterGasPrice = BigInt(quitGasPrice * quitGasUsed);
      const afterRegisterBalance = await hre.ethers.provider.getBalance(owner.address)

      const netRegisterBalance = (initialRegisterBalance - totalRegisterGasPrice)
      const expectedAfterRegisterBalance = netRegisterBalance - fees;
      expect(afterRegisterBalance).to.equal(expectedAfterRegisterBalance);
    })
  })

  describe('Quit', function () {
    it('Should emit Resigned event after quit successfully.', async function () {
      const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
      const [distributorAddress] = await switcher(deployAndAttachDistributor)
      const [syndication] = await switcher(deployInitializedSyndication)
      // const registeredDistributor = await distributorRegisteredWithLastEvent(syndication)
      await syndication.register(distributorAddress, { value: fees })
      expect(await syndication.quit(distributorAddress)).to.emit(syndication, 'Resigned')
    })

    it('Should fail quit with FailDuringQuit invalid enrollment.', async function () {
      const [distributorAddress] = await switcher(deployAndAttachDistributor)
      const [syndication] = await switcher(deployInitializedSyndication)
      // const registeredDistributor = await distributorRegisteredWithLastEvent(syndication)
      await expect(syndication.quit(distributorAddress)).to.be.revertedWithCustomError(
        syndication, 'FailDuringQuit' // no registered enrollment
      )
    })

    it('Should retain the correct penalty amount after quit.', async function () {
      const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
      const [distributorAddress] = await switcher(deployAndAttachDistributor)
      const [syndication] = await switcher(deployInitializedSyndication)

      // register the distributor
      await (await syndication.register(distributorAddress, { value: fees })).wait()
      // receive the enrollment fees..
      const afterRegisterBalance = await hre.ethers.provider.getBalance(await syndication.getAddress())
      // quit after enrollment after some time X.
      await (await syndication.quit(distributorAddress)).wait()
      // rollback the enrollment fees minus a penalty..
      const afterQuitBalance = await hre.ethers.provider.getBalance(await syndication.getAddress())

      // 1000 bps = 10% nominal
      // original fees paid on registration - 10% penalty
      const penal = (fees * BigInt(1000)) / BigInt(10000)
      expect(afterRegisterBalance).to.be.equal(fees)
      // the contract keep the 10%
      expect(afterQuitBalance).to.be.equal(penal)
    })

    it('Should fail with InvalidDistributorContract.', async function () {
      const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
      const invalidDistributor = hre.ethers.ZeroAddress // invalid contract
      const [distributorAddress] = await switcher(deployAndAttachDistributor)
      const [syndication] = await switcher(deployInitializedSyndication)

      // register a valid distributor then attemp quit with an invalid one.
      await (await syndication.register(distributorAddress, { value: fees })).wait()
      await expect(syndication.quit(invalidDistributor)).to.be.revertedWithCustomError(
        syndication, 'InvalidDistributorContract'
      )
    })

    it('Should revert the correct amount to manager after quit.', async function () {
      const [owner] = await getAccounts()
      const fees = hre.ethers.parseUnits('0.3', 'ether') // expected fees paid in contract..
      const [distributorAddress] = await switcher(deployAndAttachDistributor)
      const [syndication] = await switcher(deployInitializedSyndication)

      // the balance before register contract..
      await (await syndication.register(distributorAddress, { value: fees })).wait()
      const afterRegisterBalance = await hre.ethers.provider.getBalance(owner.address)

      // // quit after enrollment after some time X.
      const quitTx = await (await syndication.quit(distributorAddress)).wait()
      const { gasPrice: quitGasPrice, gasUsed: quitGasUsed } = quitTx;
      const totalQuitGasPrice = BigInt(quitGasPrice * quitGasUsed);

      // rollback the enrollment fees minus a penalty..
      const afterQuitBalance = await hre.ethers.provider.getBalance(owner.address)

      // fees - penal
      const residue = fees - (fees * BigInt(1000)) / BigInt(10000);
      const netQuitBalance = (afterRegisterBalance - totalQuitGasPrice)
      const expectedAfterRegisterBalance = netQuitBalance + residue;
      expect(afterQuitBalance).to.equal(expectedAfterRegisterBalance);
    })

    it('Should set zero enrollment fees after quit.', async function () {
      const fees = hre.ethers.parseUnits('0.3', 'ether')
      const [distributorAddress, distributorContract] = await switcher(deployAndAttachDistributor)
      const [syndication] = await switcher(deployInitializedSyndication)
      await (await syndication.register(distributorAddress, { value: fees })).wait()
      await (await syndication.quit(distributorAddress)).wait()

      const manager = await distributorContract.getManager()
      expect(await syndication.getLedgerBalance(manager, hre.ethers.ZeroAddress)).to.equal(0)
    })
  })

  describe('Approve', function () {

    it('Should emit Approved event after approve successfully.', async function () {
      const [syndication, , distributorAddress] = await deploySyndicationWithRegisteredDistributor()
      expect(await syndication.approve(distributorAddress)).to.emit(syndication, 'Approved')
    })

    it('Should set zero enrollment fees after approval.', async function () {
      const [syndication, distributorContract, distributorAddress] = await deploySyndicationWithRegisteredDistributor()
      await (await syndication.approve(distributorAddress)).wait()
      const manager = await distributorContract.getManager()
      expect(await syndication.getLedgerBalance(manager, hre.ethers.ZeroAddress)).to.equal(0)
    })

    it('Should set valid active state after approval.', async function () {
      const [syndication, , distributorAddress] = await deploySyndicationWithRegisteredDistributor()
      await (await syndication.approve(distributorAddress)).wait()
      expect(await syndication.isActive(distributorAddress)).to.be.true
    })

    it('Should increment the enrollment count successfully.', async function () {
      const [syndication, , distributorAddress] = await deploySyndicationWithRegisteredDistributor()

      const prevCount = await syndication.enrollmentsCount()
      await (await syndication.approve(distributorAddress)).wait()
      expect(await syndication.enrollmentsCount()).to.be.equal(prevCount + BigInt(1))
    })
  })

  describe.skip('Revoke', function () {
    it('Should emit Revoked event after revoked successfully.', async function () {
      const [syndication, , distributorAddress] = await deploySyndicationWithRegisteredDistributor()
      await (await syndication.approve(distributorAddress)).wait()
      expect(await syndication.revoke(distributorAddress)).to.emit(syndication, 'Revoked')
    })

    it('Should set valid revoked state after approval.', async function () {
      const [syndication, , distributorAddress] = await deploySyndicationWithRegisteredDistributor()
      await (await syndication.approve(distributorAddress)).wait()
      await (await syndication.revoke(distributorAddress)).wait()
      expect(await syndication.isBlocked(distributorAddress)).to.be.true
    })
  })


})
