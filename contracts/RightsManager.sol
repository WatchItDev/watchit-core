// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity 0.8.26;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { LedgerUpgradeable } from "contracts/base/upgradeable/LedgerUpgradeable.sol";
import { FeesManagerUpgradeable } from "contracts/base/upgradeable/FeesManagerUpgradeable.sol";
import { TreasurerUpgradeable } from "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import { CurrencyManagerUpgradeable } from "contracts/base/upgradeable/CurrencyManagerUpgradeable.sol";
import { GovernableUpgradeable } from "contracts/base/upgradeable/GovernableUpgradeable.sol";

import { RightsManagerBrokerUpgradeable } from "contracts/base/upgradeable/extensions/RightsManagerBrokerUpgradeable.sol";
import { RightsManagerContentAccessUpgradeable } from "contracts/base/upgradeable/extensions/RightsManagerContentAccessUpgradeable.sol";
import { RightsManagerCustodialUpgradeable } from "contracts/base/upgradeable/extensions/RightsManagerCustodialUpgradeable.sol";
import { RightsManagerPolicyControllerUpgradeable } from "contracts/base/upgradeable/extensions/RightsManagerPolicyControllerUpgradeable.sol";

import { IPolicy } from "contracts/interfaces/IPolicy.sol";
import { ISyndicatableVerifiable } from "contracts/interfaces/ISyndicatableVerifiable.sol";
import { IReferendumVerifiable } from "contracts/interfaces/IReferendumVerifiable.sol";
import { IPolicyAuditorVerifiable } from "contracts/interfaces/IPolicyAuditorVerifiable.sol";
import { IRightsManagerVerifiable } from "contracts/interfaces/IRightsManagerVerifiable.sol";
import { IBalanceVerifiable } from "contracts/interfaces/IBalanceVerifiable.sol";
import { IBalanceWithdrawable } from "contracts/interfaces/IBalanceWithdrawable.sol";
import { IDisburser } from "contracts/interfaces/IDisburser.sol";
import { IDistributor } from "contracts/interfaces/IDistributor.sol";

import { TreasuryHelper } from "contracts/libraries/TreasuryHelper.sol";
import { FeesHelper } from "contracts/libraries/FeesHelper.sol";
import { C } from "contracts/libraries/Constants.sol";
import { T } from "contracts/libraries/Types.sol";

