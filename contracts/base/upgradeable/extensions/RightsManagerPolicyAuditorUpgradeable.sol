// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IRightsPolicyAuditor.sol";

/// @title Rights Manager Policy Auditor Upgradeable
/// @notice This abstract contract manages the approval and revocation of rights audits for policy contracts.
/// @dev The contract is upgradeable and uses namespaced storage to prevent storage layout collisions.
abstract contract RightsManagerPolicyAuditorUpgradeable is
    Initializable,
    IRightsPolicyAuditor
{
    /// @notice Error thrown when trying to operate with a not audit policy.
    /// @param policy The address of the policy.
    error InvalidNotAuditPolicy(address policy);
    /// @custom:storage-location erc7201:rightsmanagerpolicyauditornupgradeable
    /// @dev Storage struct for managing the audit status of policy contracts.
    struct AuditStorage {
        mapping(address => bool) _audited;
        mapping(address => address) _auditor;
    }

    /// @dev Namespaced storage slot for AuditStorage to avoid storage layout collisions in upgradeable contracts.
    ///      The storage slot is calculated using a combination of keccak256 hashes.
    bytes32 private constant AUDIT_SLOT =
        0x7ef71f00f90957680f6fd372df003349f79144a8d0eb04809969c1e7dc075b00;

    /// @notice Internal function to access the audit storage.
    /// @dev Uses inline assembly to assign the correct storage slot to the AuditStorage struct.
    /// @return $ The storage struct containing the audit status of policies.
    function _getAuditStorage() private pure returns (AuditStorage storage $) {
        assembly {
            $.slot := AUDIT_SLOT
        }
    }

    /// @dev Modifier to ensure that only audited policies can perform certain actions.
    /// @param policy The address of the policy contract to check for audit status.
    modifier onlyAuditedPolicy(address policy) {
        AuditStorage storage $ = _getAuditStorage();
        if (!$._audited[policy]) revert InvalidNotAuditPolicy(policy);
        _;
    }

    /// @notice Checks if a specific policy contract has been audited.
    /// @param policy The address of the policy contract to verify.
    /// @return bool Returns true if the policy is audited, false otherwise.
    function isPolicyAudited(address policy) public view returns (bool) {
        AuditStorage storage $ = _getAuditStorage();
        return $._audited[policy];
    }

    /// @notice Approves the audit of a given policy by a specified auditor.
    /// @param policy The address of the policy to be audited.
    /// @param auditor The address of the auditor performing the audit.
    function _approveAudit(address policy, address auditor) internal {
        AuditStorage storage $ = _getAuditStorage();
        $._audited[policy] = true;
        $._auditor[policy] = auditor;
    }

    /// @notice Revokes the audit of a given policy by a specified auditor.
    /// @param policy The address of the policy whose audit is to be revoked.
    /// @param auditor The address of the auditor who performed the audit.
    function _revokeAudit(address policy, address auditor) internal {
        AuditStorage storage $ = _getAuditStorage();
        $._audited[policy] = false;
        $._auditor[policy] = auditor;
    }
}
