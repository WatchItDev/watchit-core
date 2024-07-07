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

    // mapping to record distributor state address:active.
    mapping(IDistributor => Status) public status;
    bytes4 private constant INTERFACE_ID_IDISTRIBUTOR =
        type(IDistributor).interfaceId;

    // Error definitions
    error InvalidDistributorContract();
    error InvalidInactiveDistributor();
    error InvalidDistributorEnrollment();
    error DistributorAlreadyExists();
    error DistributorPendingApproval();

    // Event definitions
    event DistributorRegistered(IDistributor indexed distributor);
    event DistributorApproved(IDistributor indexed distributor);
    event DistributorQuit(IDistributor indexed distributor);

    // Modifier to ensure that the given distributor contract supports the IDistributor interface.
    modifier validContractOnly(IDistributor distributor) {
        if (!address(distributor).supportsInterface(INTERFACE_ID_IDISTRIBUTOR))
            revert InvalidDistributorContract();
        _;
    }

    // Default value is the first element listed in definition of the type...
    enum Status {
        Pending,
        Waiting,
        Active,
        Blocked
    }

    /**
     * @notice Checks if the distributor is active.
     * @param distributor The distributor contract address.
     * @return bool true if distributor is active, false otherwise.
     */
    function isActive(
        IDistributor distributor
    ) public view virtual validContractOnly(distributor) returns (bool) {
        return status[distributor] == Status.Active;
    }

    // Internal function to revoke distributor's access.
    function _revoke(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Active)
            revert InvalidInactiveDistributor();
        status[distributor] = Status.Blocked;
    }

    // Internal function to approve distributor's access.
    function _approve(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Waiting)
            revert DistributorAlreadyExists();

        status[distributor] = Status.Active; // active
        emit DistributorRegistered(distributor);
    }

    // Internal function to quit distributor's enrollment.
    function _quit(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Waiting)
            revert InvalidDistributorEnrollment();

        status[distributor] = Status.Pending;
        emit DistributorQuit(distributor);
    }
    
    // Internal function to start distributor's enrollment.
    function _register(
        IDistributor distributor
    ) internal virtual validContractOnly(distributor) {
        if (status[distributor] != Status.Pending)
            revert DistributorAlreadyExists();

        status[distributor] = Status.Waiting; // pending approval
        emit DistributorRegistered(distributor);
    }
}
