// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.26;

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { GovernableUpgradeable } from "contracts/base/upgradeable/GovernableUpgradeable.sol";
import { QuorumUpgradeable } from "contracts/base/upgradeable/QuorumUpgradeable.sol";
import { TreasurerUpgradeable } from "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import { LedgerUpgradeable } from "contracts/base/upgradeable/LedgerUpgradeable.sol";
import { FeesManagerUpgradeable } from "contracts/base/upgradeable/FeesManagerUpgradeable.sol";

import { ISyndicatablePenalizer } from "contracts/interfaces/ISyndicatablePenalizer.sol";
import { ISyndicatableRegistrable } from "contracts/interfaces/ISyndicatableRegistrable.sol";
import { ISyndicatableExpirable } from "contracts/interfaces/ISyndicatableExpirable.sol";
import { ISyndicatableEnroller } from "contracts/interfaces/ISyndicatableEnroller.sol";
import { ISyndicatableRevokable } from "contracts/interfaces/ISyndicatableRevokable.sol";
import { ISyndicatableVerifiable } from "contracts/interfaces/ISyndicatableVerifiable.sol";
import { IBalanceVerifiable } from "contracts/interfaces/IBalanceVerifiable.sol";
import { IDistributor } from "contracts/interfaces/IDistributor.sol";
import { IDisburser } from "contracts/interfaces/IDisburser.sol";

import { TreasuryHelper } from "contracts/libraries/TreasuryHelper.sol";
import { FeesHelper } from "contracts/libraries/FeesHelper.sol";
import { T } from "contracts/libraries/Types.sol";

