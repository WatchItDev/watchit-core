// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IReferendumRoleManager {
    /// @notice Grants the verified role to a specific account.
    /// @param account The address of the account to verify.
    function grantVerifiedRole(address account) external;

    /// @notice Revoke the verified role to a specific account.
    /// @param account The address of the account to revoke.
    function revokeVerifiedRole(address account) external;

}