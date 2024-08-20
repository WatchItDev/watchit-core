// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/ICurrencyManager.sol";

/// @title Currency Manager Upgradeable
/// @notice This contract manages supported currencies and allows for adding/removing supported currencies.
/// @dev This contract uses the upgradeable pattern and stores currency data.
abstract contract CurrencyManagerUpgradeable is
    Initializable,
    ICurrencyManager
{
    using ERC165Checker for address;

    /// @custom:storage-location erc7201:currencymanagarupgradeable
    struct CurrencyManagerStorage {
        // Maps currency addresses to their index in the supported currencies array
        mapping(address => uint256) _supportedCurrencyMap;
        // Array of supported currency addresses
        address[] _supportedCurrencies;
    }

    bytes4 private constant INTERFACE_ID_ERC20 = type(IERC20).interfaceId;
    /// @notice Error thrown when trying to remove an unsupported currency.
    /// @param currency The address of the unsupported currency.
    error InvalidCurrency(address currency);

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.currencymanager.supportedcurrencies")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CURRENCY_MANAGER_SLOT =
        0x56b3138e9d26d4b1bbb7eb44261bf9a02d56af8c0799b6892290ca1ba7b2e700;

    /// @notice Modifier to ensure only valid ERC20 or native coins are used.
    /// @param currency The address of the currency to check.
    modifier onlyValidCurrency(address currency) {
        // if not native coin then should be a valid erc20 token
        if (currency != address(0) && !currency.supportsInterface(INTERFACE_ID_ERC20))
            revert InvalidCurrency(currency);
        _;
    }

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
        // avoid duplicate currencies...
        if (isCurrencySupported(currency)) return;
        $._supportedCurrencies.push(currency);
        // Add the last index for the current stored currency as value for mapping
        $._supportedCurrencyMap[currency] = $._supportedCurrencies.length;
    }

    /// @notice Removes a currency from the list of supported currencies.
    /// @param currency The address of the currency to remove.
    function _removeCurrency(address currency) internal {
        if (!isCurrencySupported(currency))
            revert InvalidCurrency(currency);

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
    function supportedCurrencies() public view returns (address[] memory) {
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
