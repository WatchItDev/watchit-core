// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/ISyndicatable.sol";
import "contracts/interfaces/IOwnership.sol";
import "contracts/interfaces/IRepository.sol";

/// @title Digital Rights Manager
/// @notice This contract manages digital rights, allowing content holders to set prices, rent content, and manage access.
/// @dev This contract uses the UUPS upgradeable pattern and is initialized using the `initialize` function.
contract DigitalRightsManager is
    Initializable,
    IRepositoryConsumer,
    GovernableUpgradeable,
    QuorumUpgradeable,
    UUPSUpgradeable
{
    event RightsGranted(uint256 contentId, IDistributor indexed distributor);
    event RegisteredContent(uint256 contentId);
    event ApprovedContent(uint256 contentId);
    event RevokedContent(uint256 contentId);

    // Mapping to store the private content ID for each registered content hash
    mapping(uint256 contentId => uint256 privateCid) private vault;
    /// mapping to record the current content custody contract.
    mapping(uint256 => IDistributor) private custodying;
    // Mapping to store the access control list for each watcher and content hash
    mapping(address watcher => mapping(uint256 contentId => uint256 timeframe))
        private acl;

    IERC721 private ownership;
    ISyndicatable private syndication;

    /// @dev Error that is thrown when a restricted access to the holder is attempted.
    error RestrictedAccessToHolder();
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given dependencies.
    /// @param registry The contract registry to retrieved needed contracts instance.
    function initialize(IRepository registry) public initializer {
        __Governable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        ownership = IOwnership(registry.getContract(ContractTypes.OWNERSHIP));
        syndication = ISyndicatable(
            registry.getContract(ContractTypes.SYNDICATION)
        );
    }

    /// @dev Upgrades the contract version.
    /// @notice Only the admin can upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Modifier to restrict access to the holder only.
    /// @param contentId The content hash to give distribution rights.
    modifier holderOnly(uint256 contentId) {
        if (ownership.ownerOf(contentId) != _msgSender())
            revert RestrictedAccessToHolder();
        _;
    }

    /// @notice Modifier to check if the distributor is active and not blocked.
    /// @param distributor The distributor address to check.
    modifier activeOnly(address distributor) {
        if (!syndication.isActive(distributor))
            revert InvalidInactiveDistributor();

        _;
    }

    /// @notice Modifier to restrict access to unregistered content only.
    /// @param contentId The content hash to check registration.
    modifier notRegisteredOnly(uint256 contentId) {
        if (_status(contentId) != Status.Pending)
            revert AlreadyPendingApproval();
        _;
    }

    /// @notice Modifier to restrict access to registered content only.
    /// @param contentId The content hash to check registration.
    modifier registeredOnly(uint256 contentId) {
        if (_status(contentId) != Status.Active) revert InvalidInactiveState();
        _;
    }

    // /// @notice Registers a new content with a private content id and hash.
    // /// @param contentId The content hash to register.
    // /// @param privateCid The private content ID to register.
    // function registerContent(
    //     uint256 contentId,
    //     uint256 privateCid
    // ) public holderOnly(contentId) notRegisteredOnly(contentId) {
    //     vault[contentId] = privateCid;
    //     _register(contentId);
    //     emit RegisteredContent(contentId);
    // }

    // /// @notice Registers a new content with a private content id and hash.
    // /// @param contentId The content hash to register.
    // function approveContent(
    //     uint256 contentId
    // ) public onlyGov registeredOnly(contentId) {
    //     _approve(contentId);
    //     emit ApprovedContent(contentId);
    // }

    // /// @notice Registers a new content with a private content id and hash.
    // /// @param contentId The content hash to register.
    // function revokeContent(
    //     uint256 contentId
    // ) public onlyGov registeredOnly(contentId) {
    //     _revoke(contentId);
    //     emit RevokedContent(contentId);
    // }

    // function granContentAccess(
    //     address watcher,
    //     uint256 contentId,
    //     uint256 timeframe
    // ) public registeredOnly(contentId) {
    //     acl[watcher][contentId] = block.timestamp + timeframe;
    // }

    // /// @notice Checks if access is allowed for a specific watcher and content.
    // /// @param watcher The address of the watcher.
    // /// @param cidHash The content hash to check access for.
    // /// @return True if access is allowed, false otherwise.
    // function hasContentAccess(
    //     address watcher,
    //     uint256 cidHash
    // ) public view returns (bool) {
    //     return acl[watcher][cidHash] <= Time.timestamp();
    // }

    // // // this is where the fees are routed
    // function getCustodial(
    //     uint256 contentId
    // ) public view registeredOnly(contentId) returns (IDistributor) {
    //     return custodying[contentId];
    // }

    // function grantDistributionRights(
    //     address distributor,
    //     uint256 contentId
    // )
    //     public
    //     holderOnly(contentId)
    //     registeredOnly(contentId)
    //     activeOnly(distributor)
    // {
    //     // replace or create a new custodian
    //     // TODO un pure function que retorne el decripted text basado en el shared key y texto
    //     // TODO una pure function que calcule un shared key basado en los parametros
    //     custodying[contentId] = IDistributor(distributor);
    //     emit RightsGranted(contentId, custodying[contentId]);
    // }

}
