// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IDistributor.sol";

/// @title Content Distributor contract.
/// @notice Use this contract to handle all needed logic for distributors.
/// @dev This contract inherits from Ownable and ERC165, and implements the IDistributor interface.
contract Distributor is Ownable, ERC165, IDistributor {
    using SafeERC20 for IERC20;

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

    /// @notice Function to retrieve the endpoint of the distributor.
    /// @dev This function allows users to view the current endpoint of the distributor.
    /// @return The current endpoint of the distributor.
    function getEndpoint() external view returns (string memory) {
        return endpoint;
    }

    /// @notice Updates the endpoint of the current distributor.
    /// @dev This function can only be called by the owner of the contract.
    /// @param _endpoint The new distributor's endpoint.
    function updateEndpoint(string calldata _endpoint) external onlyOwner {
        if (bytes(_endpoint).length == 0) revert InvalidEndpoint();
        string memory oldEndpoint = endpoint;
        endpoint = _endpoint;
        emit EndpointUpdated(oldEndpoint, _endpoint);
    }

    /// @notice Withdraws tokens from the contract to the owner's address.
    /// @dev This function can only be called by the owner of the contract.
    /// @param token The address of the ERC20 token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(
        address token,
        uint256 amount
    ) external onlyOwner {
        // contract transfer tokens to owner
        IERC20(token).transfer(owner(), amount);
    }

    /// @notice Checks if the contract supports a given interface.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return True if the contract supports the given interface, false otherwise.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IDistributor).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
