// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDisburser {
    /// @notice Withdraws tokens from the contract to the owner's address.
    /// @param amount The amount of tokens to withdraw.
    /// @notice This function can only be called by the owner of the contract.
    function withdraw(uint256 amount) external;

    /// @notice Withdraws tokens from the contract to the owner's address.
    /// @param amount The amount of tokens to withdraw.
    /// @param token The address of the ERC20 token to withdraw or address(0) to withdraw native tokens.
    /// @notice This function can only be called by the owner of the contract.
    function withdraw(uint256 amount, address token) external;
}
