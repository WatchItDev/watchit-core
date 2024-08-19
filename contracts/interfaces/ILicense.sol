// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

/// @title ILicense
/// @notice Interface for managing access to content based on licensing terms, 
/// transactions, and distribution of royalties or fees.
interface ILicense {
    /// @notice Verify whether the access terms for an account and content ID are satisfied
    /// @param account The address of the account to check.
    /// @param contentId The content ID to check against.
    function terms(
        address account,
        uint256 contentId
    ) external view returns (bool);

    /// @notice Retrieves the allocation specification to distribute the royalties or fees.
    /// @param account The address of the account initiating the transaction.
    /// @param contentId The content ID related to the transaction.
    function allocation(
        address account,
        uint256 contentId
    ) external returns (T.Allocation memory);
}
