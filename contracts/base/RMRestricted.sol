// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import "contracts/interfaces/IOwnership.sol";
import "contracts/interfaces/IRightsManager.sol";

abstract contract RMRestricted {
    IRightsManager public immutable rm;
    IOwnership public immutable ownership;

    /// @dev Error that is thrown when a restricted access to the holder is attempted.
    error InvalidContentHolder();
    /// @notice Error thrown when a function is called by an address other than the RM address.
    error InvalidCallOnlyRMAllowed();
    error InvalidUnknownContent();

    constructor(address rmAddress, address ownershipAddress) {
        // Get the registered RM contract from the repository
        rm = IRightsManager(rmAddress);
        ownership = IOwnership(ownershipAddress);
    }

    /// @notice Modifier to restrict operations over the content the only authorized by holder.
    /// @param contentId The content id to check authorization.
    /// @param expectedHolder The expected rights holder who authorized the access.
    /// @dev Only the holder of the content can pass this validation.
    function isValidHolder(uint256 contentId, address expectedHolder) {
        if (ownership.ownerOf(contentId) != expectedHolder)
            revert InvalidContentHolder();
        _;
    }

    /// @notice Modifier to check if the content is registered.
    /// @param contentId The content hash to check.
    modifier onlyRegisteredContent(uint256 contentId) {
        if (ownership.ownerOf(contentId) == address(0))
            revert InvalidUnknownContent();
        _;
    }

    /// @dev Modifier to restrict function calls to only the RM address.
    modifier onlyRM() {
        if (msg.sender != address(rm)) {
            revert InvalidCallOnlyRMAllowed();
        }
        _;
    }
}
