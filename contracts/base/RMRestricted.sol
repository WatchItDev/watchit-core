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


     /// @notice Modifier to restrict access to the holder only or their delegate.
    /// @param contentId The content hash to give distribution rights.
    /// @dev Only the holder of the content can pass this validation.
    modifier onlyHolder(uint256 contentId) {
        if (ownership.ownerOf(contentId) != _msgSender())
            revert RestrictedAccessToHolder();
        _;
    }

     /// @notice Modifier to check if the content is registered.
    /// @param contentId The content hash to check.
    modifier onlyRegisteredContent(uint256 contentId) {
        if (ownership.ownerOf(contentId) == address(0))
            revert InvalidUnknownContent();
        _;
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
