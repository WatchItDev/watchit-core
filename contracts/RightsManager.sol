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
import "contracts/base/upgradeable/extensions/RightsManagerPolicyAuditorUpgradeable.sol";

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
    LedgerUpgradeable,
    GovernableUpgradeable,
    TreasurerUpgradeable,
    ReentrancyGuardUpgradeable,
    CurrencyManagerUpgradeable,
    RightsManagerBrokerUpgradeable,
    RightsManagerCustodialUpgradeable,
    RightsManagerContentAccessUpgradeable,
    RightsManagerPolicyAuditorUpgradeable,
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

    /// @notice Emitted when fees are disbursed to the treasury.
    /// @param treasury The address receiving the disbursed fees.
    /// @param amount The amount of fees being disbursed.
    /// @param currency The currency used for the disbursement.
    event FeesDisbursed(
        address indexed treasury,
        uint256 amount,
        address currency
    );

    /// @notice Emitted when access rights are granted to an account based on a policy.
    /// @param account The address of the account granted access.
    /// @param proof A unique identifier for the deal or transaction.
    /// @param policy The policy contract address governing the access.
    event AccessGranted(
        address indexed account,
        bytes32 indexed proof,
        address indexed policy
    );

    /// @notice Emitted when rights are granted to a policy for content.
    /// @param policy The policy contract address granted rights.
    /// @param holder The address of the content rights holder.
    event RightsGranted(address indexed policy, address holder);
    /// @notice Emitted when rights are revoked from a policy for content.
    /// @param policy The policy contract address whose rights are being revoked.
    /// @param holder The address of the content rights holder.
    event RightsRevoked(address indexed policy, address holder);
    event PolicyApproved(address indexed policy, address auditor);
    event PolicyRevoked(address indexed policy, address auditor);

    /// KIM: any initialization here is ephimeral and not included in bytecode..
    /// so the code within a logic contract’s constructor or global declaration
    /// will never be executed in the context of the proxy’s state
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#the-constructor-caveat
    IRegistrableVerifiable public syndication;
    IReferendumVerifiable public referendum;

    /// @dev Error thrown when attempting to operate on a policy that has not
    /// been delegated rights for the specified content.
    /// @param policy The address of the policy contract attempting to access rights.
    /// @param holder The content rights holder.
    error InvalidNotRightsDelegated(address policy, address holder);
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();
    /// @dev Error thrown when a deal fails to execute.
    /// @param reason A string providing the reason for the failure.
    error NoDeal(string reason);
    /// @dev Error thrown when the fund withdrawal fails.
    error NoFundsToWithdraw(string);

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
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __CurrencyManager_init();
        __Governable_init(_msgSender());

        // initialize dependencies for RM
        IRepository repo = IRepository(repository);
        address wvc = repo.getContract(T.ContractTypes.WVC);
        address treasuryAddress = repo.getContract(T.ContractTypes.TRE);
        address syndicationAddress = repo.getContract(T.ContractTypes.SYN);
        address referendumAddress = repo.getContract(T.ContractTypes.REF);

        syndication = IRegistrableVerifiable(syndicationAddress);
        referendum = IReferendumVerifiable(referendumAddress);
        
        __Fees_init(initialFee, wvc);
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

    /// @notice Modifier to check if the distributor is active and not blocked.
    /// @param distributor The distributor address to check.
    modifier onlyActiveDistributor(address distributor) {
        if (distributor == address(0) || !_checkActiveDistributor(distributor))
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

    /// @inheritdoc IBalanceManager
    /// @notice Returns the contract's balance for the specified currency.
    /// @param currency The address of the token to check the balance of (address(0) for native currency).
    /// @return The balance of the contract in the specified currency.
    function getBalance(address currency) external view returns (uint256) {
        return address(this).balanceOf(currency);
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

    /// @inheritdoc IBalanceManagerWithdrawable
    /// @notice Withdraws tokens from the contract to a specified recipient's address.
    /// @dev This implementation enforce th withdraw of token only for distributors by registered manager.
    /// @param recipient The address that will receive the withdrawn tokens.
    /// @param amount The amount of tokens to withdraw.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function withdraw(
        address recipient,
        uint256 amount,
        address currency
    ) external onlyValidCurrency(currency) onlyActiveDistributor(recipient) {
        IDistributor distributor = IDistributor(recipient);
        if (getLedgerBalance(recipient, currency) < amount)
            revert NoFundsToWithdraw("Insuficient funds to withdraw.");

        if (_msgSender() != distributor.getManager())
            revert NoFundsToWithdraw(
                "Only manager is allowed to withdraw funds."
            );

        recipient.transfer(amount, currency);
        _subLedgerEntry(recipient, amount, currency);
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

    /// @inheritdoc IRightsPolicyAuditor
    /// @notice Approves the audit of a given policy.
    /// @param policy The address of the policy to be audited.
    function approveAudit(
        address policy
    ) external onlyPolicyContract(policy) onlyMod {
        address auditor = _msgSender();
        _approveAudit(policy, auditor);
        emit PolicyApproved(policy, auditor);
    }

    /// @inheritdoc IRightsPolicyAuditor
    /// @notice Revokes the audit of a given policy.
    /// @param policy The address of the policy whose audit is to be revoked.
    function revokeAudit(
        address policy
    ) external onlyPolicyContract(policy) onlyMod {
        address auditor = _msgSender();
        _revokeAudit(policy, auditor);
        emit PolicyRevoked(policy, auditor);
    }

    /// @inheritdoc IRightsPolicyController
    /// @notice Delegates rights to a policy contract for content held by the holder.
    /// @param policy The address of the policy contract to which rights are being delegated.
    function authorizePolicy(
        address policy
    ) external onlyAuditedPolicy(policy) {
        address holder = _msgSender();
        _authorizePolicy(policy, holder);
        emit RightsGranted(policy, holder);
    }

    /// @inheritdoc IRightsPolicyController
    /// @notice Revokes the delegation of rights to a policy contract.
    /// @param policy The address of the policy contract whose rights delegation is being revoked.
    function revokePolicy(address policy) external onlyAuditedPolicy(policy) {
        address holder = _msgSender();
        _revokePolicy(policy, holder);
        emit RightsRevoked(policy, holder);
    }

    /// @inheritdoc IRightsManager
    /// @notice Calculates the fees for both the treasury and the distributor based on the provided total amount.
    /// @dev This function handles the fee calculation for the treasury and negotiates the distribution fees with the distributor.
    ///      If the distributor or treasury does not support the specified currency, the function will revert.
    /// @param total The total amount involved in the transaction.
    /// @param currency The address of the ERC20 token (or native currency) being used in the transaction.
    /// @param custodial The address of the distributor to negotiate fees.
    /// @return tFees The calculated fee for the treasury.
    /// @return dFees The calculated fee for the distributor.
    function calcFees(
        uint256 total,
        address currency,
        address custodial
    )
        public
        onlySupportedCurrency(currency)
        onlyActiveDistributor(custodial)
        returns (uint256 tFees, uint256 dFees)
    {
        uint256 custodials = getCustodyCount(custodial);
        IDistributor distributor = IDistributor(custodial);
        // !IMPORTANT if distributor or trasury does not support the currency, will revert..
        // the max bps integrity is warrantied by treasure fees
        tFees = total.perOf(getFees(currency)); // bps
        dFees = distributor.negotiate(total, currency, custodials);
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
    ) external onlySupportedCurrency(currency) returns (bytes32) {
        address custodial = getCustody(holder);
        // calculate the fees involved in the deal based on distributor fees and treasury
        (uint256 tFees, uint256 dFees) = calcFees(total, currency, custodial);

        uint256 deductions = tFees + dFees; // the total of fees involved in the deal
        uint256 available = total - deductions; // the total after fees involved in the deal
        if (deductions > total) revert NoDeal("The fees are too high.");

        // create a new deal to interact with register policy
        T.Deal memory deal = T.Deal(
            block.timestamp, // the deal creation date
            total, // the transaction total amount
            dFees, // distribution fees
            available, // the remaining amount after fees
            currency, // the currency used in transaction
            account, // the account related to deal
            holder, // the content rights holder
            custodial, // the distributor address
            true // the deal status, true for active, false for closed.
        );

        // keccak256(abi.encodePacked(deal..))
        return _createProof(deal);
    }

    /// @inheritdoc IRightsManager
    /// @notice Finalizes the deal by registering the agreed-upon policy, effectively closing the deal.
    /// @dev This function verifies the policy's authorization, executes the deal, processes financial transactions,
    ///      and registers the policy in the system, representing the formal closure of the deal.
    /// @param dealProof The unique identifier of the deal to be enforced.
    /// @param policyAddress The address of the policy contract managing the deal.
    /// @param data Additional data required to execute the deal.
    function registerPolicy(
        bytes32 dealProof,
        address policyAddress,
        bytes calldata data
    )
        external
        payable
        nonReentrant
        onlyValidProof(dealProof)
        onlyAuditedPolicy(policyAddress)
    {
        T.Deal memory deal = getDeal(dealProof);
        // check if policy is authorized by holder to operate over content
        if (!isPolicyAuthorized(policyAddress, deal.holder))
            revert InvalidNotRightsDelegated(policyAddress, deal.holder);
        // the remaining is sent to policy contract to operate distribution..
        // transfer amounts to contract and allocate shares.
        _msgSender().safeDeposit(deal.total, deal.currency);
        policyAddress.transfer(deal.available, deal.currency);

        // validate policy execution..
        IPolicy policy = IPolicy(policyAddress);
        (bool success, string memory reason) = policy.exec(deal, data);
        if (!success) revert NoDeal(reason);

        _closeDeal(dealProof); // inactivate the deal after success..
        _sumLedgerEntry(deal.custodial, deal.fees, deal.currency);
        _registerPolicy(deal.account, policyAddress);
        emit AccessGranted(deal.account, dealProof, policyAddress);
    }

    /// @inheritdoc IRightsAccessController
    /// @notice Retrieves the first active policy for a specific account and content id in LIFO order.
    /// @param account The address of the account to evaluate.
    /// @param contentId The ID of the content to evaluate policies for.
    /// @return A tuple containing:
    /// - A boolean indicating whether an active policy was found (`true`) or not (`false`).
    /// - The address of the active policy if found, or `address(0)` if no active policy is found.
    function getActivePolicy(
        address account,
        uint256 contentId
    ) public view returns (bool, address) {
        address[] memory policies = getPolicies(account);
        uint256 i = policies.length - 1;

        while (true) {
            // LIFO precedence order: last registered policy is evaluated first.
            // The first complying policy is returned.
            // We need to check if the policy is still valid audited.
            if (isPolicyAudited(policies[i])) {
                bool comply = _verifyPolicy(account, contentId, policies[i]);
                if (comply) return (true, policies[i]);
            }

            if (i == 0) break;
            unchecked {
                --i;
            }
        }

        // No active policy found
        return (false, address(0));
    }
}
