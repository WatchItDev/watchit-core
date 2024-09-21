// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRegistrableRevokable
/// @dev Interface for managing entities' registration status, including quitting and revoking.
interface IRegistrableRevokable {
    /// @notice Allows an entity to quit and receive a penalized refund.
    /// @param distributor The address of the distributor to quit.
    /// @param currency The currency used to pay enrollment.
    function quit(address distributor, address currency) external;

    /// @notice Revokes the registration of an entity.
    /// @param distributor The address of the distributor to revoke.
    function revoke(address distributor) external;
}
