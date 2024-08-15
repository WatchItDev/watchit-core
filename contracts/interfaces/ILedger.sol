// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILedger {

    /**
     * @notice Retrieves the registered coin amount for the specified account.
     * @param account The address of the account.
     * @return The amount of registered coins for the account.
     */
    function getLedgerEntry(address account) external view returns (uint256);

    /**
     * @notice Retrieves the registered token amount for the specified account.
     * @param account The address of the account.
     * @param token The token to retrieve ledger amount.
     * @return The amount of registered tokens for the account and specified token.
     */
    function getLedgerEntry(
        address account,
        address token
    ) external view returns (uint256);
}
