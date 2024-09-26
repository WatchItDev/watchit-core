// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IBalanceManager.sol";
import "contracts/interfaces/IBalanceWithdrawable.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/libraries/TreasuryHelper.sol";

/// @title Content Distributor Contract
/// @notice This contract handles all the necessary logic for managing content distributors.
/// @dev This contract inherits from Ownable, ERC165, and implements the IDistributor interface.
/// It also uses the TreasuryHelper library for balance and withdrawal operations.
/// This contract is designed to be used without requiring upgrades, and it follows the ERC-7201 
/// Namespaced Storage Layout for better compatibility with upgradeable contracts.
contract Distributor is
    Initializable,
    ERC165Upgradeable,
    OwnableUpgradeable,
    IBalanceWithdrawable,
    IBalanceManager,
    IDistributor
{
    using TreasuryHelper for address;

    /// @notice The distribution endpoint URL.
    string private endpoint;

    /// @notice Event emitted when the distribution endpoint is updated.
    /// @param oldEndpoint The previous endpoint before the update.
    /// @param newEndpoint The new endpoint that is set.
    event EndpointUpdated(string oldEndpoint, string newEndpoint);

    /// @notice Event emitted when a withdrawal is made.
    /// @param recipient The address that received the withdrawn tokens or native currency.
    /// @param amount The amount of tokens or native currency withdrawn.
    /// @param currency The token address (or `address(0)` for native currency) that was withdrawn.
    event FundWithdrawn(address indexed recipient, uint256 amount, address indexed currency);

    /// @notice Error thrown when an invalid (empty) endpoint is provided.
    error InvalidEndpoint();

    /// @notice Initializes the Distributor contract with the specified endpoint and owner.
    /// @param _endpoint The distribution endpoint URL.
    /// @param _owner The address of the owner who will manage the distributor.
    /// @dev Ensures that the provided endpoint is valid and initializes ERC165 and Ownable contracts.
    function initialize(
        string memory _endpoint,
        address _owner
    ) public initializer {
        if (bytes(_endpoint).length == 0) revert InvalidEndpoint();
        __ERC165_init();
        __Ownable_init(_owner);
        endpoint = _endpoint;
    }

    /// @inheritdoc IDistributor
    /// @notice Retrieves the manager (owner) of the distributor contract.
    /// @return The address of the contract owner.
    function getManager() external view returns (address) {
        return owner();
    }

    /// @inheritdoc IDistributor
    /// @notice Returns the current distribution endpoint URL.
    /// @return The endpoint URL as a string.
    function getEndpoint() external view returns (string memory) {
        return endpoint;
    }

    /// @inheritdoc IDistributor
    /// @notice Updates the distribution endpoint URL.
    /// @param _endpoint The new endpoint URL to be set.
    /// @dev Reverts if the provided endpoint is an empty string. Emits an {EndpointUpdated} event.
    function setEndpoint(string calldata _endpoint) external onlyOwner {
        if (bytes(_endpoint).length == 0) revert InvalidEndpoint();
        string memory oldEndpoint = endpoint;
        endpoint = _endpoint;
        emit EndpointUpdated(oldEndpoint, _endpoint);
    }

    /// @inheritdoc IBalanceManager
    /// @notice Retrieves the contract's balance for a given currency.
    /// @param currency The token address to check the balance of (use `address(0)` for native currency).
    /// @return The balance of the contract in the specified currency.
    /// @dev This function is restricted to the contract owner.
    function getBalance(
        address currency
    ) external view onlyOwner returns (uint256) {
        return address(this).balanceOf(currency);
    }

    /// @notice Withdraws tokens or native currency from the contract to the specified recipient.
    /// @param recipient The address that will receive the withdrawn tokens or native currency.
    /// @param amount The amount of tokens or native currency to withdraw.
    /// @param currency The address of the token to withdraw (use `address(0)` for native currency).
    /// @dev Transfers the specified amount of tokens or native currency to the recipient.
    /// Emits a {FundWithdrawn} event.
    function withdraw(
        address recipient,
        uint256 amount,
        address currency
    ) external onlyOwner {
        recipient.transfer(amount, currency);
        emit FundWithdrawn(recipient, amount, currency);
    }

    /// @inheritdoc IERC165
    /// @notice Checks if the contract supports a specific interface based on its ID.
    /// @param interfaceId The ID of the interface to check.
    /// @return True if the interface is supported, otherwise false.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IDistributor).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
