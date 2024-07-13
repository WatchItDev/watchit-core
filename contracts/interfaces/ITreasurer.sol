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
     * @notice Collects native funds and sends them to the treasury.
     */
    function collectFunds() external;

    /**
     * @notice Collects funds in the specified ERC20 token and sends them to the treasury.
     * @param token The address of the ERC20 token to collect.
     */
    function collectFunds(address token) external;
}