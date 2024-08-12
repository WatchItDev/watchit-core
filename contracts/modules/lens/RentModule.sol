// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/modules/lens/interfaces/IPublicationActionModule.sol";
import "contracts/modules/lens/base/LensModuleMetadata.sol";
import "contracts/modules/lens/base/LensModuleRegistrant.sol";
import "contracts/modules/lens/base/HubRestricted.sol";
import "contracts/modules/lens/libraries/Types.sol";
import "contracts/interfaces/IAccessWitness.sol";
import "contracts/interfaces/IRightsManager.sol";
import "contracts/libraries/Types.sol";

/**
 * @title RentModule
 * @dev Contract that manages rental actions for publications.
 * It inherits from Ownable, IPublicationActionModule, LensModuleMetadata,
 * LensModuleRegistrant, and HubRestricted.
 */
contract RentModule is
    Ownable,
    LensModuleMetadata,
    LensModuleRegistrant,
    HubRestricted,
    IAccessWitness,
    IPublicationActionModule
{
    using SafeERC20 for IERC20;

    // Custom errors for specific failure cases
    error InvalidExistingContentPublication();
    error InvalidNotSupportedCurrency();
    error InvalidRentPrice();

    // Address of the Digital Rights Management (DRM) contract
    address private immutable drmAddress;
    address private immutable wvcAddress;
    // Mapping from publication ID to content ID
    mapping(uint256 => uint256) contentRegistry;
    mapping(uint256 => mapping(address => uint256)) rentRegistry;
    // Mapping from publication ID and currency to rent price
    mapping(uint256 => mapping(address => uint256)) private prices;

    /**
     * @dev Constructor that initializes the RentModule contract.
     * @param hub The address of the hub contract.
     * @param registrant The address of the registrant contract.
     * @param repository The address of the repository contract.
     */
    constructor(
        address hub,
        address registrant,
        address repository
    )
        Ownable(_msgSender())
        HubRestricted(hub)
        LensModuleRegistrant(registrant)
    {
        // Get the registered DRM contract from the repository
        IRepository repo = IRepository(repository);
        drmAddress = repo.getContract(T.ContractTypes.DRM);
        wvcAddress = repo.getContract(T.ContractTypes.WVC);
    }

    /**
     * @dev Registers an ERC20 currency to be used for rentals.
     * @param currencyAddress The address of the ERC20 currency.
     * @return bool True if the currency is successfully registered.
     */
    function registerCurrency(
        address currencyAddress
    ) public onlyOwner returns (bool) {
        return _registerErc20Currency(currencyAddress);
    }

    /**
     * @inheritdoc ILensModuleRegistrant
     * @dev Registers the RentModule as a PUBLICATION_ACTION_MODULE.
     * @return bool Success of the registration.
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
     * @dev Sets the rent settings for a publication.
     * @param rent The rent parameters.
     * @param pubId The publication ID.
     */
    function _setPublicationRentSetting(
        Types.RentParams memory rent,
        uint256 pubId
    ) private {
        uint256 i = 0;
        while (i < rent.rentPrices.length) {
            uint256 price = rent.rentPrices[i].price;
            address currency = rent.rentPrices[i].currency;

            // Validate price and currency support
            if (price == 0) revert InvalidRentPrice();
            bool isSupportedCurrencyByDistributor = IDistributor(
                rent.distributor
            ).isCurrencySupported(currency);

            if (
                !isRegisteredErc20(currency) ||
                !isSupportedCurrencyByDistributor
            ) revert InvalidNotSupportedCurrency();

            // Set the rent price
            // pub -> wvc -> 5
            prices[pubId][currency] = price;

            // Avoid overflow check and optimize gas
            unchecked {
                ++i;
            }
        }
    }

    // @dev Initializes a publication action for renting a publication.
    // @param profileId The ID of the profile initiating the action.
    // @param pubId The ID of the publication being rented.
    // @param transactionExecutor The address of the executor of the transaction.
    // @param data Additional data required for the action.
    // @return bytes memory The result of the action.
    function initializePublicationAction(
        uint256,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        // Decode the rent parameters
        Types.RentParams memory rent = abi.decode(data, (Types.RentParams));
        // Get the DRM and rights custodial interfaces
        IRightsManager drm = IRightsManager(drmAddress);
        // Ensure the content is not already owned
        if (drm.ownerOf(rent.contentId) != address(0))
            revert InvalidExistingContentPublication();

        contentRegistry[pubId] = rent.contentId;
        // Mint the NFT for the content and secure it;
        drm.mint(transactionExecutor, rent.contentId);
        // The secured content, could be any content to handly encryption schema..
        // eg: LIT cypertext + hash, public key enceypted data, shared key encrypted data..
        // Grant initial custody to the distributor
        drm.grantCustodial(rent.contentId, rent.distributor, rent.secured);
        // Store renting parameters
        _setPublicationRentSetting(rent, pubId);
        // TODO royalties NFT
        // TODO fragmentable NFT
        // TODO mirror content
        // TODO review security concerns
        // TODO tests

        return data;
    }

    /// @dev Processes a publication action (rent).
    /// @param params The parameters for processing the action.
    /// @return bytes memory The result of the action.
    function processPublicationAction(
        Types.ProcessActionParams calldata params
    ) external override onlyHub returns (bytes memory) {
        (address currency, uint256 _days) = abi.decode(
            params.actionModuleData,
            (address, uint256)
        );

        // if currency is not registered to get price, revert..
        uint256 pricePerDay = prices[params.publicationActedId][currency];
        if (pricePerDay == 0) revert InvalidNotSupportedCurrency();
        // Calculate the total fees based on the price per day and the number of days
        uint256 total = pricePerDay * _days;
        uint256 contentId = contentRegistry[params.publicationActedId];
        address rentalWatcher = params.transactionExecutor;

        // hold rent time in module to later validate it in access control...
        rentRegistry[contentId][rentalWatcher] =
            Time.timestamp() +
            (_days * 1 days);

        // The access proof is established here..
        T.AccessCondition memory cond = T.AccessCondition(
            T.Witness(address(this), this.approve.selector), // the function in the witness contract to approve the access
            T.Fees(currency, total) // the transaction amount and currency
        );

        // TODO aqui se podria agregar un hook?
        // quizas tener hooks para que se pueda
        // establecer acciones sobre las operaciones
        // sobre el contenido, como "rewards for rent in X token"
        // rewardsType = module(feeDistribution, token) o un metodo en library
        // https://docs.openzeppelin.com/contracts/4.x/api/finance

        // We deposit the token amount as delegated rights handler.
        // A previous approval should be done.
        // https://www.lens.xyz/docs/primitives/collect/collectables#additional-options-erc-20-approvals
        IERC20(currency).safeTransferFrom(rentalWatcher, address(this), total);
        // add allowance to drm contract from delegated module.
        IERC20(currency).safeIncreaseAllowance(drmAddress, total);
        // Add access to content for N days to account..
        IRightsManager(drmAddress).grantAccess(rentalWatcher, contentId, cond);
        return abi.encode(rentRegistry[contentId][rentalWatcher], currency);
    }

    /**
     * @dev Checks if the rental period has expired.
     * @param account The address of the account.
     * @param contentId The ID of the content.
     * @return bool True if the rental period has expired, false otherwise.
     */
    function approve(
        address account,
        uint256 contentId
    ) external view returns (bool) {
        return Time.timestamp() > rentRegistry[contentId][account];
    }

    /**
     * @dev Checks if the contract supports a specific interface.
     * @param interfaceID The ID of the interface to check.
     * @return bool True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceID
    ) public pure override returns (bool) {
        return
            interfaceID == type(IPublicationActionModule).interfaceId ||
            interfaceID == type(IAccessWitness).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
