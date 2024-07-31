
import hre from 'hardhat'
import type * as ethers from 'ethers'
import { Distributor, DistributorFactory } from '@/typechain-types'
import { switcher } from './CommonHelper'

export async function deployDistributor () {
  // Distributor implementation
  const implementationContract = await hre.ethers.getContractFactory('Distributor')
  const deployedImplementation = await implementationContract.deploy()
  await deployedImplementation.waitForDeployment()
  return deployedImplementation
}

export async function deployDistributorFactory () {
  // Distributor implementation
  const deployedImplementation = await deployDistributor()
  const implementationAddress = deployedImplementation.getAddress()

  const beaconContract = await hre.ethers.getContractFactory('DistributorFactory')
  const beacon = await beaconContract.deploy(implementationAddress)
  await beacon.waitForDeployment()
  return beacon
}

export async function getFilterLastEventArgs (contract: DistributorFactory | Distributor, filter: any) {
  // filter the emitted distributor created event
  const events = await contract.queryFilter(filter)
  const lastEvent = events.pop() as ethers.EventLog
  return lastEvent?.args
}

export async function attachBeaconDistributorContract (beaconProxy: string) {
  const contractFactory = await hre.ethers.getContractFactory('Distributor')
  const distributor = contractFactory.attach(beaconProxy) as Distributor
  return distributor
}

export async function deployAndInitializeDistributorContract (endpoint: string) {
  const [owner] = await hre.ethers.getSigners()
  // initial endpoint set by beacon proxy initialization.
  const distributor = await switcher(deployDistributor)
  await distributor.initialize(endpoint, owner)
  return distributor as Distributor
}

export async function distributorCreatedWithLastEvent (factory: DistributorFactory) {
  const distributorFilter = factory.filters.DistributorCreated()
  const lastEvent = await getFilterLastEventArgs(factory, distributorFilter)
  return lastEvent?.distributor.toString()
}

export async function commitRegister (factory: DistributorFactory, domain: string) {
  // filter indexed event the emitted distributor created event
  await (await factory.register(domain)).wait()
  // Unfortunately, it's not possible to get the return value of a state-changing function outside the off-chain.
  return await distributorCreatedWithLastEvent(factory)
}
