// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/ITreasury.sol";

/**
 * @dev Abstract contract for managing treasury funds.
 * It inherits from Initializable and ITreasury interfaces.
 */
abstract contract TreasuryUpgradeable is Initializable, ITreasury {
    /// @custom:storage-location erc7201:treasuryupgradeable
    struct TreasuryStorage {
        // one use cosa for token fee = 0 and supported = true could be the free content..
        mapping(address => uint256) _tokenFees;
        mapping(address => bool) _tokenSupported;
    }

    /// @notice Error to be thrown when an unsupported token is used.
    /// @param token The address of the unsupported token.
    error InvalidUnsupportedToken(address token);
    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.treasury.tokenfees")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TREASURY_SLOT =
        0x87da7b105ee6d8640c69f620aa1ac0a4cea27ca8bc07f4213d3776b156a65a00;

    /**
     * @notice Internal function to get the treasury storage.
     * @return $ The treasury storage.
     */
    function _getTreasuryStorage()
        private
        pure
        returns (TreasuryStorage storage $)
    {
        assembly {
            $.slot := TREASURY_SLOT
        }
    }

    /// @notice Initializes the treasury with the given initial fee and token.
    /// @param initialFee The initial fee for the treasury.
    /// @param token The address of the token.
    function __Treasury_init(
        uint256 initialFee,
        address token
    ) internal onlyInitializing {
        __Treasury_init_unchained(initialFee, token);
    }

    /// @notice Unchained initializer for the treasury with the given initial fee and token.
    /// @param initialFee The initial fee for the treasury.
    /// @param token The address of the token.
    function __Treasury_init_unchained(
        uint256 initialFee,
        address token
    ) internal onlyInitializing {
        _setTreasuryFee(initialFee, token);
    }

    /// @notice Modifier to ensure only supported tokens are used.
    /// @param token The address of the token to check.
    modifier onlySupportedToken(address token) {
        TreasuryStorage storage $ = _getTreasuryStorage();
        // fees == 0 is default for uint256.
        // address(0) is equivalent to native token if fees > 0
        if (!$._tokenSupported[token]) revert InvalidUnsupportedToken(token);
        _;
    }

    /// @inheritdoc ITreasury
    /// @notice Gets the treasury fee for the specified token.
    /// @param token The address of the token.
    /// @return The treasury fee for the specified token.
    function getTreasuryFee(
        address token
    ) public view override onlySupportedToken(token) returns (uint256) {
        TreasuryStorage storage $ = _getTreasuryStorage();
        return $._tokenFees[token];
    }

    /// @notice Sets a new treasury fee.
    /// @dev Sets the fee for a specific token or native currency.
    /// @param newTreasuryFee The new treasury fee.
    /// @param token The token to associate fees, could be address(0) for native token.
    /// @notice Only the owner can call this function.
    function _setTreasuryFee(
        uint256 newTreasuryFee,
        address token
    ) internal virtual {
        TreasuryStorage storage $ = _getTreasuryStorage();
        $._tokenFees[token] = newTreasuryFee;
        $._tokenSupported[token] = true;
    }
}
