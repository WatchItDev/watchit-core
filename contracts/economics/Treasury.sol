// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity 0.8.26;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { GovernableUpgradeable } from "contracts/base/upgradeable/GovernableUpgradeable.sol";
import { IBalanceVerifiable } from "contracts/interfaces/IBalanceVerifiable.sol";
import { IBalanceWithdrawable } from "contracts/interfaces/IBalanceWithdrawable.sol";
import { IFeesManager } from "contracts/interfaces/IFeesManager.sol";

// TODO payment splitter
// https://docs.openzeppelin.com/contracts/4.x/api/finance#PaymentSplitter

/// @title Treasury Contract
/// @dev This contract is designed to manage funds and token transfers,
/// and it implements upgradeable features using UUPS proxy pattern.
contract Treasury is Initializable, UUPSUpgradeable, GovernableUpgradeable, IBalanceVerifiable, IBalanceWithdrawable {
    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// @notice This constructor prevents the implementation contract from being initialized.
    /// @dev See https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// @dev See https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Function to receive Ether. Emits an event when funds are received.
    receive() external payable {}

    /// @notice Function to get the balance of the contract (to be implemented).
    // TODO: Implement get balance function
    // TODO  multisignature withdraw
    // TODO distribution of earnings, here we can handle vesting?
    // TODO aca se llevara a cabo las quemas durante la extraccion de tokens.. cuando alguien hace withdraw se quema un % de los token

    /// @notice Initializes the contract. Should be called only once.
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Governable_init(msg.sender);
    }

    function withdraw(address recipient, uint256 amount, address currency) public onlyGov {}
    function getBalance(address currency) external view returns (uint256) {}

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}
