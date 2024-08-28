// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

/// @title IPolicy
/// @notice Interface for managing access to content based on licensing terms,
interface IPolicy {
    /// @notice Returns the string identifier associated with the policy.
    function name() external pure returns (string memory);

    /// @notice Retrieves the access terms for a specific account and content ID.
    /// @param account The address of the account for which access terms are being retrieved.
    /// @param contentId The ID of the content associated with the access terms.
    /// @return The access terms as a `bytes` array, which can contain any necessary data for validating on-chain or off-chain access.
    /// eg: PILTerms https://docs.story.foundation/docs/pil-terms
    function terms(
        address account,
        uint256 contentId
    ) external view returns (bytes memory);

    /// @notice Verify whether the on-chain access terms for an account and content ID are satisfied.
    /// @param account The address of the account to check.
    /// @param contentId The content ID to check against.
    function comply(
        address account,
        uint256 contentId
    ) external view returns (bool);

    /// @notice Retrieves the payout allocation for a specific account and content ID.
    /// @param account The address of the account for which the payout allocation is being retrieved.
    /// @param contentId The ID of the content associated with the payout allocation.
    /// @return The payout allocation specified for the account and content.
    function payouts(
        address account,
        uint256 contentId
    ) external view returns (T.Payouts memory);
}
