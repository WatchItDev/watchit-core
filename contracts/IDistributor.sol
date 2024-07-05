// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

interface IDistributor {
    function updateEndpoint(string memory) external;
    function getEndpoint() external view returns(string memory);
}