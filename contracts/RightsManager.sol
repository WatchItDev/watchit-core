// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerERC721Upgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerDistributionUpgradeable.sol";

import "contracts/interfaces/IRegistrableVerifiable.sol";
import "contracts/interfaces/IRepository.sol";

/// @title Rights Manager
/// @notice This contract manages digital rights, allowing content holders to set prices, rent content, and manage access.
/// @dev This contract uses the UUPS upgradeable pattern and is initialized using the `initialize` function.
contract RightsManager is
    Initializable,
    IRepositoryConsumer,
    UUPSUpgradeable,
    GovernableUpgradeable,
    RightsManagerERC721Upgradeable,
    RightsManagerDistributionUpgradeable
{
    event RegisteredContent(uint256 contentId);
    event RevokedContent(uint256 contentId);

    // This role is granted to any holder representant trusted module. eg: Lens, Farcaster, etc.
    bytes32 private constant DELEGATED_ROLE = keccak256("DELEGATED_ROLE");

    address private syndication;

    /// @dev Error that is thrown when a restricted access to the holder is attempted.
    error RestrictedAccessToHolder();
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();
    error InvalidUnknownContent();

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given dependencies.
    /// @param _repository The contract registry to retrieve needed contracts instance.
    function initialize(address _repository) public initializer {
        __Governable_init();
        __ERC721_init("Watchit", "WOT");
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();

        IRepository repo = IRepository(_repository);
        syndication = repo.getContract(ContractTypes.SYNDICATION);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Modifier to restrict access to the holder only or delegated.
    /// @param contentId The content hash to give distribution rights.
    modifier onlyHolder(uint256 contentId) {
        if (
            ownerOf(contentId) != _msgSender() &&
            !hasRole(DELEGATED_ROLE, _msgSender())
        ) revert RestrictedAccessToHolder();
        _;
    }

    /// @notice Modifier to check if the content is registered.
    /// @param contentId The content hash to check.
    modifier onlyRegisteredContent(uint256 contentId) {
        if (ownerOf(contentId) != address(0)) revert InvalidUnknownContent();
        _;
    }

    /// @notice Modifier to check if the distributor is active and not blocked.
    /// @param distributor The distributor address to check.
    modifier onlyActiveDistributor(address distributor) {
        if (!IRegistrableVerifiable(syndication).isActive(distributor))
            revert InvalidInactiveDistributor();
        _;
    }

    /// @notice Grants custodial rights for the content to a distributor.
    /// @param distributor The address of the distributor.
    /// @param contentId The content ID to grant custodial rights for.
    function grantCustodial(
        address distributor,
        uint256 contentId
    )
        public
        onlyActiveDistributor(distributor)
        onlyRegisteredContent(contentId)
        onlyHolder(contentId)
    {
        _grantCustodial(distributor, contentId);
    }

    // /// @notice Grants content access to a watcher for a specific timeframe.
    // /// @param watcher The address of the watcher.
    // /// @param contentId The content ID to grant access to.
    // /// @param timeframe The timeframe for which access is granted.
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

   

    /// @dev Authorizes the upgrade of the contract.
    /// @notice Only the owner can authorize the upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Mints a new NFT to the specified address.
    /// @dev The minting is public. Our naive assumption is that only those who know the CID hash can mint the corresponding token.
    /// @param to The address to mint the NFT to.
    /// @param contentId The content id of the NFT. This should be a unique identifier for the NFT.
    function mint(address to, uint256 contentId) external {
        _mint(to, contentId);
        emit RegisteredContent(contentId);
    }

    /// @notice Burns a token based on the provided token ID.
    /// @dev This burn operation is generally delegated through governance.
    /// @param contentId The content id of the NFT to be burned.
    function burn(uint256 contentId) external onlyGov {
        _update(address(0), contentId, _msgSender());
        emit RevokedContent(contentId);
    }

    /// @notice Checks if the contract supports a specific interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(RightsManagerERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
