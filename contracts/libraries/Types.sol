// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

/// @title Type Definitions Library
/// @notice This library provides common type definitions for use in other contracts.
/// @dev This library defines types and structures that can be imported and used in other contracts.
library T {
    /// @notice Structure to store an access condition.
    /// @dev The structure contains a function pointer that checks 
    /// if a given address has access to a specific content ID.
    struct AccessCondition {
        /// @notice Function that verifies if an address has access to a content ID.
        /// @param account The address to check for access.
        /// @param contentId The ID of the content to check access for.
        /// @return True if the address has access to the content ID, false otherwise.
        function(address, uint256) external view returns (bool) check;
    }
}
