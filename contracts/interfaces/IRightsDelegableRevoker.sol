// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsDelegableRevoker {

    /// @notice Revokes the delegation of rights for a grantee.
    /// @param grantee The address of the account or contract to revoke rights to.
    /// @param contentId The content ID for which rights are being revoked.
    function revokeRights(address grantee, uint256 contentId) external;

}
