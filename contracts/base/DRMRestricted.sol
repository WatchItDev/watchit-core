// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title DRMRestricted
 * @author 
 *
 * @notice This abstract contract provides a public `drmAddress` immutable field and an `onlyDrm` modifier,
 * restricting certain functions to be callable only by the specified DRM address.
 */
abstract contract DRMRestricted {
    address public immutable drmAddress;

    /// @notice Error thrown when a function is called by an address other than the DRM address.
    error InvalidCallOnlyDRMAllowed();

    /**
     * @dev Sets the DRM address upon contract deployment.
     * @param drm The address of the drm contract.
     */
    constructor(address drm) {
       // Get the registered DRM contract from the repository
        drmAddress = drm;
    }

    /**
     * @dev Modifier to restrict function calls to only the DRM address.
     */
    modifier onlyDrm() {
        if (msg.sender != drmAddress) {
            revert InvalidCallOnlyDRMAllowed();
        }
        _;
    }
}
