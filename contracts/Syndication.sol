// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/base/upgradeable/TreasurerUpgradeable.sol";
import "contracts/base/upgradeable/TreasuryUpgradeable.sol";

import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/ISyndicatable.sol";
import "contracts/libraries/TreasuryHelper.sol";
import "contracts/libraries/Bytes32Helper.sol";

/// @title Content Syndication contract.
/// @notice Use this contract to handle all distribution logic needed for creators and distributors.
/// @dev This contract uses the UUPS upgradeable pattern and AccessControl for role-based access control.
contract Syndication is
    Initializable,
    ISyndicatable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    ReentrancyGuardUpgradeable,
    QuorumUpgradeable,
    TreasurerUpgradeable,
    TreasuryUpgradeable
{
    using Math for uint256;
    using ERC165Checker for address;
    using TreasuryHelper for address;
    using Bytes32Helper for bytes32;

    address private treasury;
    uint8 private constant PER_DENOMINATOR = 100;
    // 0.1 * 1e18 = 10% initial quitting penalization rate
    uint256 private penaltyRate = 1e17; // 100000000000000000
    address private immutable __self = address(this);
    mapping(address => uint256) private enrollmentFees;
    /// @notice Mapping to record the status of distributors.
    /// @dev Maps distributor addresses to their status.
    bytes4 private constant INTERFACE_ID_IDISTRIBUTOR =
        type(IDistributor).interfaceId;

    /// @notice Error to be thrown when a distributor contract is invalid.
    error InvalidDistributorContract();
    error InvalidPenaltyRate();
    error FailDuringEnrollment(string reason);
    error FailDuringQuit(string reason);

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// @notice This constructor prevents the implementation contract from being initialized.
    /// @dev See https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680 and https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Modifier to ensure that the given distributor contract supports the IDistributor interface.
    /// @param _distributor The distributor contract address.
    modifier validContractOnly(bytes32 _distributor) {
        address distributor = _distributor.toAddress(); // cast to address bytes32
        if (!distributor.supportsInterface(INTERFACE_ID_IDISTRIBUTOR))
            revert InvalidDistributorContract();
        _;
    }

    /// @notice Initializes the contract with the given enrollment fee and treasury address.
    /// @param initialFee The initial fee for enrollment.
    /// @param initialTreasuryAddress The initial address of the treasury.
    /// @dev This function is called only once during the contract deployment.
    function initialize(
        uint256 initialFee,
        address initialTreasuryAddress
    ) public initializer {
        __Quorum_init();
        __Governable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Treasurer_init(initialTreasuryAddress);
        __Treasury_init(initialFee, address(0));
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Function to set the penalty rate for quitting enrollment.
    /// @param newPenaltyRate The new penalty rate to be set. It should be a uint256 value representing a percentage (e.g., 100000000000000000 for 10%).
    /// @dev The penalty rate is a percentage (expressed as a uint256) that will be applied to the enrollment fee when a distributor quits.
    function setPenaltyRate(uint256 newPenaltyRate) public onlyGov {
        if (newPenaltyRate == 0) revert InvalidPenaltyRate();
        penaltyRate = newPenaltyRate;
    }

    /// @inheritdoc ITreasury
    /// @notice Sets a new treasury fee.
    /// @param newTreasuryFee The new treasury fee to be set.
    function setTreasuryFee(uint256 newTreasuryFee) public onlyGov {
        _setTreasuryFee(newTreasuryFee, address(0));
    }

    /// @notice Sets the address of the treasury.
    /// @param newTreasuryAddress The new treasury address to be set.
    /// @dev Only callable by the governance role.
    function setTreasuryAddress(address newTreasuryAddress) public onlyGov {
        _setTreasuryAddress(newTreasuryAddress);
    }

    /// @notice Collects funds from the contract and sends them to the treasury.
    /// @dev Only callable by an admin.
    function collectFunds() public onlyAdmin {
        // collect native token and send it to treasury
        address treasure = getTreasuryAddress();
        treasure.disburst(__self.balance);
    }

    /// @inheritdoc IRegistrable
    /// @notice Registers a distributor by sending a payment to the contract.
    /// @param _distributor The address of the distributor to register.
    function register(
        bytes32 _distributor
    ) public payable validContractOnly(_distributor) {
        if (msg.value < getTreasuryFee(address(0)))
            revert FailDuringEnrollment("Invalid fee amount");

        // the contract manager
        address distributor = _distributor.toAddress();
        address manager = IDistributor(distributor).getManager();
        // Attempt to send the amount to the syndication contract
        __self.deposit(msg.value);
        // Persist the enrollment payment in case the distributor quits before approval
        enrollmentFees[manager] = msg.value;
        // Set the distributor as pending approval
        _register(uint160(distributor));
    }

    /**
     * @notice Checks if the entity is active.
     * @param _distributor The distributor's address.
     * @return bool True if the entity is active, false otherwise.
     */
    function isActive(
        bytes32 _distributor
    ) public view validContractOnly(_distributor) returns (bool) {
        address distributor = _distributor.toAddress();
        return _status(uint160(distributor)) == Status.Active;
    }

    /// @inheritdoc IRegistrableRevokable
    /// @notice Allows a distributor to quit and receive a penalized refund.
    /// @param _distributor The address of the distributor to quit.
    /// @dev The function reverts if the distributor has not enrolled or if the refund fails.
    function quit(
        bytes32 _distributor
    ) public nonReentrant validContractOnly(_distributor) {
        address distributor = _distributor.toAddress();
        address manager = IDistributor(distributor).getManager(); // the contract manager
        uint256 registeredAmount = enrollmentFees[manager]; // Wei
        if (registeredAmount == 0)
            revert FailDuringQuit("Invalid distributor enrollment.");

        uint256 penal = registeredAmount.mulDiv(penaltyRate, PER_DENOMINATOR);
        (bool success, uint256 res) = registeredAmount.trySub(penal);
        if (!success) revert FailDuringQuit("Fail subtracting penalization");

        enrollmentFees[manager] = 0;
        manager.disburst(res);
        _quit(uint160(distributor));
    }

    /// @inheritdoc IRegistrableRevokable
    /// @notice Revokes the registration of a distributor.
    /// @param _distributor The address of the distributor to revoke.
    function revoke(
        bytes32 _distributor
    ) public onlyGov validContractOnly(_distributor) {
        address distributor = _distributor.toAddress();
        _revoke(uint160(distributor));
    }

    /// @inheritdoc IRegistrable
    /// @notice Approves a distributor's registration.
    /// @param _distributor The address of the distributor to approve.
    function approve(
        bytes32 _distributor
    ) public onlyGov validContractOnly(_distributor) {
        address distributor = _distributor.toAddress();
        enrollmentFees[IDistributor(distributor).getManager()] = 0;
        _approve(uint160(distributor));
    }

    /// @inheritdoc ITreasury
    /// @notice Sets a new treasury fee for a specific token.
    /// @param newTreasuryFee The new treasury fee to be set.
    /// @param token The address of the token.
    function setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) public override onlyGov {}

    /// @notice Collects funds of a specific token from the contract and sends them to the treasury.
    /// @param token The address of the token.
    /// @dev Only callable by an admin.
    function collectFunds(address token) public onlyAdmin {}
}
