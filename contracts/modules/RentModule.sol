// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "contracts/modules/base/LensModuleMetadata.sol";
import "contracts/modules/base/LensModuleRegistrant.sol";
import "contracts/modules/base/HubRestricted.sol";

import "contracts/interfaces/IRepository.sol";
import "contracts/modules/interfaces/IPublicationActionModule.sol";
import "contracts/modules/libraries/Types.sol";

/**
 * @dev RentModule is a contract that manages rental actions for publications.
 * It inherits from Ownable, IPublicationActionModule, LensModuleMetadata,
 * LensModuleRegistrant, and HubRestricted.
 */
contract RentModule is
    Ownable,
    IRepositoryConsumer,
    IPublicationActionModule,
    LensModuleMetadata,
    LensModuleRegistrant,
    HubRestricted
{
    IERC721 private immutable ownership;

    constructor(
        address hub,
        address registrant,
        address repository
    )
        Ownable(_msgSender())
        HubRestricted(hub)
        LensModuleRegistrant(registrant)
    {
        ownership = IERC721(
            IRepository(repository).getContract(ContractTypes.OWNERSHIP)
        );
    }

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
    function setModuleMetadataURI(
        string calldata _metadataURI
    ) public onlyOwner {
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
        // drm recibe los fees de las rentas.. que luego los duenos (creators, distriburos) pueden colectar por disburs en base a lo que tienen registrado
        // es treasury y es desburser
        // TODO: Mint nuestro NFT token aca?
        // TODO En el registro de película en drm el creador debe pasar los token con los desea pagar Y validar si el distribuidor los acepta
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
