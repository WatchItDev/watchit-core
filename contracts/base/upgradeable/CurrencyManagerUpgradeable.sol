// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
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
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:currencymanagarupgradeable
    struct CurrencyManagerStorage {
        // Maps currency addresses to their index in the supported currencies array
        EnumerableSet.AddressSet _supportedCurrencies;
    }

    bytes4 private constant INTERFACE_ID_ERC20 = type(IERC20).interfaceId;
    /// @notice Error thrown when trying to operate with an unsupported currency.
    /// @param currency The address of the unsupported currency.
    error InvalidCurrency(address currency);

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.currencymanager.supportedcurrencies")) - 1))
    // & ~bytes32(uint256(0xff))
    bytes32 private constant CURRENCY_MANAGER_SLOT =
        0x56b3138e9d26d4b1bbb7eb44261bf9a02d56af8c0799b6892290ca1ba7b2e700;

    /// @notice Modifier to ensure only valid ERC20 or native coins are used.
    /// @param currency The address of the currency to check.
    modifier onlyValidCurrency(address currency) {
        // if not native coin then should be a valid erc20 token
        if (
            currency != address(0) &&
            !currency.supportsInterface(INTERFACE_ID_ERC20)
        ) revert InvalidCurrency(currency);
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

    /// @dev As standard to avoid doubts about if a upgradeable contract
    /// need to be initalized, all the contracts specify the init even
    /// if the initialization is harmless..
    function __CurrencyManager_init() internal onlyInitializing {}

    function __CurrencyManager_init_unchained() internal onlyInitializing {}

    /// @notice Adds a currency to the list of supported currencies.
    /// @param currency The address of the currency to add.
    function _addCurrency(address currency) internal {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        // avoid duplicate currencies...
        if (isCurrencySupported(currency)) return;
        $._supportedCurrencies.add(currency);
    }

    /// @notice Removes a currency from the list of supported currencies.
    /// @param currency The address of the currency to remove.
    function _removeCurrency(address currency) internal {
        if (!isCurrencySupported(currency)) revert InvalidCurrency(currency);
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        $._supportedCurrencies.remove(currency);
    }

    /// @notice Returns the list of supported currencies.
    /// @return An array of addresses of the supported currencies.
    function supportedCurrencies() public view returns (address[] memory) {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        // https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableSet-values-struct-EnumerableSet-AddressSet-
        // This operation will copy the entire storage to memory, which can be quite expensive.
        // This is designed to mostly be used by view accessors that are queried without any gas fees.
        // Developers should keep in mind that this function has an unbounded cost, 
        /// and using it as part of a state-changing function may render the function uncallable
        /// if the set grows to a point where copying to memory consumes too much gas to fit in a block.
        return $._supportedCurrencies.values();
    }

    /// @notice Checks if a currency is supported.
    /// @param currency The address of the currency to check.
    /// @return True if supported, otherwise False.
    function isCurrencySupported(address currency) public view returns (bool) {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        return $._supportedCurrencies.contains(currency);
    }
}
