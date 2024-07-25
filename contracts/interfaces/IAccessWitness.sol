// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAccessWitness
/// @notice Interface for an access witness that manages approval of conditions for content.
/// @dev This interface defines the methods to approve conditions for accounts and content IDs.
interface IAccessWitness {
    /// @notice Approves a specific condition for an account and content ID.
    /// @dev This function approves the condition and returns a boolean indicating the result.
    /// @param account The address of the account to approve.
    /// @param contentId The content ID to approve against.
    /// @return bool True if the condition is approved, false otherwise.
    function approve(
        address account,
        uint256 contentId
    ) external view returns (bool);
}
