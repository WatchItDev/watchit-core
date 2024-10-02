// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ILedger Interface
/// @notice This interface defines the functionality for retrieving ledger entries for accounts.
/// @dev The interface is intended to be implemented by contracts that track registered fund amounts for specific accounts and currencies.
interface ILedger {
    /// @notice Retrieves the registered currency amount for the specified account.
    /// @param account The address of the account.
    /// @param currency The address of the currency to retrieve ledger amount (use address(0) for the native currency).
    /// @return The amount of registered fund for the account in the specified currency.
    function getLedgerBalance(address account, address currency) external view returns (uint256);
}
