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
    /// @return The access terms as a `bytes` array, which can contain any necessary data 
    /// for validating on-chain or off-chain access. eg: PILTerms https://docs.story.foundation/docs/pil-terms
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

    /// @notice Process the deal between the content holder and the account based on the policy's rules.
    /// @dev This method is expected to be called only by RM contract and its used to establish
    /// any logic related to access, validations, etc...
    /// @param deal The deal object containing the terms agreed upon between the content holder and the account.
    /// @param data Additional data required for processing the deal. 
    /// @return bool A boolean indicating whether the deal was successfully executed (`true`) or not (`false`).
    /// @return string A message providing context for the execution result.
    function process(
        T.Deal calldata deal,
        bytes calldata data
    ) external returns (bool, string memory);

    /// @notice Retrieves the shares allocation for a specific deal.
    /// @return T.Shares A struct containing the shares allocation details, 
    /// which include the distribution of funds.
    function shares() external view returns (T.Shares[] memory);
}
