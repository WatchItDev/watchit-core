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

}
