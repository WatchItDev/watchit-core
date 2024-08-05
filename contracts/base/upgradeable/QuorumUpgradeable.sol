// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title QuorumUpgradeable
 * @dev Abstract contract for managing generic registration and status.
 */
abstract contract QuorumUpgradeable is Initializable {
    /// @notice Enum to represent the status of an entity.
    enum Status {
        Pending, // 0: The entity is pending approval
        Waiting, // 1: The entity is waiting for approval
        Active, // 2: The entity is active
        Blocked // 3: The entity is blocked
    }

    /// @custom:storage-location erc7201:quorumupgradeable
    struct RegistryStorage {
        mapping(uint256 => Status) _status; // Mapping to store the status of entities
    }

    // ERC-7201: Namespaced Storage Layout to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.quorum.status")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REGISTRY_SLOT =
        0x78a5d34d6f19765a8d11b74cebcafd0494288384b72923088bc4746147d1ae00;

    /// @notice Error to be thrown when an entity is inactive.
    error InvalidInactiveState();
    /// @notice Error to be thrown when an entity is already pending approval.
    error AlreadyPendingApproval();
    /// @notice Error to be thrown when an entity is not waiting for approval.
    error NotWaitingApproval();

    /**
     * @notice Initializer function for the contract.
     * @dev This function is called only once during the contract deployment.
     */
    function __Quorum_init() internal onlyInitializing {}

    /**
     * @notice Unchained initializer function for the contract.
     * @dev This function is called only once during the contract deployment.
     */
    function __Quorum_init_unchained() internal onlyInitializing {}

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
     * @notice Internal function to get the status of an entity.
     * @param entry The ID of the entity.
     * @return Status The status of the entity.
     */
    function _status(uint256 entry) internal view virtual returns (Status) {
        RegistryStorage storage $ = _getRegistryStorage();
        return $._status[entry];
    }

    /**
     * @notice Internal function to revoke an entity's approval.
     * @dev The revoke operation is expected after the entry was approved first.
     * @param entry The ID of the entity.
     */
    function _revoke(uint256 entry) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if (_status(entry) != Status.Active) revert InvalidInactiveState();
        $._status[entry] = Status.Blocked;
    }

    /**
     * @notice Internal function to approve an entity's access.
     * @param entry The ID of the entity.
     */
    function _approve(uint256 entry) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if (_status(entry) != Status.Waiting) revert NotWaitingApproval();
        $._status[entry] = Status.Active;
    }

    /**
     * @notice Internal function for an entity to resign.
     * @param entry The ID of the entity.
     */
    function _quit(uint256 entry) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if (_status(entry) != Status.Waiting) revert NotWaitingApproval();
        $._status[entry] = Status.Pending;
    }

    /**
     * @notice Internal function to start an entity's registration.
     * @param entry The ID of the entity.
     */
    function _register(uint256 entry) internal virtual {
        RegistryStorage storage $ = _getRegistryStorage();
        if (_status(entry) != Status.Pending) revert AlreadyPendingApproval();
        $._status[entry] = Status.Waiting;
    }
}
