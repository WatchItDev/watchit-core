// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title IRightsManagerPolicyHandler
/// @notice Interface for managing policies delegated by content holders under the Rights Manager.
/// @dev This interface handles authorizing, revoking, and managing the delegation of policies for content rights.
interface IRightsManagerPolicyHandler {
    /// @notice Retrieves all policies to which rights have been delegated by a specific content holder.
    /// @param holder The content rights holder whose delegated policies are being queried.
    /// @return An array of policy contract addresses that have been delegated rights by the specified content holder.
    function getContentPolicies(address holder) external view returns (address[] memory);

    /// @dev Verifies if the specified policy contract has been delegated the rights by the content holder.
    /// @param policy The address of the policy contract to check for delegation.
    /// @param holder The content rights holder to check for delegation.
    /// @return bool Returns true if the policy has been authorized by the content holder.
    function isPolicyAuthorized(address policy, address holder) external view returns (bool);

    /// @notice Initializes and authorizes a policy contract for content held by the holder.
    /// @param policy The address of the policy contract to be initialized and authorized.
    /// @param data Additional data required for initializing the policy.
    function setupPolicy(address policy, bytes calldata data) external;

    /// @notice Revokes the delegation of rights to a specific policy contract.
    /// @dev This function removes the rights delegation from the RightsStorage struct,
    ///      preventing the specified policy contract from managing rights for the content holder.
    /// @param policy The address of the policy contract whose rights delegation is being revoked.
    function revokePolicy(address policy) external;
}
