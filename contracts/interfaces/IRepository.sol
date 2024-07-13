// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

/**
 * @title Repository Consumer Interface
 * @notice This interface defines common types used for interacting with the repository.
 */
interface IRepositoryConsumer {
    /**
     * @notice Enum representing different contract types.
     */
    enum ContractTypes {
        __,          // Undefined type
        OWNERSHIP,   // Ownership contract
        SYNDICATION, // Syndication contract
        DRM          // Digital Rights Management contract
    }
}

/**
 * @title Repository Interface
 * @notice This interface defines the methods for a repository to manage and query contract addresses.
 * @dev This interface extends the IRepositoryConsumer interface to include contract types.
 */
interface IRepository is IRepositoryConsumer {
    /**
     * @notice Returns the address of the contract registered under the given key.
     * @param key The key associated with the contract address.
     * @return The address of the registered contract.
     * @dev Reverts if the contract is not registered.
     */
    function getContract(ContractTypes key) external view returns (address);
}