// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TreasuryHelper {
    using SafeERC20 for IERC20;

    /// @notice Error to be thrown when a withdrawal fails.
    /// @param reason The reason for the withdrawal failure.
    error FailDuringTransfer(string reason);

    /// @notice Handles the transfer of native cryptocurrency.
    /// @param to The address to which the native cryptocurrency will be transferred.
    /// @param amount The amount of native cryptocurrency to transfer.
    function _native(address to, uint256 amount) internal {
        // Handle native coin transfer
        (bool success, ) = payable(to).call{value: amount}("");
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

    /// @notice Deposits ERC20 tokens to the specified address using SafeERC20 transferFrom method.
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
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    /// @notice Disburses native cryptocurrency from the contract to the specified address.
    /// @param to The address to which the native cryptocurrency will be disbursed.
    /// @param amount The amount of native cryptocurrency to disburse.
    function disburst(address to, uint256 amount) internal {
        if (address(this).balance < amount)
            revert FailDuringTransfer("Insufficient balance");
        _native(to, amount);
    }

    /// @notice Disburses ERC20 tokens from the contract to the specified address.
    /// @dev Handles the withdrawal of native tokens and ERC20 tokens.
    /// @param to The address to which the tokens will be sent.
    /// @param amount The amount of tokens to withdraw.
    /// @param token The address of the ERC20 token to withdraw or address(0) for native token.
    function disburst(address to, uint256 amount, address token) internal {
        if (IERC20(token).balanceOf(address(this)) < amount)
            revert FailDuringTransfer("Insufficient balance");
        // Contract transfers tokens to the specified address
        _erc20(token, to, amount);
    }
}
