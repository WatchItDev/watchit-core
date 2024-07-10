// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../base/LensModuleMetadata.sol";
import "../base/LensModuleRegistrant.sol";
import "../base/HubRestricted.sol";

import "../interfaces/IPublicationActionModule.sol";
import "../libraries/Types.sol";

/**
 * @dev RentModule is a contract that manages rental actions for publications.
 * It inherits from Ownable, IPublicationActionModule, LensModuleMetadata,
 * LensModuleRegistrant, and HubRestricted.
 */
contract RentModule is
    Ownable,
    IPublicationActionModule,
    LensModuleMetadata,
    LensModuleRegistrant,
    HubRestricted
{
    constructor(
        address hub,
        address registry
    ) Ownable(_msgSender()) HubRestricted(hub) LensModuleRegistrant(registry) {}

    /**
     * @inheritdoc ILensModuleRegistrant
     * @dev Registers the RentModule as a PUBLICATION_ACTION_MODULE.
     * @return bool success of the registration
     */
    function registerModule() public onlyOwner returns (bool) {
        return _registerModule(Types.ModuleType.PUBLICATION_ACTION_MODULE);
    }

    /**
     * @dev Sets the metadata URI for the RentModule.
     * @param _metadataURI The new metadata URI.
     */
    function setModuleMetadataURI(string calldata _metadataURI) public onlyOwner {
        _setModuleMetadataURI(_metadataURI);
    }

    /**
     * @dev Initializes a publication action for renting a publication.
     * @param profileId The ID of the profile initiating the action.
     * @param pubId The ID of the publication being rented.
     * @param transactionExecutor The address of the executor of the transaction.
     * @param data Additional data required for the action.
     * @return bytes memory The result of the action.
     */
    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        // TODO: Determine who the owner will be for payment
        // TODO: Determine who the distributor will be for fees deducted from the treasury
        // TODO: Assign the access duration
    }

    /**
     * @dev Processes a publication action.
     * @param processActionParams The parameters for processing the action.
     * @return bytes memory The result of the action.
     */
    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external override onlyHub returns (bytes memory) {}

    /**
     * @dev Checks if the contract supports a specific interface.
     * @param interfaceID The ID of the interface to check.
     * @return bool true if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceID
    ) public pure override returns (bool) {
        return
            interfaceID == type(IPublicationActionModule).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
