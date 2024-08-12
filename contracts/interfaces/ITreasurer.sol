// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITreasurer {
    /**
     * @notice Sets the address of the treasury.
     * @param newTreasuryAddress The new address of the treasury.
     */
    function setTreasuryAddress(address newTreasuryAddress) external;

    /**
     * @notice Gets the current address of the treasury.
     * @return The address of the treasury.
     */
    function getTreasuryAddress() external view returns (address);

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
