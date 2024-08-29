// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAccessController {
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
