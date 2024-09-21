// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/interfaces/IOwnership.sol";
import "contracts/interfaces/IContentVault.sol";
import "contracts/interfaces/IRepository.sol";

/// @title ContentVault
/// @notice This contract stores encrypted content and ensures only the rightful content holder
/// can access or modify the content. It is designed to be upgradeable through UUPS and governed by a 
/// decentralized authority.
/// @dev The contract uses the OpenZeppelin UUPS (Universal Upgradeable Proxy Standard) upgrade mechanism 
/// and inherits Governable for governance control.
contract ContentVault is
    Initializable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    IContentVault
{
    /// @notice The Ownership contract that tracks content holders.
    IOwnership public ownership;

    /// @dev Mapping to store encrypted content, identified by content ID.
    mapping(uint256 => bytes) private secured; 

    /// @notice Error thrown when a non-owner tries to modify or access the content.
    error InvalidContentHolder();

    /// @dev Constructor that disables initializers to prevent the implementation contract 
    /// from being initialized. This is part of the UUPS security model.
    /// @notice For more information on the UUPS vulnerability and the importance of disabling initializers, 
    /// see:
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the necessary dependencies, such as the repository
    /// contract that contains references to the Ownership contract.
    /// @param repository The contract address of the repository where dependencies are stored.
    /// @dev This function can only be called once during the contract's lifecycle and sets up the UUPS 
    /// upgradeability and governance mechanisms.
    function initialize(address repository) public initializer {
        __UUPSUpgradeable_init();
        __Governable_init(_msgSender());

        IRepository repo = IRepository(repository);
        address ownershipAddress = repo.getContract(T.ContractTypes.OWN);
        ownership = IOwnership(ownershipAddress);
    }

    /// @notice Modifier that restricts access to the content holder only.
    /// @param contentId The identifier of the content.
    /// @dev Reverts if the sender is not the owner of the content based on the Ownership contract.
    modifier onlyHolder(uint256 contentId) {
        if (ownership.ownerOf(contentId) != _msgSender())
            revert InvalidContentHolder();
        _;
    }

    /// @notice Function that authorizes the contract upgrade. It ensures that only the admin 
    /// can authorize a contract upgrade to a new implementation.
    /// @param newImplementation The address of the new contract implementation.
    /// @dev Overrides the `_authorizeUpgrade` function from UUPSUpgradeable to enforce admin-only 
    /// access for upgrades.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Retrieves the encrypted content for a given content ID.
    /// @param contentId The identifier of the content.
    /// @return The encrypted content as bytes.
    /// @dev This function is used to access encrypted data stored in the vault, 
    /// which can include various types of encrypted information such as LIT chain data or shared key-encrypted data.
    function getContent(uint256 contentId) public view returns (bytes memory) {
        return secured[contentId];
    }

    /// @notice Stores encrypted content in the vault under a specific content ID.
    /// @param contentId The identifier of the content.
    /// @param encryptedContent The encrypted content to store, represented as bytes.
    /// @dev Only the rightful content holder can set or modify the content.
    /// This allows for dynamic secure storage, handling encrypted data like public key encrypted content or
    /// hash-encrypted data.
    function setContent(
        uint256 contentId,
        bytes memory encryptedContent
    ) public onlyHolder(contentId) {
        secured[contentId] = encryptedContent;
    }
}
