// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ISyndicatableExpirable
/// @dev Interface for contracts that manage expiration periods for enrollments or registrations.
interface ISyndicatableExpirable {
    /// @notice Sets a new expiration period for an enrollment or registration.
    /// @param newPeriod The new expiration period, in seconds.
    function setExpirationPeriod(uint256 newPeriod) external;

    /// @notice Retrieves the current expiration period for enrollments or registrations.
    /// @return The expiration period, in seconds.
    function getExpirationPeriod() external view returns (uint256);

}
