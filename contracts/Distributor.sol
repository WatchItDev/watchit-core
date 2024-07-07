// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IDistributor.sol";
import "./extensions/Treasury.sol";

/// @title Content Distributor contract.
/// @notice Use this contract to handle all needed logic for distributors.
/// @dev This contract inherits from Ownable and ERC165, and implements the IDistributor interface.
contract Distributor is Ownable, Treasury, ERC165, IDistributor {
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
    function getEndpoint() external view returns (string memory) {
        return endpoint;
    }

    /// @inheritdoc IDistributor
    function updateEndpoint(string calldata _endpoint) external onlyOwner {
        if (bytes(_endpoint).length == 0) revert InvalidEndpoint();
        string memory oldEndpoint = endpoint;
        endpoint = _endpoint;
        emit EndpointUpdated(oldEndpoint, _endpoint);
    }

    /// @inheritdoc ITreasury
    function setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) public onlyOwner {
        _setTreasuryFee(newTreasuryFee, token);
    }

    /// @inheritdoc ITreasury
    function setTreasuryFee(uint256 newTreasuryFee) public onlyOwner {
        _setTreasuryFee(newTreasuryFee, address(0));
    }

    /// @inheritdoc ITreasury
    function withdraw(uint256 amount) public override onlyOwner {
        // withdraw native token if supported
        _withdraw(amount, owner(), address(0));
    }

    /// @inheritdoc ITreasury
    function withdraw(
        uint256 amount,
        address token
    ) public onlyOwner onlySupportedToken(token) {
        _withdraw(amount, owner(), token);
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IDistributor).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
