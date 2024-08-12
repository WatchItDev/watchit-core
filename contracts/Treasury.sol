// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/interfaces/IFeesManager.sol";
import "contracts/interfaces/IFundsManager.sol";

/// @title Treasury Contract
/// @dev This contract is designed to manage funds and token transfers,
/// and it implements upgradeable features using UUPS proxy pattern.
contract Treasury is
    Initializable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    IFundsManager
{
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

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Initializes the contract. Should be called only once.
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Governable_init();
    }

    /// @notice Withdraws tokens from the contract to a specified recipient's address.
    /// @param recipient The address that will receive the withdrawn tokens.
    /// @param amount The amount of tokens to withdraw.
    /// @param token The address of the ERC20 token to withdraw, or address(0) to withdraw native tokens.
    /// @dev This function can only be called by the owner of the contract or an authorized entity.
    function withdraw(
        address recipient,
        uint256 amount,
        address token
    ) public override onlyGov {}

    // TODO multisignature withdraw
}
