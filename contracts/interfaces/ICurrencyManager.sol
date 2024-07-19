// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICurrencyManager {
    function isCurrencySupported(address) external view returns (bool);
    function supportedCurrencies() external view returns (address[] memory);
}