// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IDistributor.sol";
import "../interfaces/ITreasury.sol";

/**
 * @dev Abstract contract for managing treasury funds.
 * It inherits from Ownable and ITreasury interfaces.
 */
abstract contract Treasury is ITreasury, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Internal mapping to store fees associated with different tokens.
    /// @dev The key is the token address and the value is the fee in wei.
    mapping(address => uint256) internal tokenFees;

    /// @notice Error to be thrown when an unsupported token is used.
    /// @param token The address of the unsupported token.
    error InvalidUnsupportedToken(address token);

    /// @notice Error to be thrown when a withdrawal fails.
    /// @param reason The reason for the withdrawal failure.
    error FailDuringWithdraw(string reason);

    /// @notice Modifier to ensure only supported tokens are used.
    /// @param token The address of the token to check.
    modifier onlySupportedToken(address token) {
        // fees == 0 is default for uint256.
        // address(0) is equivalent to native token if fees > 0
        if (tokenFees[token] == 0) revert InvalidUnsupportedToken(token);
        _;
    }

    /// @inheritdoc ITreasury
    function getTreasuryFee(address token) public view override returns (uint256) {
        return tokenFees[token];
    }

    /// @notice Sets a new treasury fee.
    /// @dev Sets the fee for a specific token or native currency.
    /// @param newTreasuryFee The new treasury fee.
    /// @param token The token to associate fees, could be address 0 for native token.
    /// @notice Only the owner can call this function.
    function _setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) internal virtual onlyOwner {
        tokenFees[token] = newTreasuryFee;
    }

    /// @notice Withdraws tokens from the contract to the specified address.
    /// @dev Handles the withdrawal of native tokens and ERC20 tokens.
    /// @param amount The amount of tokens to withdraw.
    /// @param to The address to which the tokens will be sent.
    /// @param token The address of the ERC20 token to withdraw or address(0) for native token.
    /// @notice This function can only be called by the owner of the contract.
    function _withdraw(
        uint256 amount,
        address to,
        address token
    ) internal virtual {
        if (token == address(0)) {
            // Handle native coin withdrawal
            if (address(this).balance < amount)
                revert FailDuringWithdraw("Insufficient balance");
            (bool success, ) = to.call{value: amount}("");
            if (!success) revert FailDuringWithdraw("Withdraw failed");
        } else {
            // Contract transfers tokens to the specified address
            IERC20(token).safeTransfer(to, amount);
        }
    }
}