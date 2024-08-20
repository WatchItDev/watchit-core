// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFeesManager {
    /// @notice Sets a new treasury fee.
    /// @param newTreasuryFee The new treasury fee.
    /// @notice Only the owner can call this function.
    function setFees(uint256 newTreasuryFee) external;

    /// @notice Sets a new treasury fee.
    /// @param newTreasuryFee The new treasury fee %.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    /// @notice Only the owner can call this function.
    function setFees(uint256 newTreasuryFee, address currency) external;

    /// @notice Returns the current treasury fee %. 
    /// @param currency The address of the currency for which to retrieve the fees fee.
    /// @return The treasury fee.
    function getFees(address currency) external view returns (uint256);
}