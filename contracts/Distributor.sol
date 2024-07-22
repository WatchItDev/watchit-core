// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "contracts/base/CurrencyManager.sol";
import "contracts/base/Treasury.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/IDisburser.sol";
import "contracts/libraries/TreasuryHelper.sol";

/// @title Content Distributor contract.
/// @notice Use this contract to handle all needed logic for distributors.
/// @dev This contract inherits from Ownable and ERC165, and implements the IDistributor interface.
contract Distributor is
    ERC165,
    Ownable,
    Treasury,
    CurrencyManager,
    IDistributor
{
    using TreasuryHelper for address;

    /// @notice The URL to the distribution.
    string private endpoint;

    /// @notice Event emitted when the endpoint is updated.
    /// @param oldEndpoint The old endpoint.
    /// @param newEndpoint The new endpoint.
    event EndpointUpdated(string oldEndpoint, string newEndpoint);

    /// @notice Error to be thrown when an invalid endpoint is provided.
    error InvalidEndpoint();

    /// @notice Constructor to initialize the Distributor contract.
    /// @param _endpoint The distributor's endpoint.
    constructor(string memory _endpoint) Ownable(_msgSender()) {
        endpoint = _endpoint;
    }

    /// @inheritdoc IDistributor
    /// @notice Gets the manager of the distributor, which is the owner of the contract.
    /// @return The address of the manager (owner) of the contract.
    function getManager() public view returns (address) {
        return owner();
    }

    /// @inheritdoc IDistributor
    /// @notice Gets the current distribution endpoint URL.
    /// @return The endpoint URL as a string.
    function getEndpoint() external view returns (string memory) {
        return endpoint;
    }

    /// @inheritdoc IDistributor
    /// @notice Updates the distribution endpoint URL.
    /// @param _endpoint The new endpoint URL to be set.
    /// @dev This function reverts if the provided endpoint is an empty string.
    /// @dev Emits an {EndpointUpdated} event.
    function updateEndpoint(string calldata _endpoint) external onlyOwner {
        if (bytes(_endpoint).length == 0) revert InvalidEndpoint();
        string memory oldEndpoint = endpoint;
        endpoint = _endpoint;
        emit EndpointUpdated(oldEndpoint, _endpoint);
    }

    /// @inheritdoc ITreasury
    /// @notice Sets a new treasury fee for a specific token.
    /// @param newTreasuryFee The new fee amount to be set.
    /// @param token The address of the token for which the fee is to be set.
    function setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) public onlyOwner {
        _setTreasuryFee(newTreasuryFee, token);
        _addCurrency(token);
    }

    /// @inheritdoc ITreasury
    /// @notice Sets a new treasury fee for the native token.
    /// @param newTreasuryFee The new fee amount to be set.
    function setTreasuryFee(uint256 newTreasuryFee) public onlyOwner {
        _setTreasuryFee(newTreasuryFee, address(0));
        _addCurrency(address(0));
    }

    /// @inheritdoc IDisburser
    /// @notice Withdraws the specified amount of native tokens from the contract.
    /// @param amount The amount of native tokens to withdraw.
    function withdraw(uint256 amount) public override onlyOwner {
        // withdraw native token if supported
        owner().disburst(amount);
    }

    /// @inheritdoc IDisburser
    /// @notice Withdraws the specified amount of ERC20 tokens from the contract.
    /// @param amount The amount of ERC20 tokens to withdraw.
    /// @param token The address of the ERC20 token to withdraw.
    function withdraw(uint256 amount, address token) public onlyOwner {
        owner().disburst(amount, token);
    }

    /// @inheritdoc IERC165
    /// @notice Checks if the contract supports a specific interface.
    /// @param interfaceId The interface identifier to check.
    /// @return True if the interface is supported, otherwise false.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IDistributor).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