/// @title Distributors Syndication contract.
/// @notice Use this contract to handle all distribution logic needed for creators and distributors.
/// @dev This contract uses the UUPS upgradeable pattern and AccessControl for role-based access control.
contract Syndication is
    Initializable,
    UUPSUpgradeable,
    LedgerUpgradeable,
    QuorumUpgradeable,
    TreasurerUpgradeable,
    GovernableUpgradeable,
    FeesManagerUpgradeable,
    ReentrancyGuardUpgradeable,
    ISyndicatableEnroller,
    ISyndicatablePenalizer,
    ISyndicatableRegistrable,
    ISyndicatableExpirable,
    ISyndicatableRevokable,
    ISyndicatableVerifiable,
    IBalanceVerifiable,
    IDisburser
{
    using FeesHelper for uint256;
    using ERC165Checker for address;
    using TreasuryHelper for address;

    uint256 public enrollmentPeriod; // Period for enrollment
    uint256 public enrollmentsCount; // Count of enrollments
    mapping(address => uint256) public penaltyRates; // Penalty rates for distributors
    mapping(address => uint256) public enrollmentTime; // Timestamp for enrollment periods

    bytes4 private constant INTERFACE_ID_IDISTRIBUTOR = type(IDistributor).interfaceId;

    /// @notice Event emitted when a distributor is registered
    /// @param distributor The address of the registered distributor
    event Registered(address indexed distributor);
    /// @notice Event emitted when a distributor is approved
    /// @param distributor The address of the approved distributor
    event Approved(address indexed distributor);
    /// @notice Event emitted when a distributor resigns
    /// @param distributor The address of the resigned distributor
    event Resigned(address indexed distributor);
    /// @notice Event emitted when a distributor is revoked
    /// @param distributor The address of the revoked distributor
    event Revoked(address indexed distributor);
    /// @notice Event emitted when fees are disbursed to the treasury
    /// @param treasury The address of the treasury receiving the fees
    /// @param amount The amount disbursed
    /// @param currency The disbursed currency
    event FeesDisbursed(address indexed treasury, uint256 amount, address currency);

    /// @notice Error thrown when a distributor contract is invalid
    error InvalidDistributorContract(address invalid);

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// @notice This constructor prevents the implementation contract from being initialized.
    /// @dev See https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given multimedia coin (MMC), treasury, enrollment fee, and initial penalty rate.
    /// @param treasury The address of the treasury contract, which manages fund handling and storage.
    /// @dev This function can only be called once during contract deployment. It sets up the contract's core components like the quorum,
    /// ledger, reentrancy protection, and upgrade mechanisms. It also defines the initial flat fees and penalty rates.
    function initialize(address treasury) public initializer {
        __Quorum_init();
        __Ledger_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __Governable_init(_msgSender());
        __Treasurer_init(treasury);
        // 6 months initially..
        enrollmentPeriod = 180 days;
    }

    /// @notice Modifier to ensure that the given distributor contract supports the IDistributor interface.
    /// @param distributor The distributor contract address.
    modifier onlyDistributorContract(address distributor) {
        if (!distributor.supportsInterface(INTERFACE_ID_IDISTRIBUTOR)) revert InvalidDistributorContract(distributor);
        _;
    }

    /// @notice Function to set the penalty rate for quitting enrollment.
    /// @param newPenaltyRate The new penalty rate to be set. It should be a value representin base points (bps).
    /// @param currency The currency to set penalty rate.
    /// @dev The penalty rate is represented as base points (expressed as a uint256)
    /// That will be applied to the enrollment fee when a distributor quits.
    function setPenaltyRate(
        uint256 newPenaltyRate,
        address currency
    ) external onlyGov onlyBasePointsAllowed(newPenaltyRate) {
        penaltyRates[currency] = newPenaltyRate;
    }

    /// @notice Sets a new treasury fee for a specific token.
    /// @param newTreasuryFee The new treasury fee to be set.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function setFees(uint256 newTreasuryFee, address currency) external override onlyGov {
        _setFees(newTreasuryFee, currency);
    }

    /// @notice Sets the address of the treasury.
    /// @param newTreasuryAddress The new treasury address to be set.
    /// @dev Only callable by the governance role.
    function setTreasuryAddress(address newTreasuryAddress) external onlyGov {
        _setTreasuryAddress(newTreasuryAddress);
    }

    /// @inheritdoc ISyndicatableExpirable
    /// @notice Sets a new expiration period for an enrollment or registration.
    /// @param newPeriod The new expiration period, in seconds.
    function setExpirationPeriod(uint256 newPeriod) external onlyGov {
        enrollmentPeriod = newPeriod;
    }

    /// @inheritdoc IBalanceVerifiable
    /// @notice Returns the contract's balance for the specified currency.
    /// @param currency The address of the token to check the balance of (address(0) for native currency).
    /// @return The balance of the contract in the specified currency.
    function getBalance(address currency) external view returns (uint256) {
        return address(this).balanceOf(currency);
    }

    /// @inheritdoc IDisburser
    /// @notice Disburses funds from the contract to a specified address.
    /// @param amount The amount of coins to disburse.
    /// @param currency The address of the ERC20 token or address(0) for native.
    /// @dev This function can only be called by governance or an authorized entity.
    function disburse(uint256 amount, address currency) external onlyGov {
        address treasury = getTreasuryAddress();
        treasury.transfer(amount, currency); // sent..
        emit FeesDisbursed(treasury, amount, currency);
    }

    /// @inheritdoc ISyndicatableRegistrable
    /// @notice Registers a distributor by sending a payment to the contract.
    /// @param distributor The address of the distributor to register.
    /// @param currency The currency used to pay enrollment.
    function register(
        address distributor,
        address currency
    ) external onlyDistributorContract(distributor) onlySupportedCurrency(currency) {
        uint256 fees = getFees(currency);
        // only manager can pay for enrollment..
        address manager = IDistributor(distributor).getManager();
        uint256 total = manager.safeDeposit(fees, currency);
        // set the distributor active enrollment period..
        // after this time the distributor is considered inactive...
        enrollmentTime[distributor] = block.timestamp + enrollmentPeriod;
        // Persist the enrollment payment in case the distributor quits before approval
        _setLedgerEntry(manager, total, currency);
        // Set the distributor as pending approval
        _register(uint160(distributor));
        emit Registered(distributor);
    }

    /// @inheritdoc ISyndicatableRevokable
    /// @notice Allows a distributor to quit and receive a penalized refund.
    /// @param distributor The address of the distributor to quit.
    /// @param currency The currency used to pay enrollment.
    /// @dev The function reverts if the distributor has not enrolled or if the refund fails.
    function quit(
        address distributor,
        address currency
    ) external nonReentrant onlyDistributorContract(distributor) onlySupportedCurrency(currency) {
        address manager = _msgSender(); // the sender is expected to be the manager..
        uint256 ledgerAmount = getLedgerBalance(manager, currency);

        // eg: (100 * bps) / BPS_MAX
        uint256 currencyPenalty = penaltyRates[currency];
        uint256 penal = ledgerAmount.perOf(currencyPenalty);
        uint256 res = ledgerAmount - penal;

        // reset ledger..
        _quit(uint160(distributor));
        _setLedgerEntry(manager, 0, currency);
        enrollmentTime[distributor] = 0;
        manager.transfer(res, currency);
        emit Resigned(distributor);
    }

    /// @inheritdoc ISyndicatableRevokable
    /// @notice Revokes the registration of a distributor.
    /// @param distributor The address of the distributor to revoke.
    function revoke(address distributor) external onlyGov onlyDistributorContract(distributor) {
        _revoke(uint160(distributor));
        enrollmentsCount--;
        // TODO auto set new distributor soritium demand based..
        emit Revoked(distributor);
    }

    /// @inheritdoc ISyndicatableRegistrable
    /// @notice Approves a distributor's registration.
    /// @param distributor The address of the distributor to approve.
    function approve(address distributor) external onlyGov onlyDistributorContract(distributor) {
        address manager = IDistributor(distributor).getManager();
        // reset ledger..
        _setLedgerEntry(manager, 0, address(0));
        _approve(uint160(distributor));
        enrollmentsCount++;
        emit Approved(distributor);
    }

    /// @notice Retrieves the penalty rate for quitting enrollment.
    /// @param currency The currency in which to query the penalty rate.
    /// @dev The penalty rate is stored in basis points (bps).
    function getPenaltyRate(address currency) public view returns (uint256) {
        return penaltyRates[currency];
    }

    /// @notice Retrieves the current expiration period for enrollments or registrations.
    /// @return The expiration period, in seconds.
    function getExpirationPeriod() public view returns (uint256) {
        return enrollmentPeriod;
    }

    /// @inheritdoc ISyndicatableEnroller
    /// @notice Retrieves the enrollment time for a distributor, taking into account the current block time and the expiration period.
    /// @param distributor The address of the distributor.
    /// @return The enrollment time in seconds.
    function getEnrollmentTime(address distributor) public view returns (uint256) {
        return enrollmentTime[distributor];
    }

    /// @inheritdoc ISyndicatableEnroller
    /// @notice Retrieves the total number of enrollments.
    /// @return The count of enrollments.
    function getEnrollmentCount() external view returns (uint256) {
        return enrollmentsCount;
    }

    /// @inheritdoc ISyndicatableVerifiable
    /// @notice Checks if the entity is active.
    /// @dev This function verifies the active status of the distributor.
    /// @param distributor The distributor's address to check.
    /// @return bool True if the distributor is active, false otherwise.
    function isActive(address distributor) public view onlyDistributorContract(distributor) returns (bool) {
        return _status(uint160(distributor)) == Status.Active && enrollmentTime[distributor] > block.timestamp;
    }

    /// @inheritdoc ISyndicatableVerifiable
    /// @notice Checks if the entity is waiting.
    /// @dev This function verifies the waiting status of the distributor.
    /// @param distributor The distributor's address to check.
    /// @return bool True if the distributor is waiting, false otherwise.
    function isWaiting(address distributor) public view onlyDistributorContract(distributor) returns (bool) {
        return _status(uint160(distributor)) == Status.Waiting;
    }

    /// @inheritdoc ISyndicatableVerifiable
    /// @notice Checks if the entity is blocked.
    /// @dev This function verifies the blocked status of the distributor.
    /// @param distributor The distributor's address to check.
    /// @return bool True if the distributor is blocked, false otherwise.
    function isBlocked(address distributor) public view onlyDistributorContract(distributor) returns (bool) {
        return _status(uint160(distributor)) == Status.Blocked;
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
