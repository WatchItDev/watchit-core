// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

/// @title IStrategy
/// @notice Interface for managing access to content based on conditions, transactions, and distribution of royalties or fees.
interface IStrategy {
    /// @notice Approves a specific condition for an account and content ID.
    /// @param account The address of the account to approve.
    /// @param contentId The content ID to approve against.
    /// @return bool True if the condition is approved, false otherwise.
    function approved(
        address account,
        uint256 contentId
    ) external view returns (bool);

    /// @notice Executes a transaction for a given account and content ID.
    /// @param account The address of the account initiating the transaction.
    /// @param contentId The content ID related to the transaction.
    /// @return T.Transaction A transaction object containing the currency and total amount transferred.
    function transaction(
        address account,
        uint256 contentId
    ) external view returns (T.Transaction);

    /// @notice Retrieves the distribution spec to distribute the royalties or fees.
    /// @param tx_ The transaction object containing information about the current transaction.
    /// @return T.Distribution[] An array representing the distribution of royalties or fees.
    function allocation(
        T.Transaction tx_
    ) external view returns (T.Allocation[] memory);
}
