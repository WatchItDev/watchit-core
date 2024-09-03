// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRightsCustodialGranter {
    /// @notice Grants custodial rights over the content held by a holder to a distributor.
    /// @param distributor The address of the distributor who will receive custodial rights.
    function grantCustody(address distributor) external;
}
