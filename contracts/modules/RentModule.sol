// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/modules/interfaces/IPublicationActionModule.sol";
import "contracts/modules/base/LensModuleMetadata.sol";
import "contracts/modules/base/LensModuleRegistrant.sol";
import "contracts/modules/base/HubRestricted.sol";
import "contracts/modules/libraries/Types.sol";
import "contracts/interfaces/IRepository.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/IRightsManager.sol";
import "contracts/libraries/TreasuryHelper.sol";
import "contracts/libraries/MathHelper.sol";

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
    IRepositoryConsumer,
    IPublicationActionModule
{
    using MathHelper for uint256;
    using TreasuryHelper for address;

    // Custom errors for specific failure cases
    error InvalidExistingContentPublication();
    error InvalidNotSupportedCurrency();
    error InvalidDistributor();
    error InvalidRentPrice();

    // Address of the Digital Rights Management (DRM) contract
    address private immutable drmAddress;
    // Mapping from publication ID to content ID
    mapping(uint256 => uint256) contentRegistry;
    mapping(uint256 => uint256[]) profileRegistry;
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
        drmAddress = repo.getContract(ContractTypes.DRM);
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

    /**
     * @dev Calculates the fees for the distributor and treasury.
     * @param total The total amount.
     * @param distSplit The distributor split in basis points.
     * @param treasurySplit The treasury split in basis points.
     * @return uint256 The distributor fees.
     * @return uint256 The treasury fees.
     * @return uint256 The amount to be deposited to the content owner.
     */
    function _calculateFees(
        uint256 total,
        uint256 distSplit,
        uint256 treasurySplit
    ) internal pure returns (uint256, uint256, uint256) {
        // Calculate the fees for the distributor and treasury
        uint256 distriFees = total.perOf(distSplit.calcBps()); // eg: (amount * (% * 100)) / BPS_MAX
        uint256 treasuryFees = total.perOf(treasurySplit.calcBps());
        uint256 depositToOwner = total - (distriFees + treasuryFees);
        return (distriFees, treasuryFees, depositToOwner);
    }

    // @dev Initializes a publication action for renting a publication.
    // @param profileId The ID of the profile initiating the action.
    // @param pubId The ID of the publication being rented.
    // @param transactionExecutor The address of the executor of the transaction.
    // @param data Additional data required for the action.
    // @return bytes memory The result of the action.
    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address transactionExecutor,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        // Decode the rent parameters
        Types.RentParams memory rent = abi.decode(data, (Types.RentParams));
        // Store renting parameters
        _setPublicationRentSetting(rent, pubId);
        // Get the DRM and rights custodial interfaces
        IRightsManager drm = IRightsManager(drmAddress);
        // Ensure the content is not already owned
        if (drm.ownerOf(rent.contentId) != address(0))
            revert InvalidExistingContentPublication();

        // Mint the NFT for the content and secure it;
        drm.mint(transactionExecutor, rent.contentId);
        // The secured content, could be any content to handly encryption schema..
        // eg: LIT cypertext + hash, public key enceypted data, shared key encrypted data..
        drm.secureContent(rent.contentId, rent.secured);
        // Grant initial custody to the distributor
        drm.grantCustodial(rent.distributor, rent.contentId);
        contentRegistry[pubId] = rent.contentId;
        profileRegistry[profileId].push(rent.contentId);
        // TODO royalties NFT
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

        IRightsManager drm = IRightsManager(drmAddress);
        uint256 contentId = contentRegistry[params.publicationActedId];
        address distributorAddress = drm.getCustodial(contentId);
        IDistributor distributor = IDistributor(distributorAddress);

        // Get split % for distributor and treasury
        uint256 treasurySplit = drm.getTreasuryFee(currency); // nominal % eg: 10, 20, 30
        //!IMPORTANT if distributor does not support the currency, will revert..
        uint256 distSplit = distributor.getTreasuryFee(currency); // nominal % eg: 10, 20, 30
        // Calculate the fees for the distributor, treasury and content owner
        (
            uint256 distriFees,
            uint256 treasuryFees,
            uint256 depositToOwner
        ) = _calculateFees(total, distSplit, treasurySplit);

        address owner = drm.ownerOf(contentId);
        address rentalWatcher = params.transactionExecutor;

        // Deposit the calculated amounts to the respective addresses
        rentalWatcher.safeDeposit(owner, depositToOwner, currency);
        rentalWatcher.safeDeposit(drmAddress, treasuryFees, currency);
        rentalWatcher.safeDeposit(distributorAddress, distriFees, currency);
        // Add access to content for N days to renter..
        drm.grantAccess(rentalWatcher, contentId, _days * 1 days);
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
            super.supportsInterface(interfaceID);
    }
}
