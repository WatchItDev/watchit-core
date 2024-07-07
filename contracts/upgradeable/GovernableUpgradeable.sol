// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/IGovernable.sol";

/**
 * @title Governable
 * @dev Abstract contract that provides governance functionality to upgradeable contracts.
 * It inherits from IGovernable and AccessControlUpgradeable.
 */
abstract contract GovernableUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    IGovernable
{
    address private governor;
    bytes32 private constant GOB_ROLE = keccak256("GOB_ROLE");

    /**
     * @dev Modifier that checks if the caller has the GOB_ROLE.
     */
    modifier onlyGov() {
        _checkRole(GOB_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Modifier that checks if the caller has the DEFAULT_ADMIN_ROLE.
     */
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    function __Governable_init() internal onlyInitializing {
        __Governable_init_unchained();
    }

    function __Governable_init_unchained() internal onlyInitializing {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Sets the governance address.
     * @dev Only callable by the DEFAULT_ADMIN_ROLE.
     * @param newGovernance The address to set as the new governor.
     */
    function setGovernance(address newGovernance) external virtual onlyAdmin {
        _grantRole(GOB_ROLE, newGovernance);
        governor = newGovernance;
    }

    /**
     * @notice Sets the emergency admin address.
     * @dev Only callable by the GOB_ROLE.
     * @param newEmergencyAdmin The address to set as the new emergency admin.
     */
    function setEmergencyAdmin(
        address newEmergencyAdmin
    ) external virtual onlyGov {
        _grantRole(DEFAULT_ADMIN_ROLE, newEmergencyAdmin);
    }

    /**
     * @notice Revokes the emergency admin role from the specified address.
     * @dev Only callable by the GOB_ROLE.
     * @param revokedAddress The address to revoke the emergency admin role from.
     */
    function revokeEmergencyAdmin(
        address revokedAddress
    ) external virtual onlyGov {
        _revokeRole(DEFAULT_ADMIN_ROLE, revokedAddress);
    }

    /**
     * @notice Returns the current governor address.
     * @return The address of the current governor.
     */
    function getGovernance() external view virtual override returns (address) {
        return governor;
    }
}
