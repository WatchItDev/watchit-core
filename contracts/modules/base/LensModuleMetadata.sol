// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LensModule.sol";

abstract contract LensModuleMetadata is LensModule {
    string public metadataURI;

    /**
     * @dev Sets the metadata URI for the module.
     * @param _metadataURI The URI of the metadata.
     * @notice Only the owner of the contract can call this function.
     */
    function _setModuleMetadataURI(string calldata _metadataURI) internal {
        metadataURI = _metadataURI;
    }

    /**
     * @dev Retrieves the metadata URI for the module.
     * @return The URI of the metadata.
     */
    function getModuleMetadataURI() external view returns (string memory) {
        return metadataURI;
    }
}
