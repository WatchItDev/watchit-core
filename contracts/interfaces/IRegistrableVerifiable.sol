// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Registrable Verifiable Interface
/// @notice This interface defines the method for checking if an entity is active.
interface IRegistrableVerifiable {
    /// @notice Checks if the entity associated with the given identifier is active.
    function isActive(address) external returns (bool);
}
