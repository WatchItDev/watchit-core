// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRegistrableExpirable
/// @dev Interface for contracts that allow setting an expiration period for enrollments or registrations.
interface IRegistrableExpirable {
    /// @dev Sets a new expiration period for an enrollment or registration.
    /// @param newPeriod The new expiration period in seconds.
    function setPeriod(uint256 newPeriod) external;
}
