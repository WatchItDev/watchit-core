// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/types/Time.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "contracts/modules/lens/interfaces/IPublicationActionModule.sol";
// import "contracts/modules/lens/base/LensModuleMetadata.sol";
// import "contracts/modules/lens/base/LensModuleRegistrant.sol";
// import "contracts/modules/lens/base/HubRestricted.sol";
// import "contracts/interfaces/ILicense.sol";
// import "contracts/interfaces/IRightsManager.sol";
// import "contracts/libraries/Constants.sol";
// import "contracts/libraries/Types.sol";

// /**
//  * @title GatedContentModule
//  * @dev Contract that manages gated content access based on predefined conditions.
//  * It inherits from Ownable, IPublicationActionModule, LensModuleMetadata,
//  * LensModuleRegistrant, and HubRestricted.
//  */
// contract GatedContentModule is
//     Ownable,
//     LensModuleMetadata,
//     LensModuleRegistrant,
//     HubRestricted,
//     IPublicationActionModule,
//     ILicense
// {
//     using SafeERC20 for IERC20;

//     // Custom errors for specific failure cases
//     error InvalidExistingContentPublication();
//     error InvalidCondition();
//     error AccessDenied();

//     struct GateRegistry {
//         uint256 contentId;
//         address contractAddress;
//         string method;
//         bytes[] parameters;
//         bool isCustomGate;
//     }

//     // Mapping from publication ID to content ID
//     mapping(uint256 => uint256) contentRegistry;
//     mapping(uint256 => mapping(address => GateRegistry)) gatedConditions;

//     /**
//      * @dev Constructor that initializes the GatedContentModule contract.
//      * @param hub The address of the hub contract.
//      * @param registrant The address of the registrant contract.
//      * @param drm The address of the DRM contract.
//      */
//     constructor(
//         address hub,
//         address registrant,
//         address drm
//     )
//         Ownable(_msgSender())
//         HubRestricted(hub)
//         LensModuleRegistrant(registrant)
//     {}

//     /**
//      * @dev Registers a gating condition for a specific content ID.
//      * @param contentId The ID of the content to be gated.
//      * @param gate The gating condition.
//      */
//     function registerGatingCondition(
//         uint256 contentId,
//         GateRegistry memory gate
//     ) external onlyOwner {
//         gatedConditions[contentId][gate.contractAddress] = gate;
//     }

//     /**
//      * @inheritdoc ILensModuleRegistrant
//      * @dev Registers the GatedContentModule as a PUBLICATION_ACTION_MODULE.
//      * @return bool Success of the registration.
//      */
//     function registerModule() public onlyOwner returns (bool) {
//         return _registerModule(Types.ModuleType.PUBLICATION_ACTION_MODULE);
//     }

//     /**
//      * @dev Sets the metadata URI for the GatedContentModule.
//      * @param _metadataURI The new metadata URI.
//      */
//     function setModuleMetadataURI(
//         string calldata _metadataURI
//     ) public onlyOwner {
//         _setModuleMetadataURI(_metadataURI);
//     }

//     /**
//      * @dev Initializes a publication action for gating content access.
//      * @param profileId The ID of the profile initiating the action.
//      * @param pubId The ID of the publication being gated.
//      * @param transactionExecutor The address of the executor of the transaction.
//      * @param data Additional data required for the action.
//      * @return bytes memory The result of the action.
//      */
//     function initializePublicationAction(
//         uint256,
//         uint256 pubId,
//         address transactionExecutor,
//         bytes calldata data
//     ) external override onlyHub returns (bytes memory) {
//         Types.GateParams memory gateParams = abi.decode(
//             data,
//             (Types.GateParams)
//         );

//         IRightsManager drm = IRightsManager(gateParams.drmAddress);
//         if (drm.ownerOf(gateParams.contentId) != address(0))
//             revert InvalidExistingContentPublication();

//         contentRegistry[pubId] = gateParams.contentId;
//         drm.mint(transactionExecutor, gateParams.contentId);
//         drm.grantCustodial(
//             gateParams.contentId,
//             gateParams.distributor,
//             gateParams.encryptedContent
//         );

//         drm.delegateRights(address(this), gateParams.contentId);
//         registerGatingCondition(gateParams.contentId, gateParams.gate);

//         return data;
//     }

//     /// @inheritdoc ILicense
//     /// @notice Checks whether the terms (such as gated content conditions) for an account and content ID are satisfied.
//     /// @param account The address of the account being checked.
//     /// @param contentId The content ID associated with the access terms.
//     /// @return bool True if the terms are satisfied, false otherwise.
//     function terms(
//         address account,
//         uint256 contentId
//     ) external view override returns (bool) {
//         GateRegistry memory gate = gatedConditions[contentId][msg.sender];
//         return _checkGate(account, gate);
//     }

//     /// @inheritdoc ILicense
//     /// @notice Manages the allocation of royalties or fees based on gated content access.
//     /// @param account The address of the account initiating the transaction.
//     /// @param contentId The content ID related to the transaction.
//     /// @return T.Allocation The allocation details for the transaction.
//     function allocation(
//         address account,
//         uint256 contentId
//     ) external override returns (T.Allocation memory) {
//         GateRegistry memory gate = gatedConditions[contentId][msg.sender];
//         return
//             T.Allocation(
//                 T.Transaction(address(0), 0), 
//                 new T.Distribution 
//             );
//     }

//     /**
//      * @dev Internal function to check if a gating condition is met.
//      * @param account The address of the account.
//      * @param gate The gating condition.
//      * @return bool True if the gate is passed, false otherwise.
//      */
//     function _checkGate(
//         address account,
//         GateRegistry memory gate
//     ) internal view returns (bool) {
//         (bool success, bytes memory result) = gate.contractAddress.staticcall(
//             abi.encodeWithSignature(gate.method, account, gate.parameters)
//         );
//         return success && abi.decode(result, (bool));
//     }

//     /**
//      * @dev Checks if the contract supports a specific interface.
//      * @param interfaceID The ID of the interface to check.
//      * @return bool True if the contract supports the interface, false otherwise.
//      */
//     function supportsInterface(
//         bytes4 interfaceID
//     ) public pure override returns (bool) {
//         return
//             interfaceID == type(IPublicationActionModule).interfaceId ||
//             interfaceID == type(ILicense).interfaceId ||
//             super.supportsInterface(interfaceID);
//     }
// }
