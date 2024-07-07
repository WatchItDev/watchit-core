// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IDistributor.sol";

/**
 * @title IRegistrable
 * @dev Interface for managing distributors.
 */
interface IRegistrable {
    /// @notice Registers a distributor by sending a payment to the contract.
    /// @param distributor The address of the distributor to register.
    /// @dev The function reverts if the payment amount is less than the treasury fee.
    function register(IDistributor distributor) external payable;

    /// @notice Allows a distributor to quit and receive a penalized refund.
    /// @param distributor The address of the distributor to quit.
    /// @param revertTo The address to which the refund will be sent.
    /// @dev The function reverts if the distributor has not enrolled or if the refund fails.
    function quit(IDistributor distributor, address payable revertTo) external;

    /// @notice Revokes the registration of a distributor.
    /// @param distributor The address of the distributor to revoke.
    function revoke(IDistributor distributor) external;

    /// @notice Approves a distributor's registration.
    /// @param distributor The address of the distributor to approve.
    function approve(IDistributor distributor) external;
}
