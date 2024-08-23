// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/base/upgradeable/LedgerUpgradeable.sol";
import "contracts/base/upgradeable/FeesManagerUpgradeable.sol";
import "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import "contracts/base/upgradeable/CurrencyManagerUpgradeable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/base/upgradeable/ContentVaultUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerERC721Upgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerContentAccessUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerCustodialUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerDelegationUpgradeable.sol";
import "contracts/interfaces/IRegistrableVerifiable.sol";
import "contracts/interfaces/IReferendumVerifiable.sol";
import "contracts/interfaces/IRightsManager.sol";
import "contracts/interfaces/IPolicy.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/IRepository.sol";
import "contracts/libraries/TreasuryHelper.sol";
import "contracts/libraries/FeesHelper.sol";
import "contracts/libraries/Constants.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager
/// @notice This contract manages digital rights, allowing content holders to set prices, rent content, etc.
/// @dev This contract uses the UUPS upgradeable pattern and is initialized using the `initialize` function.
contract RightsManager is
    Initializable,
    UUPSUpgradeable,
    LedgerUpgradeable,
    FeesManagerUpgradeable,
    GovernableUpgradeable,
    TreasurerUpgradeable,
    ContentVaultUpgradeable,
    ReentrancyGuardUpgradeable,
    CurrencyManagerUpgradeable,
    RightsManagerERC721Upgradeable,
    RightsManagerCustodialUpgradeable,
    RightsManagerContentAccessUpgradeable,
    RightsManagerDelegationUpgradeable,
    IRightsManager
{
    using TreasuryHelper for address;
    using FeesHelper for uint256;

    /// @notice Emitted when distribution custodial rights are granted to a distributor.
    /// @param prevCustody The previous distributor custodial address.
    /// @param newCustody The new distributor custodial address.
    /// @param contentId The content identifier.
    event GrantedCustodial(
        address indexed prevCustody,
        address indexed newCustody,
        uint256 contentId
    );

    event FeesDisbursed(
        address indexed treasury,
        uint256 amount,
        address currency
    );

    event RegisteredContent(uint256 contentId);
    event GrantedAccess(address account, uint256 contentId);
    event RightsDelegated(address indexed policy, uint256 contentId);
    event RightsRevoked(address indexed policy, uint256 contentId);

    /// KIM: any initialization here is ephimeral and not included in bytecode..
    /// so the code within a logic contract’s constructor or global declaration
    /// will never be executed in the context of the proxy’s state
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#the-constructor-caveat
    address private syndication;
    address private referendum;

    /// @dev Error that is thrown when a restricted access to the holder is attempted.
    error RestrictedAccessToHolder();
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();
    error InvalidNotApprovedContent();
    error InvalidNotAllowedContent();
    error InvalidUnknownContent();
    error InvalidAccessValidation(string reason);
    error InvalidAlreadyRegisteredContent();
    error NoFundsToWithdraw(address);
    error NoDeal(string reason);

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
        __Ledger_init();
        __Governable_init();
        __ContentVault_init();
        __ERC721_init("Watchit", "WOT");
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __CurrencyManager_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        IRepository repo = IRepository(repository);
        syndication = repo.getContract(T.ContractTypes.SYNDICATION);
        referendum = repo.getContract(T.ContractTypes.REFERENDUM);
        // Get the registered treasury contract from the repository
        address treasury = repo.getContract(T.ContractTypes.TREASURY);

        __Fees_init(initialFee, address(0));
        __Treasurer_init(treasury);
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
    ) private returns (bool) {
        IRegistrableVerifiable _v = IRegistrableVerifiable(syndication);
        return _v.isActive(distributor); // is active status in syndication
    }

    /// @notice Checks if the given content is active and not blocked.
    /// @param contentId The ID of the content to check.
    /// @return True if the content is active, false otherwise.
    function _checkActiveContent(
        uint256 contentId
    ) private view returns (bool) {
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
    ) private view returns (bool) {
        IReferendumVerifiable _v = IReferendumVerifiable(referendum);
        return _v.isApproved(to, contentId); // is approved by referendu,
    }

    /// @notice Calculates the portion of an amount based on a given split percentage.
    /// @dev The split percentage is represented in base points (bps), where 10000 bps equals 100%.
    /// Ensures the split is within allowed base points.
    /// @param amount The total amount to be split.
    /// @param split The percentage of the amount to allocate, represented in base points.
    /// @return The calculated split amount.
    function _calculateSplit(
        uint256 amount,
        uint256 split
    ) private onlyBasePointsAllowed(split) returns (uint256) {
        return amount.perOf(split);
    }

    /// @notice Allocates the specified amount across a distribution array and returns the remaining unallocated amount.
    /// @dev Distributes the amount based on the provided distribution array.
    /// Ensures no more than 100 allocations and a minimum of 1% per distributor.
    /// @param amount The total amount to be allocated.
    /// @param currency The address of the currency being allocated.
    /// @param splits An array of Splits structs specifying the split percentages and target addresses.
    /// @return The remaining unallocated amount after distribution.
    function _allocate(
        uint256 amount,
        address currency,
        T.Splits[] memory splits
    ) private returns (uint256) {
        // Ensure there's a distribution or return the full amount.
        if (splits.length == 0) return amount;
        if (splits.length > 100) {
            revert NoDeal(
                "Invalid split allocations. Cannot be more than 100."
            );
        }

        uint8 i = 0;
        uint256 accBps = 0; // Accumulated base points
        uint256 accTotal = 0; // Accumulated total allocation

        while (i < splits.length) {
            // Retrieve base points and target address from the distribution array.
            uint256 bps = splits[i].bps;
            address target = splits[i].target;
            // safely increment i uncheck overflow
            unchecked {
                ++i;
            }

            if (bps == 0) continue;
            // Calculate and register the allocation for each distribution.
            uint256 registeredAmount = _calculateSplit(amount, bps);
            _sumLedgerEntry(target, registeredAmount, currency);

            accTotal += registeredAmount;
            accBps += bps;
        }

        // Ensure the total base points do not exceed the maximum allowed (100%).
        if (accBps > C.BPS_MAX)
            revert NoDeal("Invalid split base points overflow.");
        return amount - accTotal; // Return the remaining unallocated amount.
    }

    /// @notice Modifier to restrict access to the holder only or their delegate.
    /// @param contentId The content hash to give distribution rights.
    /// @dev Only the holder of the content can pass this validation.
    modifier onlyHolder(uint256 contentId) {
        if (ownerOf(contentId) != _msgSender())
            revert RestrictedAccessToHolder();
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
    /// @notice Sets a new treasury fee for a specific currency.
    /// @param newTreasuryFee The new fee amount to be set.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function setFees(
        uint256 newTreasuryFee,
        address currency
    )
        external
        onlyGov
        onlyValidCurrency(currency)
        onlyBasePointsAllowed(newTreasuryFee)
    {
        _setFees(newTreasuryFee, currency);
        _addCurrency(currency);
    }

    /// @inheritdoc IFeesManager
    /// @notice Sets a new treasury fee for the native coin.
    /// @param newTreasuryFee The new fee amount to be set.
    function setFees(
        uint256 newTreasuryFee
    ) external onlyGov onlyBasePointsAllowed(newTreasuryFee) {
        _setFees(newTreasuryFee, address(0));
        _addCurrency(address(0));
    }

    /// @inheritdoc ITreasurer
    /// @notice Sets the address of the treasury.
    /// @param newTreasuryAddress The new treasury address to be set.
    /// @dev Only callable by the governance role.
    function setTreasuryAddress(address newTreasuryAddress) external onlyGov {
        _setTreasuryAddress(newTreasuryAddress);
    }

    /// @inheritdoc IDisburser
    /// @notice Disburses funds from the contract to a specified address.
    /// @param amount The amount of currencies to disburse.
    /// @param currency The address of the ERC20 token to disburse tokens.
    /// @dev This function can only be called by governance or an authorized entity.
    function disburse(
        uint256 amount,
        address currency
    ) external onlyGov onlyValidCurrency(currency) {
        address treasury = getTreasuryAddress();
        treasury.transfer(amount, currency);
        emit FeesDisbursed(treasury, amount, currency);
    }

    /// @inheritdoc IDisburser
    /// @notice Disburses funds from the contract to a specified address.
    /// @param amount The amount of coins to disburse.
    /// @dev This function can only be called by governance or an authorized entity.
    function disburse(uint256 amount) external onlyGov {
        // collect native coins and send it to treasury
        address treasury = getTreasuryAddress();
        // if no balance revert..
        treasury.transfer(amount);
        emit FeesDisbursed(treasury, amount, address(0));
    }

    /// @inheritdoc IFundsManager
    /// @notice Withdraws funds from the contract to a specified recipient's address.
    /// @param recipient The address that will receive the withdrawn funds.
    /// @param amount The amount of funds to withdraw.
    /// @param currency The address of the ERC20 token to withdraw, or address(0) to withdraw native coins.
    function withdraw(
        address recipient,
        uint256 amount,
        address currency
    ) external onlyValidCurrency(currency) {
        uint256 available = getLedgerEntry(recipient, currency);
        if (available < amount) revert NoFundsToWithdraw(recipient);
        recipient.transfer(amount, currency);
        _subLedgerEntry(recipient, amount, currency);
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
            _checkActiveDistributor(getCustody(contentId)) &&
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

    // TODO grantCustody with signature
    /// @inheritdoc IRightsCustodial
    /// @notice Grants custodial rights for the content to a distributor.
    /// @param distributor The address of the distributor.
    /// @param contentId The content ID to grant custodial rights for.
    /// @param encryptedContent Additional encrypted data to share access between authorized parties.
    function grantCustody(
        uint256 contentId,
        address distributor,
        bytes calldata encryptedContent
    )
        external
        onlyActiveDistributor(distributor)
        onlyRegisteredContent(contentId)
        onlyHolder(contentId)
    {
        // if it's first custody assignment prev = address(0)
        address prevCustody = getCustody(contentId);
        _grantCustody(distributor, contentId);
        _secureContent(contentId, encryptedContent);
        emit GrantedCustodial(prevCustody, distributor, contentId);
    }

    /// @inheritdoc IRightsDelegable
    /// @notice Delegates rights for a specific content ID to a license policy.
    /// @param policy The address of the policy contract to delegate rights to.
    /// @param contentId The content ID for which rights are being delegated.
    function delegateRights(
        address policy,
        uint256 contentId
    )
        external
        onlyHolder(contentId)
        onlyRegisteredContent(contentId)
        onlyPolicyContract(policy)
    {
        _delegateRights(policy, contentId);
        emit RightsDelegated(policy, contentId);
    }

    /// @inheritdoc IRightsDelegable
    /// @notice Revoke rights for a specific content ID to a license policy.
    /// @param policy The address of license policy contract to revoke rights to.
    /// @param contentId The content ID for which rights are being revoked.
    function revokeRights(
        address policy,
        uint256 contentId
    )
        external
        onlyHolder(contentId)
        onlyRegisteredContent(contentId)
        onlyPolicyContract(policy)
    {
        _revokeRights(policy, contentId);
        emit RightsRevoked(policy, contentId);
    }

    /// @inheritdoc IRightsAccessController
    /// @notice Registers and enforces access for a specific account to a content ID based on the conditions set by a policy.
    /// @param account The address of the account to be granted access to the content.
    /// @param contentId The unique identifier of the content for which access is being registered.
    /// @param policy The address of the policy contract responsible for validating and enforcing the access conditions.
    /// @dev Access is granted only if the specified policy contract is valid and has the necessary delegation rights.
    /// If the policy conditions are not met, access will not be registered, and the operation will be rejected.
    function registerPolicy(
        uint256 contentId,
        address account,
        address policy
    )
        external
        payable
        nonReentrant
        onlyRegisteredContent(contentId)
        onlyWhenRightsDelegated(policy, contentId)
    {
        // in some cases the content or distributor could be revoked..
        if (!isEligibleForDistribution(contentId))
            revert InvalidNotAllowedContent();

        IPolicy advocate = IPolicy(policy);
        T.Terms calldata terms = advocate.terms(account, contentId);
        uint256 amount = terms.t9n.amount;
        address currency = terms.t9n.currency;

        // get distributors conditions
        address custodial = getCustody(contentId);
        uint256 custodials = getCustodyCount(custodial);
        IDistributor distributor = IDistributor(cusdotial);
        // The user, owner or delegated policy must ensure that the necessary steps
        // are taken to handle the transaction value or set the appropriate
        // approve/allowance for the DRM (Digital Rights Management) contract.
        uint256 total = policy.safeDeposit(amount, currency);
        //!IMPORTANT if distributor or trasury does not support the currency, will revert..
        // the max bps integrity is warrantied by treasure fees
        uint256 treasurySplit = total.perOf(getFees(currency)); // bps
        uint256 acceptedSplit = distributor.negotiate(
            total,
            currency,
            custodials
        );

        uint256 deductions = treasurySplit + acceptedSplit;
        if (deductions > total) revert NoDeal("The fees are too high.");
        uint256 remaining = _allocate(total - deductions, currency, terms.s4s);

        // register split distribution in ledger..
        _sumLedgerEntry(ownerOf(contentId), remaining, currency);
        _sumLedgerEntry(distributor.getManager(), acceptedSplit, currency);
        _registerPolicy(account, contentId, policy);
        emit GrantedAccess(account, contentId);
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
