// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRegistrableRevokable
/// @dev Interface for managing entities' registration status, including quitting and revoking.
interface IRegistrableRevokable {
    /// @notice Allows an entity to quit and receive a penalized refund.
    function quit(address) external;
    /// @notice Revokes the registration of an entity.
    function revoke(address) external;
}
