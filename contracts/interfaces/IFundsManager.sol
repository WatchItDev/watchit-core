// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IFundsManager Interface
/// @notice This interface defines the functionality for withdrawing funds from the contract to a specified address.
/// @dev This interface is intended to be implemented by contracts that need to allow secure withdrawal of funds
///      to specified recipients. The `withdraw` function should be protected to ensure that only the contract owner
///      or an authorized entity can initiate a withdrawal.
interface IFundsManager {
    /// @notice Withdraws tokens from the contract to a specified recipient's address.
    /// @param recipient The address that will receive the withdrawn tokens.
    /// @param amount The amount of tokens to withdraw.
    /// @param token The address of the ERC20 token to withdraw, or address(0) to withdraw native tokens.
    function withdraw(address recipient, uint256 amount, address token) external;
    // function getBalance
}