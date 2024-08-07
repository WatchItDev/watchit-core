// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/base/upgradeable/FeesManagerUpgradeable.sol";
import "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import "contracts/base/upgradeable/CurrencyManagerUpgradeable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/base/upgradeable/ContentVaultUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerERC721Upgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerContentAccessUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerDistributionUpgradeable.sol";
import "contracts/interfaces/IRegistrableVerifiable.sol";
import "contracts/interfaces/IReferendumVerifiable.sol";
import "contracts/interfaces/IRightsManager.sol";
import "contracts/interfaces/IRepository.sol";
import "contracts/libraries/TreasuryHelper.sol";
import "contracts/libraries/MathHelper.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager
/// @notice This contract manages digital rights, allowing content holders to set prices, rent content, etc.
/// @dev This contract uses the UUPS upgradeable pattern and is initialized using the `initialize` function.
contract RightsManager is
    Initializable,
    UUPSUpgradeable,
    FeesManagerUpgradeable,
    GovernableUpgradeable,
    TreasurerUpgradeable,
    ContentVaultUpgradeable,
    ReentrancyGuardUpgradeable,
    CurrencyManagerUpgradeable,
    RightsManagerERC721Upgradeable,
    RightsManagerDistributionUpgradeable,
    RightsManagerContentAccessUpgradeable,
    IRightsManager
{
    using TreasuryHelper for address;
    using MathHelper for uint256;

    event GrantedCustodial(address distributor, uint256 contentId);
    event GrantedAccess(address account, uint256 contentId);
    event RegisteredContent(uint256 contentId);
    event RevokedContent(uint256 contentId);

    address private syndication;
    address private referendum;
    // This role is granted to any holder representant trusted module. eg: Lens, Farcaster, etc.
    bytes32 private constant OP_ROLE = keccak256("OP_ROLE");

    /// @dev Error that is thrown when a restricted access to the holder is attempted.
    error RestrictedAccessToHolder();
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();
    error InvalidNotApprovedContent();
    error InvalidNotAllowedContent();
    error InvalidUnknownContent();

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

        __Fees_init(initialFee, address(0));
        __Treasurer_init(initialTreasuryAddress);
    }

    /// @dev Authorizes the upgrade of the contract.
    /// @notice Only the owner can authorize the upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Checks if the given distributor is active and not blocked.
    /// @param distributor The address of the distributor to check.
    /// @return True if the distributor is active, false otherwise.
    function _checkActiveDistributor(
        address distributor
    ) internal returns (bool) {
        IRegistrableVerifiable _v = IRegistrableVerifiable(syndication);
        return _v.isActive(distributor); // is active status in syndication
    }

    /// @notice Checks if the given content is active and not blocked.
    /// @param contentId The ID of the content to check.
    /// @return True if the content is active, false otherwise.
    function _checkActiveContent(
        uint256 contentId
    ) internal view returns (bool) {
        IReferendumVerifiable _v = IReferendumVerifiable(referendum);
        return _v.isActive(contentId); // is active in referendum
    }

    /// @notice Checks if the given content is approved for distribution.
    /// @param to The address attempting to distribute the content.
    /// @param contentId The ID of the content to be distributed.
    /// @return True if the content is approved, false otherwise.
    function _checkApprovedContent(
        address to,
        uint256 contentId
    ) internal view returns (bool) {
        IReferendumVerifiable _v = IReferendumVerifiable(referendum);
        return _v.isApproved(to, contentId); // is approved by referendu,
    }

    /// @notice Modifier to restrict access to the holder only or their delegate.
    /// @param contentId The content hash to give distribution rights.
    /// @dev Only the holder of the content and the delegated holder can pass this validation.
    /// When could this happen? If we have a TRUSTED delegated holder, such as a module of Lens, etc,
    /// we can add a delegated role to operate on behalf of the holder's account.
    modifier onlyHolder(uint256 contentId) {
        if (
            ownerOf(contentId) != _msgSender() &&
            !hasRole(OP_ROLE, _msgSender())
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
        if (!_checkActiveDistributor(distributor))
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
        // Revert if the content is not approved or if the recipient is not the original submitter
        if (!_checkApprovedContent(to, contentId))
            revert InvalidNotApprovedContent();
        _;
    }

    /// @inheritdoc IFeesManager
    /// @notice Sets a new treasury fee for a specific token.
    /// @param newTreasuryFee The new fee amount to be set.
    /// @param token The address of the token for which the fee is to be set.
    function setFees(
        uint256 newTreasuryFee,
        address token
    ) public onlyGov onlyBasePointsAllowed(newTreasuryFee) {
        _setFees(newTreasuryFee, token);
        _addCurrency(token);
    }

    /// @inheritdoc IFeesManager
    /// @notice Sets a new treasury fee for the native token.
    /// @param newTreasuryFee The new fee amount to be set.
    function setFees(
        uint256 newTreasuryFee
    ) public onlyGov onlyBasePointsAllowed(newTreasuryFee) {
        _setFees(newTreasuryFee, address(0));
        _addCurrency(address(0));
    }

    /// @inheritdoc ITreasurer
    /// @notice Sets the address of the treasury.
    /// @param newTreasuryAddress The new treasury address to be set.
    /// @dev Only callable by the governance role.
    function setTreasuryAddress(address newTreasuryAddress) public onlyGov {
        _setTreasuryAddress(newTreasuryAddress);
    }

    /// @inheritdoc IDisburser
    /// @notice Withdraw funds of a specific token from the contract and sends them to the treasury.
    /// @param token The address of the token.
    /// @param amount The amount of tokens to withdraw.
    /// @dev Only callable by governance.
    function withdraw(uint256 amount, address token) public onlyGov {
        // collect native token and send it to treasury
        address treasury = getTreasuryAddress();
        treasury.disburst(amount, token);
    }

    /// @inheritdoc IDisburser
    /// @notice Withdraw funds from the contract and sends them to the treasury.
    /// @param amount The amount of coins to withdraw.
    /// @dev Only callable by governance.
    function withdraw(uint256 amount) public onlyGov {
        // collect native token and send it to treasury
        address treasure = getTreasuryAddress();
        treasure.disburst(amount);
    }

    /// @inheritdoc IRightsManager
    /// @notice Checks if the content is eligible for distribution.
    /// @param contentId The ID of the content.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(
        uint256 contentId
    ) public returns (bool) {
        // Perform checks to ensure the content/distributor has not been blocked.
        // Check if the content's custodial is active in the Syndication contract
        // and if the content is active in the Referendum contract.
        return
            _checkActiveDistributor(getCustodial(contentId)) &&
            _checkActiveContent(contentId);
    }

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

    /// @inheritdoc IRightsCustodial
    /// @notice Grants custodial rights for the content to a distributor.
    /// @param distributor The address of the distributor.
    /// @param contentId The content ID to grant custodial rights for.
    /// @param encryptedContent Additional encrypted data to share access between authorized parties.
    function grantCustodial(
        uint256 contentId,
        address distributor,
        bytes calldata encryptedContent
    )
        public
        onlyActiveDistributor(distributor)
        onlyRegisteredContent(contentId)
        onlyHolder(contentId)
    {
        _grantCustodial(distributor, contentId);
        _secureContent(contentId, encryptedContent);
        emit GrantedCustodial(distributor, contentId);
    }

    /// @inheritdoc IRightsAccessController
    /// @notice Grants access to a specific account for a certain content ID for a given timeframe.
    /// @param account The address of the account.
    /// @param contentId The content ID to grant access to.
    /// @param condition The proof to validate access.
    function grantAccess(
        address account,
        uint256 contentId,
        T.AccessCondition calldata condition
    ) public onlyRegisteredContent(contentId) onlyHolder(contentId) {
        // in some cases the content or distributor could be revoked..
        if (!isEligibleForDistribution(contentId))
            revert InvalidNotAllowedContent();

        address owner = ownerOf(contentId);
        address custodial = getCustodial(contentId);
        //!IMPORTANT if distributor or trasury does not support the currency, will revert..
        uint256 treasurySplit = getFees(condition.txCurrency); // bps
        uint256 distSplit = IFeesManager(custodial).getFees(condition.txCurrency); // bps

        // get treasure fees and subtract from transaction amount
        uint256 treasuryFees = condition.txAmount.perOf(treasurySplit);
        uint256 total = condition.txAmount - treasuryFees;

        // the max bps integrity is warrantied by treasure fees only bps modifier
        uint256 distributorFees = total.perOf(distSplit);
        uint256 depositToOwner = total - distributorFees;

        // Deposit the calculated amounts to the respective addresses
        account.safeDeposit(owner, depositToOwner, condition.txCurrency);
        account.safeDeposit(custodial, distributorFees, condition.txCurrency);
        account.safeDeposit(address(this), treasuryFees, condition.txCurrency);

        _grantAccess(account, contentId, condition);
        emit GrantedAccess(account, contentId);
    }

    /// @inheritdoc IRightsAccessController
    /// @notice Checks if access is allowed for a specific account and content.
    /// @param account The address of the account.
    /// @param contentId The content ID to check access for.
    /// @return True if access is allowed, false otherwise.
    /// @dev This function is marked as noReentrant because the access check calls an external contract
    /// to verify the conditions. A malicious attacker could attempt a reentrancy attack or an infinite
    /// callback loop, so the reentrancy guard is necessary.
    function isAccessGranted(
        address account,
        uint256 contentId
    ) public nonReentrant onlyRegisteredContent(contentId) returns (bool) {
        // content is active and has access to content..
        return
            _checkActiveContent(contentId) &&
            _isAccessGranted(account, contentId);
    }

    /// @notice Checks if the contract supports a specific interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            IERC165,
            RightsManagerERC721Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
