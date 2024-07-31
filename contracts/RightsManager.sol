// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/base/upgradeable/TreasuryUpgradeable.sol";
import "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import "contracts/base/upgradeable/CurrencyManagerUpgradeable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/base/upgradeable/ContentVaultUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerERC721Upgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerContentAccessUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerDistributionUpgradeable.sol";
import "contracts/interfaces/IRegistrableVerifiable.sol";
import "contracts/interfaces/IReferendumVerifiable.sol";
import "contracts/interfaces/IRepository.sol";
import "contracts/libraries/TreasuryHelper.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager
/// @notice This contract manages digital rights, allowing content holders to set prices, rent content, etc.
/// @dev This contract uses the UUPS upgradeable pattern and is initialized using the `initialize` function.
contract RightsManager is
    Initializable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    TreasuryUpgradeable,
    TreasurerUpgradeable,
    ContentVaultUpgradeable,
    CurrencyManagerUpgradeable,
    RightsManagerERC721Upgradeable,
    RightsManagerDistributionUpgradeable,
    RightsManagerContentAccessUpgradeable
{
    using TreasuryHelper for address;
    event GrantedCustodial(address distributor, uint256 contentId);
    event GrantedAccess(address account, uint256 contentId);
    event RegisteredContent(uint256 contentId);
    event RevokedContent(uint256 contentId);

    address private syndication;
    address private referendum;
    address private immutable __self = address(this);
    // This role is granted to any holder representant trusted module. eg: Lens, Farcaster, etc.
    bytes32 private constant DELEGATED_ROLE = keccak256("DELEGATED_ROLE");
    // This role is granted to any representant trusted account. eg: Verified Accounts, etc.
    bytes32 private constant VERIFIED_ROLE = keccak256("VERIFIED_ROLE");

    /// @dev Error that is thrown when a restricted access to the holder is attempted.
    error RestrictedAccessToHolder();
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();
    error InvalidUnknownContent();
    error InvalidNotApprovedContent();

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given dependencies.
    /// @param repository The contract registry to retrieve needed contracts instance.
    /// @param initialFee The initial fee for the treasury in basis points (bps).
    /// @dev This function is called only once during the contract deployment.
    function initialize(
        address repository,
        uint256 initialFee
    ) public initializer onlyBasePointsAllowed(initialFee) {
        __Governable_init();
        __ERC721_init("Watchit", "WOT");
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();
        __CurrencyManager_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        IRepository repo = IRepository(repository);
        syndication = repo.getContract(T.ContractTypes.SYNDICATION);
        referendum = repo.getContract(T.ContractTypes.REFERENDUM);
        // Get the registered treasury contract from the repository
        address initialTreasuryAddress = repo.getContract(
            T.ContractTypes.TREASURY
        );

        __Treasury_init(initialFee, address(0));
        __Treasurer_init(initialTreasuryAddress);
    }

    /// @notice Modifier to restrict access to the holder only or their delegate.
    /// @param contentId The content hash to give distribution rights.
    /// @dev Only the holder of the content and the delegated holder can pass this validation.
    /// When could this happen? If we have a TRUSTED delegated holder, such as a module of Lens, etc,
    /// we can add a delegated role to operate on behalf of the holder's account.
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
        if (ownerOf(contentId) == address(0)) revert InvalidUnknownContent();
        _;
    }

    /// @notice Modifier to check if the distributor is active and not blocked.
    /// @param distributor The distributor address to check.
    modifier onlyActiveDistributor(address distributor) {
        if (!IRegistrableVerifiable(syndication).isActive(distributor))
            revert InvalidInactiveDistributor();
        _;
    }

    /// @notice Modifier to ensure content is approved before distribution.
    /// @param to The address attempting to distribute the content.
    /// @param contentId The ID of the content to be distributed.
    /// @dev The content must be approved by referendum or the recipient must have a verified role.
    /// This modifier checks if the content is approved by referendum or if the recipient has a verified role.
    /// It also ensures that the recipient is the one who initially submitted the content for approval.
    modifier onlyApprovedContent(address to, uint256 contentId) {
        IReferendumVerifiable _referendum = IReferendumVerifiable(referendum);
        // Retrieve the address that initially submitted the content for referendum approval
        address approvalFor = _referendum.approvedFor(contentId);
        // Check if the content is approved by referendum or if the recipient has a verified role
        bool approved = _referendum.isApproved(contentId) ||
            hasRole(VERIFIED_ROLE, to);

        // Revert if the content is not approved or if the recipient is not the original submitter
        if (!approved || to != approvalFor) revert InvalidNotApprovedContent();
        _;
    }

    /// @inheritdoc ITreasury
    /// @notice Sets a new treasury fee for a specific token.
    /// @param newTreasuryFee The new fee amount to be set.
    /// @param token The address of the token for which the fee is to be set.
    function setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) public onlyGov onlyBasePointsAllowed(newTreasuryFee) {
        _setTreasuryFee(newTreasuryFee, token);
        _addCurrency(token);
    }

    /// @inheritdoc ITreasury
    /// @notice Sets a new treasury fee for the native token.
    /// @param newTreasuryFee The new fee amount to be set.
    function setTreasuryFee(
        uint256 newTreasuryFee
    ) public onlyGov onlyBasePointsAllowed(newTreasuryFee) {
        _setTreasuryFee(newTreasuryFee, address(0));
        _addCurrency(address(0));
    }

    /// @inheritdoc ITreasurer
    /// @notice Sets the address of the treasury.
    /// @param newTreasuryAddress The new treasury address to be set.
    /// @dev Only callable by the governance role.
    function setTreasuryAddress(address newTreasuryAddress) public onlyGov {
        _setTreasuryAddress(newTreasuryAddress);
    }

    /// @inheritdoc ITreasurer
    /// @notice Collects funds of a specific token from the contract and sends them to the treasury.
    /// @param token The address of the token.
    /// @dev Only callable by an admin.
    function collectFunds(address token) public onlyAdmin {
        // collect native token and send it to treasury
        address treasure = getTreasuryAddress();
        treasure.disburst(__self.balanceOf(token));
    }

    /// @inheritdoc ITreasurer
    /// @notice Collects funds from the contract and sends them to the treasury.
    /// @dev Only callable by an admin.
    function collectFunds() public onlyAdmin {
        // collect native token and send it to treasury
        address treasure = getTreasuryAddress();
        treasure.disburst(__self.balanceOf());
    }

    /// @inheritdoc IContentVault
    /// @notice Stores encrypted content in the vault.
    /// @param contentId The identifier of the content.
    /// @param encryptedContent The encrypted content to store.
    function secureContent(
        uint256 contentId,
        bytes calldata encryptedContent
    ) external onlyHolder(contentId) {
        _secureContent(contentId, encryptedContent);
    }

    /// @inheritdoc IRightsAccessController
    /// @notice Grants access to a specific watcher for a certain content ID for a given timeframe.
    /// @param account The address of the watcher.
    /// @param contentId The content ID to grant access to.
    /// @param condition The conditional params to validate access.
    function grantAccess(
        address account,
        uint256 contentId,
        T.AccessCondition calldata condition
    ) external onlyRegisteredContent(contentId) onlyHolder(contentId) {
        _grantAccess(account, contentId, condition);
        emit GrantedAccess(account, contentId);
    }

    /// @inheritdoc IRightsCustodial
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
        emit GrantedCustodial(distributor, contentId);
    }

    /// @dev Authorizes the upgrade of the contract.
    /// @notice Only the owner can authorize the upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @inheritdoc IRightsOwnership
    /// @notice Mints a new NFT to the specified address.
    /// @dev Our naive assumption is that only those who know the CID hash can mint the corresponding token.
    /// @param to The address to mint the NFT to.
    /// @param contentId The content id of the NFT. This should be a unique identifier for the NFT.
    function mint(
        address to,
        uint256 contentId
    ) external onlyApprovedContent(to, contentId) {
        _mint(to, contentId);
        emit RegisteredContent(contentId);
    }

    /// @inheritdoc IRightsOwnership
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
