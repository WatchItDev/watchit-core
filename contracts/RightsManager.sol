// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "contracts/base/upgradeable/LedgerUpgradeable.sol";
import "contracts/base/upgradeable/FeesManagerUpgradeable.sol";
import "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import "contracts/base/upgradeable/CurrencyManagerUpgradeable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";

import "contracts/base/upgradeable/extensions/RightsManagerBrokerUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerContentAccessUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerCustodialUpgradeable.sol";
import "contracts/base/upgradeable/extensions/RightsManagerPolicyControllerUpgradeable.sol";

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
    FeesManagerUpgradeable,
    GovernableUpgradeable,
    TreasurerUpgradeable,
    ReentrancyGuardUpgradeable,
    CurrencyManagerUpgradeable,
    RightsManagerBrokerUpgradeable,
    RightsManagerCustodialUpgradeable,
    RightsManagerContentAccessUpgradeable,
    RightsManagerPolicyControllerUpgradeable,
    IRightsManager
{
    using TreasuryHelper for address;
    using FeesHelper for uint256;

    /// @notice Emitted when distribution custodial rights are granted to a distributor.
    /// @param prevCustody The previous distributor custodial address.
    /// @param newCustody The new distributor custodial address.
    /// @param rightsHolder The content rights holder.
    event CustodialGranted(
        address indexed prevCustody,
        address indexed newCustody,
        address indexed rightsHolder
    );

    event FeesDisbursed(
        address indexed treasury,
        uint256 amount,
        address currency
    );

    event AccessGranted(
        address indexed account,
        bytes32 indexed proof,
        address indexed policy
    );

    event RightsGranted(address indexed policy, address holder);
    event RightsRevoked(address indexed policy, address holder);

    /// KIM: any initialization here is ephimeral and not included in bytecode..
    /// so the code within a logic contract’s constructor or global declaration
    /// will never be executed in the context of the proxy’s state
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#the-constructor-caveat
    IRegistrableVerifiable private syndication;
    IReferendumVerifiable private referendum;

    /// @dev Error thrown when attempting to operate on a policy that has not
    /// been delegated rights for the specified content.
    /// @param policy The address of the policy contract attempting to access rights.
    /// @param holder The content rights holder.
    error InvalidNotRightsDelegated(address policy, address holder);
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();
    error InvalidNotAllowedContent();
    error InvalidAccessValidation(string reason);
    error InvalidAlreadyRegisteredContent();
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
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __CurrencyManager_init();
        __Governable_init(_msgSender());

        // initialize dependencies for RM
        IRepository repo = IRepository(repository);
        address treasuryAddress = repo.getContract(T.ContractTypes.TRE);
        address syndicationAddress = repo.getContract(T.ContractTypes.SYN);
        address referendumAddress = repo.getContract(T.ContractTypes.REF);

        syndication = IRegistrableVerifiable(syndicationAddress);
        referendum = IReferendumVerifiable(referendumAddress);

        __Fees_init(initialFee, address(0));
        __Treasurer_init(treasuryAddress);
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
        return syndication.isActive(distributor); // is active status in syndication
    }

    /// @notice Checks if the given content is active and not blocked.
    /// @param contentId The ID of the content to check.
    /// @return True if the content is active, false otherwise.
    function _checkActiveContent(
        uint256 contentId
    ) private view returns (bool) {
        return referendum.isActive(contentId); // is active in referendum
    }

    /// @notice Allocates the specified amount across a distribution array and returns the remaining unallocated amount.
    /// @dev Distributes the amount based on the provided distribution array.
    /// @param amount The total amount to be allocated.
    /// @param currency The address of the currency being allocated.
    /// @param shares An array of Splits structs specifying the split percentages and target addresses.
    /// @return The remaining unallocated amount after distribution.
    function _allocate(
        uint256 amount,
        address currency,
        T.Shares[] memory shares
    ) private returns (uint256) {
        // Ensure there's a distribution or return the full amount.
        if (shares.length == 0) return amount;
        if (shares.length > 100) {
            revert NoDeal(
                "Invalid split allocations. Cannot be more than 100."
            );
        }

        uint8 i = 0;
        uint256 accBps = 0; // accumulated base points
        uint256 accTotal = 0; // accumulated total allocation

        while (i < shares.length) {
            // Retrieve base points and target address from the distribution array.
            uint256 bps = shares[i].bps;
            address target = shares[i].target;
            // safely increment i uncheck overflow
            unchecked {
                ++i;
            }

            if (bps == 0) continue;
            // Calculate and register the allocation for each distribution.
            uint256 registeredAmount = amount.perOf(bps);
            target.transfer(registeredAmount, currency);
            accTotal += registeredAmount;
            accBps += bps;
        }

        // Ensure the total base points do not exceed the maximum allowed (100%).
        if (accBps > C.BPS_MAX)
            revert NoDeal("Invalid split base points overflow.");
        return amount - accTotal; // Return the remaining unallocated amount.
    }

    /// @notice Modifier to check if the distributor is active and not blocked.
    /// @param distributor The distributor address to check.
    modifier onlyActiveDistributor(address distributor) {
        if (!_checkActiveDistributor(distributor))
            revert InvalidInactiveDistributor();
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

    /// @inheritdoc IRightsManager
    /// @notice Checks if the content is eligible for distribution by the content holder's custodial.
    /// @dev This function verifies whether the specified content can be distributed,
    /// based on the status of the custodial rights and the content's activation state in related contracts.
    /// @param contentId The ID of the content to check for distribution eligibility.
    /// @param contentHolder The address of the content holder whose custodial rights are being checked.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(
        uint256 contentId,
        address contentHolder
    ) public returns (bool) {
        // Perform checks to ensure the content/distributor has not been blocked.
        // Check if the content's custodial is active in the Syndication contract
        // and if the content is active in the Referendum contract.
        return
            _checkActiveDistributor(getCustody(contentHolder)) &&
            _checkActiveContent(contentId);
    }

    /// @inheritdoc IRightsCustodialGranter
    /// @notice Grants custodial rights over the content held by a holder to a distributor.
    /// @dev This function assigns custodial rights for the content held by a specific
    /// account to a designated distributor.
    /// @param distributor The address of the distributor who will receive custodial rights.
    function grantCustody(
        address distributor
    ) external onlyActiveDistributor(distributor) {
        // if it's first custody assignment prev = address(0)
        address contentHolder = _msgSender();
        address prevCustody = getCustody(contentHolder);
        _grantCustody(distributor, contentHolder);
        emit CustodialGranted(prevCustody, distributor, contentHolder);
    }

    /// @inheritdoc IRightsPolicyControllerAuthorizer
    /// @notice Delegates rights to a policy contract for content held by the holder.
    /// @param policy The address of the policy contract to which rights are being delegated.
    function authorizePolicy(
        address policy
    ) external onlyPolicyContract(policy) {
        address holder = _msgSender();
        _authorizePolicy(policy, holder);
        emit RightsGranted(policy, holder);
    }

    /// @inheritdoc IRightsPolicyControllerRevoker
    /// @notice Revokes the delegation of rights to a policy contract.
    /// @param policy The address of the policy contract whose rights delegation is being revoked.
    function revokePolicy(address policy) external onlyPolicyContract(policy) {
        address holder = _msgSender();
        _revokePolicy(policy, holder);
        emit RightsRevoked(policy, holder);
    }

    /// @inheritdoc IRightsDealBroker
    /// @notice Creates a new deal between the account and the content holder, returning a unique deal identifier.
    /// @dev This function handles the creation of a new deal by negotiating terms, calculating fees,
    /// and generating a unique proof of the deal.
    /// @param total The total amount involved in the deal.
    /// @param currency The address of the ERC20 token (or native currency) being used in the deal.
    /// @param holder The address of the content holder whose content is being accessed.
    /// @param account The address of the account proposing the deal.
    /// @return bytes32 A unique identifier (dealProof) representing the created deal.
    function createDeal(
        uint256 total,
        address currency,
        address holder,
        address account
    ) external returns (bytes32) {
        address custodial = getCustody(holder);
        uint256 custodials = getCustodyCount(custodial);
        IDistributor distributor = IDistributor(custodial);
        // !IMPORTANT if distributor or trasury does not support the currency, will revert..
        // the max bps integrity is warrantied by treasure fees
        uint256 treasury = total.perOf(getFees(currency)); // bps
        uint256 accepted = distributor.negotiate(total, currency, custodials);
        uint256 deductions = treasury + accepted;
        if (deductions > total) revert NoDeal("The fees are too high.");
        // create a new deal to interact with register policy
        T.Deal memory deal = T.Deal(
            block.timestamp, // the deal creation date
            total, // the transaction total amount
            accepted, // distribution fees
            total - deductions, // the remaining amount after fees
            currency, // the currency used in transaction
            account, // the account related to deal
            holder, // the content rights holder
            custodial, // the distributor address
            true // the deal status, true for active, false for closed.
        );

        // keccak256(abi.encodePacked(deal..))
        return _createProof(deal);
    }

    /// @inheritdoc IRightsDealBroker
    /// @notice Close the deal by confirming the terms and executing the necessary transactions.
    /// @dev This function finalizes the deal created by the account. It validates the proposal,
    /// executes the agreed terms, and allocates payments.
    /// @param dealProof The unique identifier of the created deal.
    /// @param policyAddress The address of the policy contract that governs the terms.
    /// @param data Additional data required to close the deal.
    function closeDeal(
        bytes32 dealProof,
        address policyAddress,
        bytes calldata data
    )
        external
        payable
        nonReentrant
        onlyValidProof(dealProof)
        onlyPolicyContract(policyAddress)
    {
        T.Deal memory deal = getDeal(dealProof);
        // check if policy is authorized by holder to operate over content
        if (!isPolicyAuthorized(policyAddress, deal.holder))
            revert InvalidNotRightsDelegated(policyAddress, deal.holder);

        IPolicy policy = IPolicy(policyAddress);
        (bool success, string memory reason) = policy.exec(deal, data);
        if (!success) revert NoDeal(reason);

        // transfer amounts to contract and allocate shares.
        // if currency is not native, allowance is checked..
        _msgSender().safeDeposit(deal.total, deal.currency);
        T.Shares[] memory shares = policy.shares(); // royalties distribution..
        uint256 remaining = _allocate(deal.amount, deal.currency, shares);

        // register split distribution in ledger..
        deal.holder.transfer(remaining, deal.currency);
        deal.custodial.transfer(deal.fees, deal.currency);

        _closeDeal(dealProof); // inactivate the deal after success..
        _registerPolicy(deal.account, policyAddress);
        emit AccessGranted(deal.account, dealProof, policyAddress);
    }
}
