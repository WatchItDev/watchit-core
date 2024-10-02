// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ISyndicatableExpirable
/// @dev Interface for contracts that allow setting an expiration period for enrollments or registrations.
interface ISyndicatableExpirable {
    /// @dev Sets a new expiration period for an enrollment or registration.
    /// @param newPeriod The new expiration period in seconds.
    function setPeriod(uint256 newPeriod) external;
}
