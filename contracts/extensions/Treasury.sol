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
abstract contract Treasury is ITreasury {
    using SafeERC20 for IERC20;

    // Internal fee variable
    mapping(address token => uint256 fee) internal tokenFees;
    error InvalidUnsupportedToken(address);

    modifier onlySupportedToken(address token) {
        // fees == 0 is default for uint256.
        // address(0) is equivalent to native token if fees > 0
        if (tokenFees[token] == 0) revert InvalidUnsupportedToken(token);
        _;
    }

    /// @inheritdoc ITreasury
    function getTreasuryFee(address token) public view returns (uint256) {
        return tokenFees[token];
    }

    /**
     * @dev Sets a new treasury fee.
     * @param newTreasuryFee The new treasury fee.
     * @param token The token to associate fees, could be address 0 for native token
     * @notice Only the owner can call this function.
     */
    function _setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) internal virtual {
        tokenFees[token] = newTreasuryFee;
    }

    /**
     * @dev Withdraws tokens from the contract to the owner's address.
     * @param amount The amount of tokens to withdraw.
     * @param token The address of the ERC20 token to withdraw or empty to withdraw native.
     * @notice This function can only be called by the owner of the contract.
     */
    function _withdraw(
        uint256 amount,
        address to,
        address token
    ) internal virtual {
        if (token == address(0)) {
            // Handle native coin withdrawal
            require(address(this).balance >= amount, "Insufficient balance");
            (bool success, ) = to.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            // Contract transfers tokens to owner
            IERC20(token).transfer(to, amount);
        }
    }
}
