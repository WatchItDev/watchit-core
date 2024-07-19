// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRightsCustodial {
    // this is where the fees are routed
    function grantCustodial(address, uint256) external;
    function getCustodial(uint256) external view returns (address);
    function hasCustodial(address, uint256) external view returns (bool);
}
