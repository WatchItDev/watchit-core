// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRegistrable
/// @dev Interface for managing data registration.
interface IRegistrable {
    /// @notice Registers data with a given identifier.
    function register(address) external payable;
    /// @notice Approves the data associated with the given identifier.
    function approve(address) external;
}
