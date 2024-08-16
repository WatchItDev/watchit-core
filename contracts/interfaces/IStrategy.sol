// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

/// @title IStrategy
/// @notice Interface for managing access to content based on conditions, 
/// transactions, and distribution of royalties or fees.
interface IStrategy {
    /// @notice Verify access to for an account and content ID.
    /// @param account The address of the account to approve.
    /// @param contentId The content ID to approve against.
    function access(
        address account,
        uint256 contentId
    ) external view returns (bool);

    /// @notice Retrieves the allocation spec to distribute the royalties or fees.
    /// @param account The address of the account initiating the transaction.
    /// @param contentId The content ID related to the transaction.
    function allocation(
        address account,
        uint256 contentId
    ) external returns (T.Allocation memory);
}
