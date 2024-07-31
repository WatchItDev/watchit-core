// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;
import "contracts/libraries/constants/Types.sol";

/**
 * @title Repository Interface
 * @notice This interface defines the methods for a repository to manage and query contract addresses.
 */
interface IRepository {
    /**
     * @notice Returns the address of the contract registered under the given key.
     * @param key The key associated with the contract address.
     * @return The address of the registered contract.
     * @dev Reverts if the contract is not registered.
     */
    function getContract(T.ContractTypes key) external view returns (address);
}
