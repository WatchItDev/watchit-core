// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsPolicyControllerAuthorizer {
    /// @notice Grants operational rights for a specific content ID to a policy.
    /// @param policy The address of the policy contract to which the rights are being granted.
    /// @param contentId The ID of the content for which the rights are being granted.
    function grantRights(address policy, uint256 contentId) external;
}
