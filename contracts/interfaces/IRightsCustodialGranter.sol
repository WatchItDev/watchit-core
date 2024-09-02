// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRightsCustodialGranter {
    /// @notice Grants custodial rights over the content held by a holder to a distributor.
    /// @param distributor The address of the distributor who will receive custodial rights.
    /// @param contentHolder The address of the account that owns the content for which custodial rights are being granted.
    function grantCustody(address contentHolder, address distributor) external;
}
