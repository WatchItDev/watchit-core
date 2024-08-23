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

import "contracts/base/DRMRestricted.sol";
import "contracts/interfaces/IValidator.sol";
import "contracts/interfaces/IRightsManager.sol";
import "contracts/libraries/Constants.sol";
import "contracts/libraries/Types.sol";

/**
 * @title RentModule
 * @dev Contract that manages rental actions for publications and enforces licensing terms based on rental conditions.
 * It inherits from Ownable, IPublicationActionModule, LensModuleMetadata,
 * LensModuleRegistrant, and HubRestricted.
 */
contract RentModule is
    Ownable,
    LensModuleMetadata,
    LensModuleRegistrant,
    HubRestricted,
    DRMRestricted,
    IPublicationActionModule,
    IValidator
{
    using SafeERC20 for IERC20;

    // Custom errors for specific failure cases
    error InvalidExistingContentPublication();
    error InvalidNotSupportedCurrency();
    error InvalidRentPrice();

    struct Registry {
        uint256 timelock;
        address currency;
        uint256 amount;
    }

    // Mapping from publication ID to content ID
    mapping(uint256 => uint256) contentRegistry;
    mapping(uint256 => mapping(address => Registry)) rentRegistry;
    mapping(uint256 => mapping(address => uint256)) private prices;

    /**
     * @dev Constructor that initializes the RentModule contract.
     * @param hub The address of the hub contract.
     * @param registrant The address of the registrant contract.
     * @param drm The address of the drm contract.
     */
    constructor(
        address hub,
        address registrant,
        address drm
    )
        Ownable(_msgSender())
        HubRestricted(hub)
        DRMRestricted(drm)
        LensModuleRegistrant(registrant)
    {}

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
        uint8 i = 0;
        while (i < rent.rentPrices.length) {
            uint256 price = rent.rentPrices[i].price;
            address currency = rent.rentPrices[i].currency;

            // Validate price and currency support
            if (price == 0) revert InvalidRentPrice();
            if (!isRegisteredErc20(currency))
                revert InvalidNotSupportedCurrency();

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
        contentRegistry[pubId] = rent.contentId;
        // Store renting parameters
        _setPublicationRentSetting(rent, pubId);
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
        address account = params.transactionExecutor;

        // hold rent time in module to later validate it in access control...
        uint256 timelock = Time.timestamp() + (_days * 1 days);
        rentRegistry[contentId][account] = Registry(timelock, currency, total);
        // Transfers the specified amount of funds from the account to this contract
        // Requires that the account has previously approved this contract to spend the specified amount
        IERC20(currency).safeTransferFrom(account, address(this), total);
        // Increases the allowance for the DRM contract by the total amount
        IERC20(currency).approve(drmAddress, total);
        
        IRightsManager(drmAddress).enforceAccess(contentId, account, address(this));
        return abi.encode(rentRegistry[contentId][account], currency);
    }

    /// @notice Verify whether the access terms for an account and content ID are satisfied
    /// @param account The address of the account to check.
    /// @param contentId The content ID to check against.
    function verify(
        address account,
        uint256 contentId
    ) external view returns (bool) {
        // Checks if the current timestamp is greater than the timelock for the given account and contentId
        uint256 expireAt = rentRegistry[contentId][account].timelock;
        return Time.timestamp() > expireAt;
    }

    /// @inheritdoc IValidator
    /// @notice Checks whether the terms (such as rental period) for an account and content ID are still valid.
    /// @dev This function checks if the current timestamp is within the valid period (timelock) for the specified account and content ID.
    /// If the current time is within the allowed period, the terms are considered satisfied.
    /// @param account The address of the account being checked.
    /// @param contentId The content ID associated with the access terms.
    /// @return bool True if the terms are satisfied, false otherwise.
    function terms(
        address account,
        uint256 contentId
    ) external view returns (bool) {
        Registry reg = rentRegistry[contentId][account];
        address currency = reg.currency;
        uint256 amount = reg.amount;

        return
            T.Terms(
                T.Transaction(currency, amount),
                // An empty distribution means all royalties go to the owner.
                // If a distribution is set, e.g., a=>5%, b=>5%, owner=>remaining 90%,
                // if the distribution sums to 100%, the owner receives 0.
                // This can be used to manage various business logic for content distribution.
                new T.Splits[](0)
            );
    }

    /// @dev Checks if the contract supports a specific interface.
    /// @param interfaceID The ID of the interface to check.
    /// @return bool True if the contract supports the interface, false otherwise.
    function supportsInterface(
        bytes4 interfaceID
    ) public pure override returns (bool) {
        return
            interfaceID == type(IPublicationActionModule).interfaceId ||
            interfaceID == type(IValidator).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
