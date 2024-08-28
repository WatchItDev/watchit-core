// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title RMRestricted
 * @author 
 *
 * @notice This abstract contract provides a public `rmAddress` immutable field and an `onlyRm` modifier,
 * restricting certain functions to be callable only by the specified RM address.
 */
abstract contract RMRestricted {
    address public immutable rmAddress;

    /// @notice Error thrown when a function is called by an address other than the RM address.
    error InvalidCallOnlyRMAllowed();

    /**
     * @dev Sets the RM address upon contract deployment.
     * @param rm The address of the rights manager contract.
     */
    constructor(address rm) {
       // Get the registered RM contract from the repository
        rmAddress = rm;
    }

    /**
     * @dev Modifier to restrict function calls to only the RM address.
     */
    modifier onlyRm() {
        if (msg.sender != rmAddress) {
            revert InvalidCallOnlyRMAllowed();
        }
        _;
    }
}
