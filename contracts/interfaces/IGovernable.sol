// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html

/**
 * @title IGovernable
 * @dev Interface for managing governance and emergency admin functionalities.
 */
interface IGovernable {
    /// @notice Sets the privileged governance role.
    /// @custom:permissions Governance.
    /// @param newGovernance The new governance address to set.
    function setGovernance(address newGovernance) external;

    /// @notice Sets the emergency admin, which is a permissioned role able to set the protocol state.
    /// @custom:permissions Governance.
    /// @param newEmergencyAdmin The new emergency admin address to set.
    function setEmergencyAdmin(address newEmergencyAdmin) external;

    /// @notice Returns the currently configured governance address.
    /// @return address The address of the currently configured governance.
    function getGovernance() external view returns (address);

    /// @notice Revokes the emergency admin role from a specified address.
    /// @custom:permissions Governance.
    /// @param revokedAddress The address to revoke the emergency admin role from.
    function revokeEmergencyAdmin(address revokedAddress) external;
}