// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/ITreasury.sol";
import "contracts/libraries/MathHelper.sol";

/**
 * @title Treasury Contract
 * @notice This contract is responsible for managing treasury fees associated with different tokens.
 * @dev This is an abstract contract that implements the ITreasury interface.
 */
abstract contract Treasury is ITreasury {
    /// @notice Internal mapping to store fees associated with different tokens.
    /// @dev The key is the token address and the value is the fee in wei.
    mapping(address => uint256) internal tokenFees;

    /// @notice Error to be thrown when an unsupported token is used.
    /// @param token The address of the unsupported token.
    error InvalidUnsupportedToken(address token);
    /// @notice Error to be thrown when basis point fees are invalid.
    error InvalidBasisPointRange();
    /// @notice Error to be thrown when nominal fees are invalid.
    error InvalidNominalRange();

    /**
     * @notice Modifier to ensure only supported tokens are used.
     * @param token The address of the token to check.
     */
    modifier onlySupportedToken(address token) {
        // fees == 0 is default for uint256.
        // address(0) is equivalent to native token if fees > 0
        if (tokenFees[token] == 0) revert InvalidUnsupportedToken(token);
        _;
    }

    /// @notice Modifier to ensure only valid basis points are used.
    /// @param fees The fee amount to check.
    modifier onlyBasePointsAllowed(uint256 fees) {
        // if fees < 1 = 0.01% || fees basis > 10_000 = 100%
        if (fees < 1 || fees > MathHelper.BPS_MAX)
            revert InvalidBasisPointRange();
        _;
    }
    /// @notice Modifier to ensure only valid nominal fees are used.
    /// @param fees The fee amount to check.
    modifier onlyNominalAllowed(uint256 fees) {
        // if fees < 1% || fees > 100%
        if (fees < 1 || fees > MathHelper.SCALE_FACTOR)
            revert InvalidNominalRange();
        _;
    }

    /**
     * @inheritdoc ITreasury
     * @notice Gets the treasury fee for the specified token.
     * @param token The address of the token.
     * @return The treasury fee for the specified token.
     */
    function getTreasuryFee(
        address token
    ) public view override onlySupportedToken(token) returns (uint256) {
        return tokenFees[token];
    }

    /**
     * @notice Sets a new treasury fee.
     * @dev Sets the fee for a specific token or native currency.
     * @param newTreasuryFee The new treasury fee.
     * @param token The token to associate fees, could be address(0) for native token.
     */
    function _setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) internal virtual {
        tokenFees[token] = newTreasuryFee;
    }
}
