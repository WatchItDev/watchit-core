// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TreasuryHelper
/// @notice Library to assist with treasury operations, including transfers and deposits of native cryptocurrency and ERC20 tokens.
library TreasuryHelper {
    // Using OpenZeppelin's SafeERC20 library for safe ERC20 transfers
    using SafeERC20 for IERC20;

    /// @notice Error to be thrown when a transfer fails.
    /// @param reason The reason for the transfer failure.
    error FailDuringTransfer(string reason);

    /// @notice Handles the transfer of native cryptocurrency.
    /// @param to The address to which the native cryptocurrency will be transferred.
    /// @param amount The amount of native cryptocurrency to transfer.
    function _native(address to, uint256 amount) internal {
        // Handle native coin transfer
        (bool success, ) = payable(to).call{value: amount}("");
        // Revert the transaction if the transfer fails
        if (!success) revert FailDuringTransfer("Transfer failed");
    }

    /// @notice Handles the transfer of ERC20 tokens.
    /// @param token The address of the ERC20 token to transfer.
    /// @param to The address to which the ERC20 tokens will be transferred.
    /// @param amount The amount of ERC20 tokens to transfer.
    function _erc20(address token, address to, uint256 amount) internal {
        // Contract transfers tokens to the specified address
        IERC20(token).transfer(to, amount);
    }

    /// @notice Deposits native cryptocurrency to the specified address.
    /// @param to The address to which the native cryptocurrency will be deposited.
    /// @param amount The amount of native cryptocurrency to deposit.
    function deposit(address to, uint256 amount) internal {
        _native(to, amount);
    }

    /// @notice Deposits ERC20 tokens to the specified address.
    /// @param to The address to which the ERC20 tokens will be deposited.
    /// @param amount The amount of ERC20 tokens to deposit.
    /// @param token The address of the ERC20 token to deposit.
    function deposit(address to, uint256 amount, address token) internal {
        _erc20(token, to, amount);
    }

    /// @notice Deposits ERC20 tokens to the specified address using SafeERC20's safeTransferFrom method.
    /// @dev This function ensures that the transfer is executed safely, handling any potential reverts.
    /// @param from The address from which the ERC20 tokens will be transferred.
    /// @param to The address to which the ERC20 tokens will be deposited.
    /// @param amount The amount of ERC20 tokens to deposit.
    /// @param token The address of the ERC20 token to deposit.
    function safeDeposit(
        address from,
        address to,
        uint256 amount,
        address token
    ) internal {
        // Use SafeERC20's safeTransferFrom to securely transfer tokens
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    /// @notice Returns the balance of the specified ERC20 token held by the target address.
    /// @param target The address to check the balance for.
    /// @param token The address of the ERC20 token.
    /// @return uint256 The balance of the ERC20 token at the target address.
    function balanceOf(
        address target,
        address token
    ) internal view returns (uint256) {
        return IERC20(token).balanceOf(target);
    }

    /// @notice Returns the balance of native cryptocurrency held by the target address.
    /// @param target The address to check the balance for.
    /// @return uint256 The balance of native cryptocurrency at the target address.
    function balanceOf(address target) internal view returns (uint256) {
        return target.balance;
    }

    /// @notice Disburses native cryptocurrency from the contract to the specified address.
    /// @param to The address to which the native cryptocurrency will be disbursed.
    /// @param amount The amount of native cryptocurrency to disburse.
    function disburst(address to, uint256 amount) internal {
        // Check if the contract has enough balance to disburse
        if (balanceOf(address(this)) < amount)
            revert FailDuringTransfer("Insufficient balance");
        _native(to, amount);
    }

    /// @notice Disburses ERC20 tokens from the contract to the specified address.
    /// @dev Handles the withdrawal of native tokens and ERC20 tokens.
    /// @param to The address to which the tokens will be sent.
    /// @param amount The amount of tokens to withdraw.
    /// @param token The address of the ERC20 token to withdraw or address(0) for native token.
    function disburst(address to, uint256 amount, address token) internal {
        // Check if the contract has enough token balance to disburse
        if (balanceOf(address(this), token) < amount)
            revert FailDuringTransfer("Insufficient balance");
        // Contract transfers tokens to the specified address
        _erc20(token, to, amount);
    }
}
