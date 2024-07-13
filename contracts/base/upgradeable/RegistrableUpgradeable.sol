// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/IRegistrable.sol";
import "contracts/interfaces/IStatusVerifier.sol";

/**
 * @title Registrable
 * @dev Abstract contract for managing distributor registration and status.
 * Implements IRegistrable interface.
 */
abstract contract RegistrableUpgradeable is Initializable, IRegistrable, IStatusVerifier {
    using ERC165Checker for address;

    /// @notice Enum to represent the status of a distributor.
    enum Status {
        Pending, //  0
        Waiting, // 1
        Active, // 2
        Blocked // 3
    }

    /// @custom:storage-location erc7201:registrabeupgradeable.registry
    struct RegistryStorage {
        mapping(IDistributor => Status) _status;
    }

    bytes32 private constant GOB_ROLE = keccak256("GOB_ROLE");
    /// @notice Mapping to record the status of distributors.
    /// @dev Maps distributor addresses to their status.
    bytes4 private constant INTERFACE_ID_IDISTRIBUTOR =
        type(IDistributor).interfaceId;
    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.registrable.status")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REGISTRY_SLOT =
        0x78a5d34d6f19765a8d11b74cebcafd0494288384b72923088bc4746147d1ae00;

    /// @notice Error to be thrown when a distributor contract is invalid.
    error InvalidDistributorContract();
    /// @notice Error to be thrown when a distributor is inactive.
    error InvalidInactiveState();
    /// @notice Error to be thrown when a distributor is pending approval.
    error AlreadyPendingApproval();
    error NotWaitingApproval();

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

    function __Registrable_init() internal onlyInitializing {}
    function __Registrable_init_unchained() internal onlyInitializing {}

    /**
     * @notice Internal function to get the registry storage.
     * @return $ The registry storage.
     */
    function _getRegistryStorage()
        private
        pure
        returns (RegistryStorage storage $)
    {
        assembly {
            $.slot := REGISTRY_SLOT
        }
    }

    /**
     * @notice Checks if the distributor is active.
     * @param distributor The distributor contract address.
     * @return bool True if the distributor is active, false otherwise.
     */
    function isActive(
        IDistributor distributor
    ) public view returns (bool) {
        RegistryStorage storage $ = _getRegistryStorage();
        return $._status[distributor] == Status.Active;
    }

    /// @notice Internal function to revoke a distributor's access.
    /// @param distributor The distributor contract address.
    function _revoke(IDistributor distributor) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if ($._status[distributor] != Status.Active)
            revert InvalidInactiveState();
        $._status[distributor] = Status.Blocked;
    }

    /// @notice Internal function to approve a distributor's access.
    /// @param distributor The distributor contract address.
    function _approve(IDistributor distributor) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if ($._status[distributor] != Status.Waiting)
            revert NotWaitingApproval();
        $._status[distributor] = Status.Active; // active
        emit DistributorApproved(distributor);
    }

    /// @notice Internal function to quit a distributor's enrollment.
    /// @param distributor The distributor contract address.
    function _quit(IDistributor distributor) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if ($._status[distributor] != Status.Waiting)
            revert NotWaitingApproval();
        $._status[distributor] = Status.Pending;
        emit DistributorQuit(distributor);
    }

    /// @notice Internal function to start a distributor's enrollment.
    /// @param distributor The distributor contract address.
    function _register(IDistributor distributor) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if ($._status[distributor] != Status.Pending)
            revert AlreadyPendingApproval();

        $._status[distributor] = Status.Waiting; // pending approval
        emit DistributorRegistered(distributor);
    }
}
