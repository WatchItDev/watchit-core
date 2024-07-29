// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// The ICurrencyManager interface defines methods for checking and retrieving supported currencies.
interface ICurrencyManager {
    
    /// @notice Checks if a given currency is supported.
    /// @param currency The address of the currency to check.
    /// @return bool True if the currency is supported, false otherwise.
    function isCurrencySupported(address currency) external view returns (bool);
    
    /// @notice Returns a list of all supported currencies.
    /// @return address[] An array of addresses representing the supported currencies.
    function supportedCurrencies() external view returns (address[] memory);
}
