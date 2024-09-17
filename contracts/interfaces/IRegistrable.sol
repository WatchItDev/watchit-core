// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRegistrable
/// @dev Interface for managing data registration.
interface IRegistrable {
    /// @notice Registers data with a given identifier.
    /// @param distributor The address of the distributor to register.
    /// @param currency The currency used to pay enrollment.
    function register(address distributor, address currency) external;

    /// @notice Approves the data associated with the given identifier.
    function approve(address) external;
}
