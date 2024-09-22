// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ISyndicatableRegistrable
/// @dev Interface for managing distributors registration.
interface ISyndicatableRegistrable {
    /// @notice Registers data with a given identifier.
    /// @param distributor The address of the distributor to register.
    /// @param currency The currency used to pay enrollment.
    function register(address distributor, address currency) external;

    /// @notice Approves the data associated with the given identifier.
    /// @param distributor The address of the distributor to approve.
    function approve(address distributor) external;
}
