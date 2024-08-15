// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsDelegable {
    /// @notice Delegates rights for a specific content ID to a grantee.
    /// @param grantee The address of the account or contract to delegate rights to.
    /// @param contentId The content ID for which rights are being delegated.
    function grantRights(address grantee, uint256 contentId) external;

    /// @notice Revokes the delegation of rights for a grantee.
    /// @param grantee The address of the account or contract whose delegation is being revoked.
    function revokeRights(address grantee) external;

    /// @notice Checks if rights for a specific content ID have been delegated to a grantee.
    /// @param grantee The address of the account or contract to check.
    /// @param contentId The content ID to check for delegation.
    /// @return bool True if rights have been delegated to the grantee for the specified content ID, false otherwise.
    function isDelegated(address grantee, uint256 contentId) external view returns (bool);

    /// @notice Returns the content ID that has been delegated to a grantee.
    /// @param grantee The address of the account or contract to check.
    /// @return uint256 The content ID that has been delegated to the grantee, or 0 if no delegation exists.
    function getDelegatedContent(address grantee) external view returns (uint256);
}
