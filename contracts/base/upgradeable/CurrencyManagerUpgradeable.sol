// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/ICurrencyManager.sol";

abstract contract CurrencyManagerUpgradeable is
    Initializable,
    ICurrencyManager
{
    /// @custom:storage-location erc7201:currencymanagarupgradeable.supportedtokensmap
    /// @custom:storage-location erc7201:currencymanagarupgradeable.supportedtokens
    struct CurrencyManagerStorage {
        mapping(address => uint256) _supportedTokensMap;
        address[] _supportedTokens;
    }

    error InvalidUnsupportedToken(address);

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.currencybroker.supportedtokens")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CURRENCY_MANAGER_SLOT =
        0xeef4c6e07c8c48aa12ec4689202072497f770ef14b71c2b38f8bc57ade760c00;

    /**
     * @notice Internal function to get the treasury storage.
     * @return $ The broker storage.
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

    function __CurrencyManager_init() internal onlyInitializing {}
    function __CurrencyManager_init_unchained() internal onlyInitializing {}

    function _addCurrency(address currency) internal {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        $._supportedTokens.push(currency);
        // add the last index for current stored currency as value for mapping
        $._supportedTokensMap[currency] = $._supportedTokens.length;
    }

    function _removeCurrency(address currency) internal {
        if (!isCurrencySupported(currency))
            revert InvalidUnsupportedToken(currency);

        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        uint256 index = $._supportedTokensMap[currency] - 1;
        uint256 lastIndex = $._supportedTokens.length - 1;
        address lastCurrency = $._supportedTokens[lastIndex];

        // replace the remove with the last address
        $._supportedTokens[index] = lastCurrency;
        $._supportedTokensMap[lastCurrency] = index + 1; // restore the remove address index as base 1
        // flush old data removing index and poping the last address..
        delete $._supportedTokensMap[currency];
        $._supportedTokens.pop();
    }

    function supportedCurrencies() external view returns (address[] memory) {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        return $._supportedTokens;
    }

    /// @notice Checks if a currency is supported
    /// @param currency The address of the currency to check
    /// @return True supported, otherwise False..
    function isCurrencySupported(address currency) public view returns (bool) {
        CurrencyManagerStorage storage $ = _getCurrencyManagerStorage();
        return $._supportedTokensMap[currency] != 0;
    }
}
