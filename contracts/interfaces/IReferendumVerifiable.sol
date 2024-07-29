// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IReferendumVerifiable {
    function isApproved(uint256) external view returns (bool);
    function approvedFor(uint256) external view returns (address);
}
