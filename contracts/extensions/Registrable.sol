// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../interfaces/IDistributor.sol";
import "../interfaces/IRegistrable.sol";

/**
 * @title Registrable
 * @dev Abstract contract for managing distributor registration and status.
 * Implements IRegistrable interface.
 */
abstract contract Registrable is IRegistrable {
    using ERC165Checker for address;

    /// @notice Mapping to record the status of distributors.
    /// @dev Maps distributor addresses to their status.
    mapping(IDistributor => Status) public status;
    bytes4 private constant INTERFACE_ID_IDISTRIBUTOR =
        type(IDistributor).interfaceId;

    /// @notice Error to be thrown when a distributor contract is invalid.
    error InvalidDistributorContract();
    
    /// @notice Error to be thrown when a distributor is inactive.
    error InvalidInactiveDistributor();
    
    /// @notice Error to be thrown when a distributor enrollment is invalid.
    error InvalidDistributorEnrollment();
    
    /// @notice Error to be thrown when a distributor already exists.
    error DistributorAlreadyExists();
    
    /// @notice Error to be thrown when a distributor is pending approval.
    error DistributorPendingApproval();

    /// @notice Event emitted when a distributor is registered.
    /// @param distributor The address of the registered distributor.
    event DistributorRegistered(IDistributor indexed distributor);
    
    /// @notice Event emitted when a distributor is approved.
    /// @param distributor The address of the approved distributor.
    event DistributorApproved(IDistributor indexed distributor);
    
    /// @notice Event emitted when a distributor quits.
    /// @param distributor The address of the distributor that quit.
    event DistributorQuit(IDistributor indexed distributor);

    /// @notice Modifier to ensure that the given distributor contract supports the IDistributor interface.
    /// @param distributor The distributor contract address.
    modifier validContractOnly(IDistributor distributor) {
        if (!address(distributor).supportsInterface(INTERFACE_ID_IDISTRIBUTOR))
            revert InvalidDistributorContract();
        _;
    }

    /// @notice Enum to represent the status of a distributor.
    enum Status {
        Pending,
        Waiting,
        Active,
        Blocked
    }

    /**
     * @notice Checks if the distributor is active.
     * @param distributor The distributor contract address.
     * @return bool True if the distributor is active, false otherwise.
     */
    function isActive(
        IDistributor distributor
    ) public view virtual validContractOnly(distributor) returns (bool) {
        return status[distributor] == Status.Active;
    }

    /// @notice Internal function to revoke a distributor's access.
    /// @param distributor The distributor contract address.
    function _revoke(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Active)
            revert InvalidInactiveDistributor();
        status[distributor] = Status.Blocked;
    }

    /// @notice Internal function to approve a distributor's access.
    /// @param distributor The distributor contract address.
    function _approve(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Waiting)
            revert DistributorAlreadyExists();

        status[distributor] = Status.Active; // active
        emit DistributorApproved(distributor);
    }

    /// @notice Internal function to quit a distributor's enrollment.
    /// @param distributor The distributor contract address.
    function _quit(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Waiting)
            revert InvalidDistributorEnrollment();

        status[distributor] = Status.Pending;
        emit DistributorQuit(distributor);
    }
    
    /// @notice Internal function to start a distributor's enrollment.
    /// @param distributor The distributor contract address.
    function _register(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Pending)
            revert DistributorAlreadyExists();

        status[distributor] = Status.Waiting; // pending approval
        emit DistributorRegistered(distributor);
    }
}