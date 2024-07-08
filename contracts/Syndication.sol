// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./upgradeable/GovernableUpgradeable.sol";
import "./extensions/Registrable.sol";
import "./extensions/Treasury.sol";
import "./interfaces/IDistributor.sol";

/// @title Content Syndication contract.
/// @notice Use this contract to handle all distribution logic needed for creators and distributors.
/// @dev This contract uses the UUPS upgradeable pattern and AccessControl for role-based access control.
contract Syndication is
    Initializable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    ReentrancyGuard,
    Registrable,
    Treasury
{
    using Math for uint256;

    uint8 private constant PER_DENOMINATOR = 100;
    // 0.1 * 1e18 = 10% initial quiting penalization rate
    uint256 private penaltyRate = 1e17; // 100000000000000000
    address private immutable __self = address(this);
    mapping(address => uint256) private enrollmentFees;

    error InvalidPenaltyRate();
    error FailDuringEnrollment(string reason);
    error FailDuringQuit(string reason);

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// @notice This constructor prevents the implementation contract from being initialized.
    /// @dev See https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680 and https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given ownership address.
    /// @param initialFee The initial fee for enrollment.
    /// @dev This function is called only once during the contract deployment.
    function initialize(uint256 initialFee) public initializer {
        __Governable_init();
        __UUPSUpgradeable_init();
        _setTreasuryFee(initialFee, address(0));
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

    /// @inheritdoc IRegistrable
    /// @notice Registers a distributor by sending a payment to the contract.
    /// @param distributor The address of the distributor to register.
    function register(IDistributor distributor) public payable {
        if (msg.value < getTreasuryFee(address(0)))
            revert FailDuringEnrollment("Invalid fee amount");

        // the contract manager
        address manager = distributor.getManager();
        // Attempt to send the amount to the syndication contract
        _transfer(msg.value, __self, address(0));
        // Persist the enrollment payment in case the distributor quits before approval
        enrollmentFees[manager] = msg.value;
        _register(distributor); // Set the distributor as pending approval
    }

    /// @inheritdoc IRegistrable
    /// @notice Allows a distributor to quit and receive a penalized refund.
    /// @param distributor The address of the distributor to quit.
    /// @dev The function reverts if the distributor has not enrolled or if the refund fails.
    function quit(IDistributor distributor) public nonReentrant {
        address manager = distributor.getManager(); // the contract manager
        uint256 registeredAmount = enrollmentFees[manager]; // Wei
        if (registeredAmount == 0)
            revert FailDuringQuit("Invalid distributor enrollment.");

        uint256 penal = registeredAmount.mulDiv(penaltyRate, PER_DENOMINATOR);
        (bool success, uint256 res) = registeredAmount.trySub(penal);
        if (!success) revert FailDuringQuit("Fail subtracting penalization");

        enrollmentFees[manager] = 0;
        _transfer(res, manager, address(0));
        _quit(distributor);
    }

    /// @inheritdoc IRegistrable
    /// @notice Revokes the registration of a distributor.
    /// @param distributor The address of the distributor to revoke.
    function revoke(IDistributor distributor) public onlyGov {
        _revoke(distributor);
    }

    /// @inheritdoc IRegistrable
    /// @notice Approves a distributor's registration.
    /// @param distributor The address of the distributor to approve.
    function approve(IDistributor distributor) public onlyGov {
        enrollmentFees[distributor.getManager()] = 0;
        _approve(distributor);
    }

    /// @inheritdoc ITreasury
    /// @notice Withdraws a specified amount of native currency from the contract.
    /// @param amount The amount to withdraw.
    function withdraw(uint256 amount) public onlyAdmin {
        _transfer(amount, _msgSender(), address(0));
    }

    /// @inheritdoc ITreasury
    function withdraw(uint256 amount, address token) public onlyAdmin {}

    /// @inheritdoc ITreasury
    /// @notice Sets a new treasury fee for a specific token.
    /// @param newTreasuryFee The new treasury fee to be set.
    /// @param token The address of the token.
    function setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) public override onlyGov {}
}
