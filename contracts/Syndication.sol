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
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given ownership address.
    /// @dev This function is called only once during the contract deployment.
    function initialize(uint256 initialFee) public initializer {
        __Governable_init();
        __UUPSUpgradeable_init();
        // what's the initial cost for enrollment?
        _setTreasuryFee(initialFee, address(0));
    }

    /// @notice Function that should revert when msg sender is not authorized to upgrade the contract.
    /// @dev see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Function to set the penalty rate for quitting enrollment.
    /// @dev The penalty rate is a percentage (expressed as a uint256) that will be applied to the enrollment fee when a distributor quits.
    /// @param newPenaltyRate The new penalty rate to be set. It should be a uint256 value representing a percentage (e.g., 100000000000000000 for 10%).
    function setPenaltyRate(uint256 newPenaltyRate) public onlyGov {
        if (newPenaltyRate == 0) revert InvalidPenaltyRate();
        penaltyRate = newPenaltyRate;
    }

    /// @inheritdoc IRegistrable
    function register(IDistributor distributor) public payable {
        if (msg.value < getTreasuryFee(address(0)))
            revert FailDuringEnrollment("Invalid fee amount");

        // attempt send the amount to syndication contract
        (bool sent, ) = payable(__self).call{value: msg.value}("");
        if (!sent) revert FailDuringEnrollment("Fail sending payment");

        // persist the enrollment payment in case that distributor quits to enrollment
        enrollmentFees[address(distributor)] = msg.value;
        _register(distributor); // set the distributor as pending approval
    }

    /// @inheritdoc IRegistrable
    function quit(
        IDistributor distributor,
        address payable revertTo
    ) public nonReentrant {
        uint256 registeredAmount = enrollmentFees[address(distributor)]; // wei
        if (registeredAmount == 0)
            revert FailDuringQuit("No enrolled distributor.");

        uint256 penal = registeredAmount.mulDiv(penaltyRate, PER_DENOMINATOR);
        (bool success, uint256 res) = registeredAmount.trySub(penal);
        if (!success) revert FailDuringQuit("Fail subtracting penalization");

        enrollmentFees[address(distributor)] = 0;
        (bool sent, ) = revertTo.call{value: res}("");
        if (!sent) revert FailDuringQuit("Fail reverting payment");
        _quit(distributor);
    }

    /// @inheritdoc IRegistrable
    function revoke(IDistributor distributor) public onlyGov {
        _revoke(distributor);
    }

    /// @inheritdoc IRegistrable
    function approve(IDistributor distributor) public onlyGov {
        enrollmentFees[address(distributor)] = 0;
        _approve(distributor);
    }

    /// @inheritdoc ITreasury
    function setTreasuryFee(uint256 newTreasuryFee) public onlyGov {
        _setTreasuryFee(newTreasuryFee, address(0));
    }

    /// @inheritdoc ITreasury
    function withdraw(uint256 amount) public onlyAdmin {
        _withdraw(amount, _msgSender(), address(0));
    }

    /// @inheritdoc ITreasury
    function setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) public override onlyGov {}

    /// @inheritdoc ITreasury
    // https://docs.soliditylang.org/en/v0.4.21/contracts.html#function-overloading
    function withdraw(
        uint256 amount,
        address token
    ) external override onlyGov {}
}
