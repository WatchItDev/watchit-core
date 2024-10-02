// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IRightsManagerAccessController {
    /// @notice Retrieves the first active policy for a specific account, rights holder, and content in LIFO order.
    /// @param account The address of the account to evaluate.
    /// @param contentId The ID of the content to evaluate policies for.
    function getActivePolicy(address account, uint256 contentId) external returns (bool, address);

    /// @notice Retrieves the list of policys associated with a specific account and content ID.
    /// @param account The address of the account for which policies are being retrieved.
    /// @return An array of addresses representing the policies associated with the account and content ID.
    function getPolicies(address account) external view returns (address[] memory);

    /// @notice Finalizes the agreement by registering the agreed-upon policy, effectively closing the agreement.
    /// @param proof The unique identifier of the agreement to be enforced.
    /// @param policyAddress The address of the policy contract managing the agreement.
    /// @param data Additional data required to execute the agreement.
    function registerPolicy(bytes32 proof, address policyAddress, bytes calldata data) external payable;
}
