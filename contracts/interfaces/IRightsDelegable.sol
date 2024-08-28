// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsDelegable {
    /// @notice Delegates rights for a specific content ID to a grantee.
    /// @param grantee The address of the account or contract to delegate rights to.
    /// @param contentId The content ID for which rights are being delegated.
    function delegateRights(address grantee, uint256 contentId) external;

    /// @notice Revokes the delegation of rights for a grantee.
    /// @param grantee The address of the account or contract to revoke rights to.
    /// @param contentId The content ID for which rights are being revoked.
    function revokeRights(address grantee, uint256 contentId) external;

    /// @notice Retrieves all content IDs for which rights have been delegated to a grantee.
    /// @param grantee The address of the account or contract whose delegated rights are being queried.
    /// @return An array of content IDs that have been delegated to the specified grantee.
    function getDelegatedRights(
        address grantee
    ) external view returns (uint256[] memory);
}
