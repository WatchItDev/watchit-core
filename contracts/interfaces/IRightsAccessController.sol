// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAccessController {
    /// @notice Registers and enforces access for a specific account to a content ID based on the conditions set by a policy.
    /// @param account The address of the account to be granted access to the content.
    /// @param contentId The unique identifier of the content for which access is being registered.
    /// @param policy The address of the policy contract responsible for validating and enforcing the access conditions.
    /// @dev Access is granted only if the specified policy contract is valid and has the necessary delegation rights.
    /// If the policy conditions are not met, access will not be registered, and the operation will be rejected.
    function registerPolicy(
        uint256 contentId,
        address policy,
        address account
    ) external payable;

    /// @notice Removes a specific policy associated with a given content ID.
    /// @dev This function allows the removal of a policy from the list of policies linked to a specific content ID.
    /// @param contentId The ID of the content from which the policy is to be removed.
    /// @param policy The address of the policy that needs to be removed.
    /// @return True if the policy was removed succesfully, false otherwise.
    function removePolicy(uint256 contentId, address policy) external;

    /// @notice Retrieves the first active policy for a specific user and content in LIFO order.
    /// @param account The address of the account to evaluate.
    /// @param contentId The content ID to evaluate policies for.
    /// @return A tuple containing:
    /// - A boolean indicating whether an active policy was found (`true`) or not (`false`).
    /// - The address of the active policy if found, or `address(0)` if no active policy is found.
    function getActivePolicy(
        address account,
        uint256 contentId
    ) external returns (bool, address);

    /// @notice Retrieves the list of policys associated with a specific account and content ID.
    /// @param account The address of the account for which policies are being retrieved.
    /// @param contentId The ID of the content for which policies are being retrieved.
    /// @return An array of addresses representing the policies associated with the account and content ID.
    function getPolicies(
        address account,
        uint256 contentId
    ) external view returns (address[] memory);
}