/// @title Rights Manager
/// @notice This contract manages digital rights, allowing content holders to set prices, rent content, etc.
/// @dev This contract uses the UUPS upgradeable pattern and is initialized using the `initialize` function.
contract RightsManager is
    Initializable,
    UUPSUpgradeable,
    LedgerUpgradeable,
    GovernableUpgradeable,
    TreasurerUpgradeable,
    FeesManagerUpgradeable,
    ReentrancyGuardUpgradeable,
    CurrencyManagerUpgradeable,
    RightsManagerBrokerUpgradeable,
    RightsManagerCustodialUpgradeable,
    RightsManagerContentAccessUpgradeable,
    RightsManagerPolicyControllerUpgradeable,
    IRightsManagerVerifiable,
    IBalanceWithdrawable,
    IBalanceVerifiable,
    IDisburser
{
    using TreasuryHelper for address;
    using FeesHelper for uint256;

    /// KIM: any initialization here is ephimeral and not included in bytecode..
    /// so the code within a logic contract’s constructor or global declaration
    /// will never be executed in the context of the proxy’s state
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#the-constructor-caveat
    IPolicyAuditorVerifiable public audit;
    ISyndicatableVerifiable public syndication;
    IReferendumVerifiable public referendum;

    /// @notice Emitted when distribution custodial rights are granted to a distributor.
    /// @param prevCustody The previous distributor custodial address.
    /// @param newCustody The new distributor custodial address.
    /// @param rightsHolder The content rights holder.
    event CustodialGranted(address indexed prevCustody, address indexed newCustody, address indexed rightsHolder);

    /// @notice Emitted when fees are disbursed to the treasury.
    /// @param treasury The address receiving the disbursed fees.
    /// @param amount The amount of fees being disbursed.
    /// @param currency The currency used for the disbursement.
    event FeesDisbursed(address indexed treasury, uint256 amount, address currency);

    /// @notice Emitted when access rights are granted to an account based on a policy.
    /// @param account The address of the account granted access.
    /// @param proof A unique identifier for the agreement or transaction.
    /// @param policy The policy contract address governing the access.
    event AccessGranted(address indexed account, bytes32 indexed proof, address indexed policy);

    /// @notice Emitted when rights are granted to a policy for content.
    /// @param policy The policy contract address granted rights.
    /// @param holder The address of the content rights holder.
    event RightsGranted(address indexed policy, address holder);
    /// @notice Emitted when rights are revoked from a policy for content.
    /// @param policy The policy contract address whose rights are being revoked.
    /// @param holder The address of the content rights holder.
    event RightsRevoked(address indexed policy, address holder);
    /// @dev Error thrown when attempting to operate on a policy that has not
    /// been delegated rights for the specified content.
    /// @param policy The address of the policy contract attempting to access rights.
    /// @param holder The content rights holder.
    error InvalidNotRightsDelegated(address policy, address holder);
    error InvalidNotAuditedPolicy(address policy);
    error InvalidPolicySetup(string reason);
    /// @dev Error that is thrown when a content hash is already registered.
    error InvalidInactiveDistributor();
    /// @dev Error thrown when a proposed agreement fails to execute.
    /// @param reason A string providing the reason for the failure.
    error NoAgreement(string reason);
    /// @dev Error thrown when the fund withdrawal fails.
    error NoFundsToWithdraw(string);

    /// @notice Modifier to check if the distributor is active and not blocked.
    /// @param distributor The distributor address to check.
    modifier onlyActiveDistributor(address distributor) {
        if (distributor == address(0) || !_checkActiveDistributor(distributor)) revert InvalidInactiveDistributor();
        _;
    }

    /// @dev Modifier to ensure that only audited policies can perform certain actions.
    /// @param policy The address of the policy contract to check for audit status.
    modifier onlyAuditedPolicy(address policy) {
        if (policy == address(0) || !audit.isAudited(policy)) revert InvalidNotAuditedPolicy(policy);
        _;
    }

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the necessary dependencies.
    /// @param treasury The address of the treasury contract to manage funds.
    /// @param syndication_ The address of the syndication contract, which verifies distributor agreements and manages syndication logic.
    /// @param referendum_ The address of the referendum contract, which handles governance voting on decisions.
    /// @param audit_ The address of the audit contract, which verifies policies audit.
    /// @dev This function can only be called once during the contract's deployment and sets up core components including the Ledger, Fees, and Treasurer.
    function initialize(
        address treasury,
        address syndication_,
        address referendum_,
        address audit_
    ) public initializer {
        __Ledger_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __CurrencyManager_init();
        __Governable_init(_msgSender());
        __Treasurer_init(treasury);

        syndication = ISyndicatableVerifiable(syndication_);
        referendum = IReferendumVerifiable(referendum_);
        audit = IPolicyAuditorVerifiable(audit_);
    }

    /// @notice Returns the contract's balance for the specified currency.
    /// @param currency The address of the token to check the balance of (address(0) for native currency).
    /// @return The balance of the contract in the specified currency.
    function getBalance(address currency) external view returns (uint256) {
        return address(this).balanceOf(currency);
    }

    /// @notice Withdraws tokens from the contract to a specified recipient's address.
    /// @dev This function withdraws funds from the caller's balance (checked via _msgSender()) and transfers them to the recipient.
    /// @param recipient The address that will receive the withdrawn tokens.
    /// @param amount The amount of tokens to withdraw.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function withdraw(
        address recipient,
        uint256 amount,
        address currency
    ) external nonReentrant onlyValidCurrency(currency) {
        if (getLedgerBalance(_msgSender(), currency) < amount)
            revert NoFundsToWithdraw("Insuficient funds to withdraw.");
        _subLedgerEntry(_msgSender(), amount, currency);
        recipient.transfer(amount, currency);
        // TODO emit event
    }

    /// @notice Sets a new treasury fee for a specific currency.
    /// @param newTreasuryFee The new fee amount to be set.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function setFees(
        uint256 newTreasuryFee,
        address currency
    ) external onlyGov onlyValidCurrency(currency) onlyBasePointsAllowed(newTreasuryFee) {
        _setFees(newTreasuryFee, currency);
        _addCurrency(currency);
        // TODO emit events
    }

    /// @notice Sets the address of the treasury.
    /// @param newTreasuryAddress The new treasury address to be set.
    /// @dev Only callable by the governance role.
    function setTreasuryAddress(address newTreasuryAddress) external onlyGov {
        _setTreasuryAddress(newTreasuryAddress);
        // TODO emit event
    }

    /// @notice Disburses funds from the contract to a specified address.
    /// @param amount The amount of currencies to disburse.
    /// @param currency The address of the ERC20 token to disburse tokens.
    /// @dev This function can only be called by governance or an authorized entity.
    function disburse(uint256 amount, address currency) external onlyGov onlyValidCurrency(currency) {
        address treasury = getTreasuryAddress();
        treasury.transfer(amount, currency);
        emit FeesDisbursed(treasury, amount, currency);
    }

    /// @notice Grants custodial rights over the content held by a holder to a distributor.
    /// @dev This function assigns custodial rights for the content held by a specific
    /// account to a designated distributor.
    /// @param distributor The address of the distributor who will receive custodial rights.
    function grantCustody(address distributor) external onlyActiveDistributor(distributor) {
        // if it's first custody assignment prev = address(0)
        address contentHolder = _msgSender();
        address prevCustody = getCustody(contentHolder);
        _grantCustody(distributor, contentHolder);
        emit CustodialGranted(prevCustody, distributor, contentHolder);
    }

    /// @notice Initializes and authorizes a policy contract for content held by the holder.
    /// @param policy The address of the policy contract to be initialized and authorized.
    /// @param data Additional data required for initializing the policy.
    function setupPolicy(address policy, bytes calldata data) external onlyAuditedPolicy(policy) {
        T.Setup memory setupData = T.Setup(_msgSender(), data);
        try IPolicy(policy).setup(setupData) {
            _authorizePolicy(policy, setupData.holder);
            emit RightsGranted(policy, setupData.holder);
        } catch Error(string memory reason) {
            revert InvalidPolicySetup(reason);
        }
    }

    /// @notice Revokes the delegation of rights to a policy contract.
    /// @param policy The address of the policy contract whose rights delegation is being revoked.
    function revokePolicy(address policy) external {
        address holder = _msgSender();
        _revokePolicy(policy, holder);
        emit RightsRevoked(policy, holder);
    }

    /// @notice Calculates the fees for the treasury based on the provided total amount.
    /// @param total The total amount involved in the transaction.
    /// @param currency The address of the ERC20 token (or native currency) being used in the transaction.
    /// @return treasury The calculated fee for the treasury.
    function calcFees(uint256 total, address currency) public view onlySupportedCurrency(currency) returns (uint256) {
        // !IMPORTANT if trasury does not support the currency, will revert..
        // the max bps integrity is warrantied by treasure fees
        return total.perOf(getFees(currency)); // bps
    }

    /// @notice Checks if the content is eligible for distribution by the content holder's custodial.
    /// @dev This function verifies whether the specified content can be distributed,
    /// based on the status of the custodial rights and the content's activation state in related contracts.
    /// @param contentId The ID of the content to check for distribution eligibility.
    /// @param contentHolder The address of the content holder whose custodial rights are being checked.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(uint256 contentId, address contentHolder) public returns (bool) {
        // Perform checks to ensure the content/distributor has not been blocked.
        // Check if the content's custodial is active in the Syndication contract
        // and if the content is active in the Referendum contract.
        return _checkActiveDistributor(getCustody(contentHolder)) && _checkActiveContent(contentId);
    }

    /// @notice Creates a new agreement between the account and the content holder, returning a unique agreement identifier.
    /// @dev This function handles the creation of a new agreement by negotiating terms, calculating fees,
    /// and generating a unique proof of the agreement.
    /// @param total The total amount involved in the agreement.
    /// @param currency The address of the ERC20 token (or native currency) being used in the agreement.
    /// @param holder The address of the content holder whose content is being accessed.
    /// @param account The address of the account proposing the agreement.
    /// @param payload Additional data required to execute the agreement.
    /// @return bytes32 A unique identifier (agreementProof) representing the created agreement.
    function createAgreement(
        uint256 total,
        address currency,
        address holder,
        address account,
        bytes calldata payload
    ) public onlySupportedCurrency(currency) returns (bytes32) {
        uint256 deductions = calcFees(total, currency);
        if (deductions > total) revert NoAgreement("The fees are too high.");
        uint256 available = total - deductions; // the total after fees
        // one agreement it's unique and cannot be reconstructed..
        // create a new immutable agreement to interact with register policy
        T.Agreement memory agreement = T.Agreement(
            block.timestamp, // the agreement creation time
            total, // the transaction total amount
            available, // the remaining amount after fees
            currency, // the currency used in transaction
            account, // the account related to agreement
            holder, // the content rights holder
            payload, // any additional data needed during agreement execution
            true // the agreement status, true for active, false for closed.
        );

        // keccak256(abi.encodePacked(....))
        // TODO emit event
        return _createProof(agreement);
    }

    /// @notice Finalizes the agreement by registering the agreed-upon policy, effectively closing the agreement.
    /// @dev This function verifies the policy's authorization, executes the agreement, processes financial transactions,
    ///      and registers the policy in the system, representing the formal closure of the agreement.
    /// @param proof The unique identifier of the agreement to be enforced.
    /// @param policyAddress The address of the policy contract managing the agreement.
    function registerPolicy(
        bytes32 proof,
        address policyAddress
    ) public payable onlyValidProof(proof) onlyAuditedPolicy(policyAddress) {
        T.Agreement memory agreement = getAgreement(proof);
        // check if policy is authorized by holder to operate over content
        if (!isPolicyAuthorized(policyAddress, agreement.holder))
            revert InvalidNotRightsDelegated(policyAddress, agreement.holder);

        // the remaining is registered to policy contract to operate distribution..
        _msgSender().safeDeposit(agreement.total, agreement.currency);
        // validate policy execution..
        try IPolicy(policyAddress).exec(agreement) {
            _closeAgreement(proof); // inactivate the agreement after success..
            _sumLedgerEntry(policyAddress, agreement.available, agreement.currency);
            _registerPolicy(agreement.account, policyAddress);
            emit AccessGranted(agreement.account, proof, policyAddress);
        } catch Error(string memory reason) {
            // catch revert, require with a reason..
            revert NoAgreement(reason);
        }
    }

    /// @notice Executes the creation of an agreement and immediately registers the policy in a single transaction.
    /// @dev This function streamlines the process by creating the agreement and registering the policy in one step,
    ///      ensuring that the content access and policy execution are handled efficiently.
    /// @param total The total amount involved in the agreement.
    /// @param currency The address of the ERC20 token (or native currency) used in the transaction.
    /// @param holder The address of the content rights holder whose content is being accessed.
    /// @param account The address of the user or account proposing the agreement.
    /// @param policyAddress The address of the policy contract managing the agreement.
    /// @param data Additional data required to execute the policy.
    function flashAgreement(
        uint256 total,
        address currency,
        address holder,
        address account,
        address policyAddress,
        bytes calldata data
    ) public payable returns (bytes32) {
        bytes32 proof = createAgreement(total, currency, holder, account, data);
        registerPolicy(proof, policyAddress);
        return proof;
    }

    /// @notice Retrieves the first active policy for a specific account and content id in LIFO order.
    /// @param account The address of the account to evaluate.
    /// @param contentId The ID of the content to evaluate policies for.
    /// @return A tuple containing:
    /// - A boolean indicating whether an active policy was found (`true`) or not (`false`).
    /// - The address of the active policy if found, or `address(0)` if no active policy is found.
    function getActivePolicy(address account, uint256 contentId) public view returns (bool, address) {
        address[] memory policies = getPolicies(account);
        uint256 i = policies.length - 1;

        while (true) {
            bool comply = _verifyPolicy(account, contentId, policies[i]);
            if (comply) return (true, policies[i]);
            if (i == 0) break;
            unchecked {
                --i;
            }
        }

        // No active policy found
        return (false, address(0));
    }

    /// @dev Authorizes the upgrade of the contract.
    /// @notice Only the owner can authorize the upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /// @notice Checks if the given distributor is active and not blocked.
    /// @param distributor The address of the distributor to check.
    /// @return True if the distributor is active, false otherwise.
    function _checkActiveDistributor(address distributor) private returns (bool) {
        return syndication.isActive(distributor); // is active status in syndication
    }

    /// @notice Checks if the given content is active and not blocked.
    /// @param contentId The ID of the content to check.
    /// @return True if the content is active, false otherwise.
    function _checkActiveContent(uint256 contentId) private view returns (bool) {
        return referendum.isActive(contentId); // is active in referendum
    }
}
