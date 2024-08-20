// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILedger {

    /// @notice Retrieves the registered currency amount for the specified account.
    /// @param account The address of the account.
    /// @param currency The currency to retrieve ledger amount.
    /// @return The amount of registered fund for the account.
    function getLedgerEntry(
        address account,
        address currency
    ) external view returns (uint256);
}
