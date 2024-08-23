// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

/// @title IPolicy
/// @notice Interface for managing access to content based on licensing terms,
/// eg: transactions and distribution of royalties or fees.
interface IPolicy {
    /// @notice Returns the string identifier associated with the policy.
    function name() external returns (string memory);

    /// @notice Retrieves the access terms for a specific account and content ID.
    /// @param account The address of the account for which access terms are being retrieved.
    /// @param contentId The ID of the content associated with the access terms.
    /// @return T.Terms The terms that apply to the specified account and content.
    function terms(
        address account,
        uint256 contentId
    ) external view returns (T.Terms);

    /// @notice Verify whether the access terms for an account and content ID are satisfied
    /// @param account The address of the account to check.
    /// @param contentId The content ID to check against.
    function comply(
        address account,
        uint256 contentId
    ) external view returns (bool);
}
