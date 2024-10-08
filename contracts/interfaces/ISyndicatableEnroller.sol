// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ISyndicatableEnroller
/// @dev Interface for retrieving enrollment-related information for a distributor.
interface ISyndicatableEnroller {
    /// @notice Retrieves the enrollment time for a distributor, based on the current block time and expiration period.
    /// @param distributor The address of the distributor.
    /// @return The enrollment time in seconds.
    function getEnrollmentTime(address distributor) external view returns (uint256);

    /// @notice Retrieves the total number of enrollments.
    /// @return The count of enrollments.
    function getEnrollmentCount() external view returns (uint256);
}
