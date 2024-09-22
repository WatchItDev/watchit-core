// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IReferendumVerifiable.sol";
import "./IReferendumRoleManager.sol";

/// @title Referendum Interface
/// @notice This interface defines the essential functions for a referendum contract.
/// @dev Implement this interface to create a referendum contract.
interface IReferendum is IReferendumVerifiable, IReferendumRoleManager {
    /// @notice Submits a new proposition for referendum.
    /// @param contentId The ID of the content to be submitted.
    /// @param initiator The address of the initiator submitting the content.
    function submit(uint256 contentId, address initiator) external;

    /// @notice Approves a proposition in the referendum.
    /// @param contentId The ID of the content to be approved.
    function approve(uint256 contentId) external;

    /// @notice Rejects a proposition in the referendum.
    /// @param contentId The ID of the content to be rejected.
    function reject(uint256 contentId) external;
}
