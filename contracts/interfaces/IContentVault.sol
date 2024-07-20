// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IContentVault {
    function getSecuredContent(uint256) external view returns (bytes memory);
    function secureContent(uint256, bytes calldata) external;
}
