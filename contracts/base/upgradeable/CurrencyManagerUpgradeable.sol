// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/ICurrencyManager.sol";

/// @title Currency Manager Upgradeable
/// @notice This contract manages supported currencies and allows for adding/removing supported currencies.
/// @dev This contract uses the upgradeable pattern and stores currency data in a specific storage slot to prevent storage conflicts.
abstract contract CurrencyManagerUpgradeable is
    Initializable,
    ICurrencyManager
{
    /// @custom:storage-location erc7201:currencymanagarupgradeable.supportedtokensmap
    /// @custom:storage-location erc7201:currencymanagarupgradeable.supportedtokens
    struct CurrencyManagerStorage {
        mapping(address => uint256) _supportedCurrencyMap; // Maps currency addresses to their index in the supported tokens array
        address[] _supportedCurrencies; // Array of supported currency addresses
    }

    /// @notice Error thrown when trying to remove an unsupported currency.
    /// @param currency The address of the unsupported currency.
    error InvalidUnsupportedCurrency(address currency);

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.currencybroker.supportedtokens")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CURRENCY_MANAGER_SLOT =
        0xeef4c6e07c8c48aa12ec4689202072497f770ef14b71c2b38f8bc57ade760c00;

    /**
     * @notice Internal function to get the currency manager storage.
     * @return $ The currency manager storage.
     */
    function _getCurrencyManagerStorage()
        private
        pure
        returns (CurrencyManagerStorage storage $)
    {
        assembly {
            $.slot := CURRENCY_MANAGER_SLOT
        }
    }

    /// @notice Initializes the currency manager. To be called during contract initialization.
    function __CurrencyManager_init() internal onlyInitializing {}
    function __CurrencyManager_init_unchained() internal onlyInitializing {}

    /// @notice Adds a currency to the list of supported currencies.
    /// @param currency The address of the currency to add.
    function _addCurrency(address currency) internal {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        $._supportedCurrencies.push(currency);
        // Add the last index for the current stored currency as value for mapping
        $._supportedCurrencyMap[currency] = $._supportedCurrencies.length;
    }

    /// @notice Removes a currency from the list of supported currencies.
    /// @param currency The address of the currency to remove.
    function _removeCurrency(address currency) internal {
        if (!isCurrencySupported(currency))
            revert InvalidUnsupportedCurrency(currency);

        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        uint256 index = $._supportedCurrencyMap[currency] - 1;
        uint256 lastIndex = $._supportedCurrencies.length - 1;
        address lastCurrency = $._supportedCurrencies[lastIndex];

        // Replace the currency to remove with the last address
        $._supportedCurrencies[index] = lastCurrency;
        $._supportedCurrencyMap[lastCurrency] = index + 1; // Restore the index of the last address to be base 1
        // Clear old data by removing index and popping the last address
        delete $._supportedCurrencyMap[currency];
        $._supportedCurrencies.pop();
    }

    /// @notice Returns the list of supported currencies.
    /// @return An array of addresses of the supported currencies.
    function supportedCurrencies() external view returns (address[] memory) {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        return $._supportedCurrencies;
    }

    /// @notice Checks if a currency is supported.
    /// @param currency The address of the currency to check.
    /// @return True if supported, otherwise False.
    function isCurrencySupported(address currency) public view returns (bool) {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        return $._supportedCurrencyMap[currency] != 0;
    }
}
