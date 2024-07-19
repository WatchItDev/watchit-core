// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/ICurrencyManager.sol";

/// @title CurrencyManager
/// @notice Abstract contract for managing supported currencies
/// @dev This contract provides internal functions for adding and removing supported currencies
abstract contract CurrencyManager is Initializable, ICurrencyManager {
    /// @dev Mapping from currency address to its index in the supportedTokens array
    mapping(address => uint256) supportedTokensMap;
    /// @dev Array of supported currency addresses
    address[] supportedTokens;

    error InvalidUnsupportedToken(address);
    /// @notice Adds a new currency to the supported currencies list
    /// @dev This function is internal and can only be called within the contract or derived contracts
    /// @param currency The address of the currency to add
    function _addCurrency(address currency) internal {
        supportedTokens.push(currency);
        // Add the last index for the currently stored currency as the value in the mapping
        supportedTokensMap[currency] = supportedTokens.length;
    }

    /// @notice Removes a currency from the supported currencies list
    /// @dev This function is internal and can only be called within the contract or derived contracts
    /// @param currency The address of the currency to remove
    function _removeCurrency(address currency) internal {
        if (!isCurrencySupported(currency))
            revert InvalidUnsupportedToken(currency);

        uint256 index = supportedTokensMap[currency] - 1;
        uint256 lastIndex = supportedTokens.length - 1;
        address lastCurrency = supportedTokens[lastIndex];

        // replace the remove with the last address
        supportedTokens[index] = lastCurrency;
        supportedTokensMap[lastCurrency] = index + 1; // restore the remove address index as base 1
        // flush old data removing index and poping the last address..
        delete supportedTokensMap[currency];
        supportedTokens.pop();
    }

    /// @notice Returns the list of supported currencies
    /// @return An array of addresses representing the supported currencies
    function supportedCurrencies() external view returns (address[] memory) {
        return supportedTokens;
    }

    /// @notice Checks if a currency is supported
    /// @param currency The address of the currency to check
    /// @return True if the currency is supported, otherwise False
    function isCurrencySupported(address currency) public view returns (bool) {
        // This checks if the currency exists in the mapping, and handles the edge case for the first element
        return supportedTokensMap[currency] != 0;
    }
}
