// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../LensModule.sol";

/**
 * @title LensModuleMetadataUpgradeable
 * @dev This contract allows managing metadata URI for Lens modules.
 * It is an upgradeable contract using OpenZeppelin's upgradeable patterns.
 */
contract LensModuleMetadataUpgradeable is
    LensModule,
    Initializable,
    OwnableUpgradeable
{
    /// @notice The storage slot for the metadata URI.
    /// @custom:storage-location erc7201:LensModuleMetadataUpgradeable.metadata
    bytes32 private constant METADATA_SLOT =
        0x17463ac0b88d4a0527bbbd4210f305fc3c3274ba6a4ca40bc9a8a2ca9d4efa00;

    /**
     * @notice Metadata storage structure.
     * @custom:storage-location erc7201:LensModuleMetadataUpgradeable.metadata
     */
    struct MetadataStorage {
        string _uri;
    }

    /**
     * @notice Internal function to get the metadata storage.
     * @return $ The metadata storage.
     */
    function _getMetadataStorage()
        private
        pure
        returns (MetadataStorage storage $)
    {
        assembly {
            $.slot := METADATA_SLOT
        }
    }

    /**
     * @notice Initializes the contract setting the owner.
     * @param owner The address of the owner.
     */
    function __LensModuleMetadata_init(
        address owner
    ) internal onlyInitializing {
        __LensModuleMetadata_init_unchained(owner);
    }

    /**
     * @notice Initializes the ownership of the contract.
     * @param owner The address of the owner.
     */
    function __LensModuleMetadata_init_unchained(
        address owner
    ) internal onlyInitializing {
        __Ownable_init(owner);
    }

    /**
     * @notice Sets the metadata URI for the module.
     * @param _metadataURI The new metadata URI.
     * @dev Can only be called by the owner of the contract.
     */
    function setModuleMetadataURI(
        string memory _metadataURI
    ) external onlyOwner {
        MetadataStorage storage $ = _getMetadataStorage();
        $._uri = _metadataURI;
    }

    /**
     * @notice Gets the metadata URI for the module.
     * @return The metadata URI.
     */
    function getModuleMetadataURI() external view returns (string memory) {
        MetadataStorage storage $ = _getMetadataStorage();
        return $._uri;
    }
}
