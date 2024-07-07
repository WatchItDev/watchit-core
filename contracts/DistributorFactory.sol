// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./Distributor.sol";

/// @title Distributor factory contract.
/// @notice Use this contract to create new distributors.
/// @dev This contract uses OpenZeppelin's Ownable and Pausable contracts for access control and pausing functionality.
contract DistributorFactory is Ownable, Pausable {
    /// @notice Array to store addresses of created distributor contracts.
    address[] public contracts;
    /// @notice Mapping to keep track of registered distributor endpoints.
    mapping(string => address) public registry;

    /// @notice Event emitted when a new distributor is created.
    /// @param distributor The address of the newly created distributor contract.
    event DistributorCreated(address distributor);
    /// @notice Error to be thrown when attempting to register an already registered distributor.
    error DistributorAlreadyRegistered();

    /// @notice Constructor to initialize the Ownable and Pausable contracts.
    constructor() Ownable(_msgSender()) Pausable() {}

    /// @notice Function to pause the contract, preventing the creation of new distributors.
    /// @dev Can only be called by the owner of the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Function to unpause the contract, allowing the creation of new distributors.
    /// @dev Can only be called by the owner of the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Function to create a new distributor contract.
    /// @dev The contract must not be paused to call this function.
    /// @param _endpoint The endpoint associated with the new distributor.
    function register(string calldata _endpoint) external whenNotPaused {
        // not allowed duplicated endpoints
        if (registry[_endpoint] != address(0))
            revert DistributorAlreadyRegistered();

        address newContract = address(new Distributor(_endpoint));
        registry[_endpoint] = _msgSender();
        contracts.push(newContract);
        emit DistributorCreated(newContract);
    }
}