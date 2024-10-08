// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title IFeesManager Interface
/// @notice This interface defines functions for managing and retrieving treasury fees associated with different currencies.
/// @dev This interface is intended to be implemented by contracts that manage platform or treasury fees for multiple currencies.
interface IFeesManager {
    /// @notice Sets a new treasury fee for a specific currency.
    /// @param newTreasuryFee The new treasury fee percentage (e.g., 5 for 5%).
    /// @param currency The address of the currency to associate fees with. Use address(0) for the native coin.
    /// @notice Only the owner can call this function.
    function setFees(uint256 newTreasuryFee, address currency) external;

    /// @notice Returns the current treasury fee percentage for a specific currency.
    /// @param currency The address of the currency for which to retrieve the treasury fee. Use address(0) for the native coin.
    /// @return The treasury fee percentage.
    function getFees(address currency) external view returns (uint256);
}
