// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRightsPolicyAuditor
/// @notice Interface for auditing and revoking audits for policy controllers.
/// @dev This interface allows external contracts to approve or revoke the audit status of a specific policy.
interface IRightsPolicyAuditor {

    /// @notice Checks if a specific policy contract has been audited.
    /// @param policy The address of the policy contract to verify.
    /// @return bool Returns true if the policy is audited, false otherwise.
    function isPolicyAudited(address policy) external view returns (bool);

    /// @notice Approves the audit of a given policy.
    /// @param policy The address of the policy to be audited.
    /// @dev Important fact is that each policy should not be upgradeable.
    function approveAudit(address policy) external;

    /// @notice Revokes the audit of a given policy.
    /// @param policy The address of the policy whose audit is to be revoked.
    function revokeAudit(address policy) external;
}
