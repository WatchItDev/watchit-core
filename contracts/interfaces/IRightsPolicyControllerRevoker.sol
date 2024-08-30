// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsPolicyControllerRevoker {
    /// @notice Revokes operational rights for a specific policy related to a content ID.
    /// @param policy The address of the policy contract for which rights are being revoked.
    /// @param contentId The ID of the content associated with the policy being revoked.
    function revokeRights(address policy, uint256 contentId) external;
}
