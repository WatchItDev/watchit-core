// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsPolicyController {
    /// @notice Retrieves all policies to which rights have been delegated by a specific content holder.
    /// @param holder The content rights holder whose delegated policies are being queried.
    /// @return An array of policy contract addresses that have been delegated rights by the specified content holder.
    function getContentPolicies(
        address holder
    ) external view returns (address[] memory);

    /// @dev Verify if the specified policy contract has been delegated the rights by the content holder.
    /// @param policy The address of the policy contract to check for delegation.
    /// @param holder The content rights holder to check for delegation.
    /// Reverts if the rights have not been delegated for the specified content ID.
    function isPolicyAuthorized(
        address policy,
        address holder
    ) external view returns (bool);
}
