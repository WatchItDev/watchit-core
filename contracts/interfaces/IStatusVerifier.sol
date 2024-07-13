// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IDistributor.sol";

interface IStatusVerifier {
    /// @notice Registers a distributor by sending a payment to the contract.
    /// @param distributor The address of the distributor to register.
    /// @dev The function reverts if the payment amount is less than the treasury fee.
    function isActive(IDistributor distributor) external view returns (bool);
}
