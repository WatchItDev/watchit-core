// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import "contracts/base/upgradeable/LedgerUpgradeable.sol";
import "contracts/base/upgradeable/FeesManagerUpgradeable.sol";

import "contracts/libraries/Types.sol";
import "contracts/interfaces/IRepository.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/ISyndicatable.sol";
import "contracts/libraries/TreasuryHelper.sol";
import "contracts/libraries/FeesHelper.sol";

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
    ISyndicatable
{
    using FeesHelper for uint256;
    using ERC165Checker for address;
    using TreasuryHelper for address;

    // 10% initial quitting penalization rate
    uint256 public penaltyRate;
    uint256 public enrollmentsCount;
    bytes4 private constant INTERFACE_ID_IDISTRIBUTOR =
        type(IDistributor).interfaceId;

    /// @notice Error to be thrown when a distributor contract is invalid.
    error InvalidPenaltyRate();
    error InvalidDistributorContract();
    error FailDuringEnrollment(string reason);
    error FailDuringQuit(string reason);

    /// @notice Event emitted when an entity is registered.
    /// @param distributor The address of the registered entity.
    event Registered(address indexed distributor);
    /// @notice Event emitted when an entity is approved.
    /// @param distributor The address of the approved entity.
    event Approved(address indexed distributor);
    /// @notice Event emitted when an entity resigns.
    /// @param distributor The address of the resigned entity.
    event Resigned(address indexed distributor);
    /// @notice Event emitted when an entity is revoked.
    /// @param distributor The address of the revoked entity.
    event Revoked(address indexed distributor);
    event FeesDisbursed(address indexed treasury, uint256 amount);

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// @notice This constructor prevents the implementation contract from being initialized.
    /// @dev See https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Modifier to ensure that the given distributor contract supports the IDistributor interface.
    /// @param distributor The distributor contract address.
    modifier onlyDistributorContract(address distributor) {
        if (!distributor.supportsInterface(INTERFACE_ID_IDISTRIBUTOR))
            revert InvalidDistributorContract();
        _;
    }

    /// @notice Initializes the contract with the given repository, enrollment fee, and initial penalty rate.
    /// @param repository The address of the repository contract.
    /// @param initialFee The initial flat fee for the treasury in native currency.
    /// @param initialPenaltyRateBps The initial penalty rate in basis points (bps).
    /// @dev This function is called only once during the contract deployment.
    function initialize(
        address repository,
        uint256 initialFee,
        uint256 initialPenaltyRateBps
    ) public initializer onlyBasePointsAllowed(initialPenaltyRateBps) {
        __Quorum_init();
        __Ledger_init();
        __Governable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        penaltyRate = initialPenaltyRateBps; // bps
        // Get the registered treasury contract from the repository
        IRepository repo = IRepository(repository);
        address treasury = repo.getContract(T.ContractTypes.TREASURY);

        // initially flat fees in native coin
        __Fees_init(initialFee, address(0));
        __Treasurer_init(treasury);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @inheritdoc ISyndicatable
    /// @notice Function to set the penalty rate for quitting enrollment.
    /// @param newPenaltyRate The new penalty rate to be set. It should be a value representin base points (bps).
    /// @dev The penalty rate is represented as base points (expressed as a uint256)
    /// That will be applied to the enrollment fee when a distributor quits.
    function setPenaltyRate(
        uint256 newPenaltyRate
    ) external onlyGov onlyBasePointsAllowed(newPenaltyRate) {
        if (newPenaltyRate == 0) revert InvalidPenaltyRate();
        penaltyRate = newPenaltyRate;
    }

    /// @inheritdoc IFeesManager
    /// @notice Sets a new treasury fee.
    /// @param newTreasuryFee The new treasury flat fee to be set.
    function setFees(uint256 newTreasuryFee) external onlyGov {
        _setFees(newTreasuryFee, address(0));
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
    /// @param amount The amount of coins to disburse.
    /// @dev This function can only be called by governance or an authorized entity.
    function disburse(uint256 amount) external onlyGov {
        address treasury = getTreasuryAddress();
        treasury.transfer(amount); // sent..
        emit FeesDisbursed(treasury, amount);
    }

    /// @inheritdoc IRegistrableVerifiable
    /// @notice Checks if the entity is active.
    /// @dev This function verifies the active status of the distributor.
    /// @param distributor The distributor's address to check.
    /// @return bool True if the distributor is active, false otherwise.
    function isActive(
        address distributor
    ) public view onlyDistributorContract(distributor) returns (bool) {
        return _status(uint160(distributor)) == Status.Active;
    }

    /// @inheritdoc IRegistrableVerifiable
    /// @notice Checks if the entity is waiting.
    /// @dev This function verifies the waiting status of the distributor.
    /// @param distributor The distributor's address to check.
    /// @return bool True if the distributor is waiting, false otherwise.
    function isWaiting(
        address distributor
    ) public view onlyDistributorContract(distributor) returns (bool) {
        return _status(uint160(distributor)) == Status.Waiting;
    }

    /// @inheritdoc IRegistrableVerifiable
    /// @notice Checks if the entity is blocked.
    /// @dev This function verifies the blocked status of the distributor.
    /// @param distributor The distributor's address to check.
    /// @return bool True if the distributor is blocked, false otherwise.
    function isBlocked(
        address distributor
    ) public view onlyDistributorContract(distributor) returns (bool) {
        return _status(uint160(distributor)) == Status.Blocked;
    }

    /// @inheritdoc IRegistrable
    /// @notice Registers a distributor by sending a payment to the contract.
    /// @param distributor The address of the distributor to register.
    function register(
        address distributor
    ) external payable onlyDistributorContract(distributor) {
        if (msg.value < getFees(address(0)))
            revert FailDuringEnrollment("Invalid fee amount");

        // the contract manager;
        address manager = IDistributor(distributor).getManager();
        // Persist the enrollment payment in case the distributor quits before approval
        _setLedgerEntry(manager, msg.value, address(0));
        // Set the distributor as pending approval
        _register(uint160(distributor));
        emit Registered(distributor);
    }

    /// @inheritdoc IRegistrableRevokable
    /// @notice Allows a distributor to quit and receive a penalized refund.
    /// @param distributor The address of the distributor to quit.
    /// @dev The function reverts if the distributor has not enrolled or if the refund fails.
    function quit(
        address distributor
    ) external nonReentrant onlyDistributorContract(distributor) {
        address manager = _msgSender(); // the sender is expected to be the manager..
        uint256 registeredAmount = getLedgerEntry(manager, address(0)); // Wei, etc..
        if (registeredAmount == 0)
            revert FailDuringQuit("Invalid distributor/manager enrollment.");

        // eg: (100 * bps) / BPS_MAX
        uint256 penal = registeredAmount.perOf(penaltyRate);
        uint256 res = registeredAmount - penal;

        // reset ledger..
        _setLedgerEntry(manager, 0, address(0));
        _quit(uint160(distributor));
        // rollback partial payment..
        manager.transfer(res);
        emit Resigned(distributor);
    }

    /// @inheritdoc IRegistrableRevokable
    /// @notice Revokes the registration of a distributor.
    /// @param distributor The address of the distributor to revoke.
    function revoke(
        address distributor
    ) external onlyGov onlyDistributorContract(distributor) {
        _revoke(uint160(distributor));
        emit Revoked(distributor);
    }

    /// @inheritdoc IRegistrable
    /// @notice Approves a distributor's registration.
    /// @param distributor The address of the distributor to approve.
    function approve(
        address distributor
    ) external onlyGov onlyDistributorContract(distributor) {
        address manager = IDistributor(distributor).getManager();
        // reset ledger..
        _setLedgerEntry(manager, 0, address(0));
        _approve(uint160(distributor));
        enrollmentsCount++;
        emit Approved(distributor);
    }

    /// @inheritdoc IFeesManager
    /// @notice Sets a new treasury fee for a specific token.
    /// @param newTreasuryFee The new treasury fee to be set.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function setFees(
        uint256 newTreasuryFee,
        address currency
    ) external override onlyGov {}

    /// @inheritdoc IDisburser
    /// @notice Disburses tokens from the contract to a specified address.
    /// @param amount The amount of tokens to disburse.
    /// @param currency The address of the ERC20 token to disburse tokens.
    /// @dev This function can only be called by governance or an authorized entity.
    function disburse(uint256 amount, address currency) external onlyGov {}
}
