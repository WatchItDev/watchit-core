// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IFeesManager.sol";
import "contracts/libraries/MathHelper.sol";
import "contracts/libraries/Constants.sol";

/**
 * @dev Abstract contract for managing fee funds.
 * It inherits from Initializable and IFeesManager interfaces.
 */
abstract contract FeesManagerUpgradeable is Initializable, IFeesManager {
    /// @custom:storage-location erc7201:feesupgradeable
    struct FeesStorage {
        mapping(address => uint256) _tokenFees;
        mapping(address => bool) _tokenSupported;
    }

    /// @notice Error to be thrown when an unsupported token is used.
    /// @param token The address of the unsupported token.
    error InvalidUnsupportedToken(address token);
    /// @notice Error to be thrown when basis point fees are invalid.
    error InvalidBasisPointRange();
    /// @notice Error to be thrown when nominal fees are invalid.
    error InvalidNominalRange();

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.fees.tokenfees")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FEES_SLOT =
        0x87da7b105ee6d8640c69f620aa1ac0a4cea27ca8bc07f4213d3776b156a65a00;

    /**
     * @notice Internal function to get the fees storage.
     * @return $ The fees storage.
     */
    function _getFeesStorage() private pure returns (FeesStorage storage $) {
        assembly {
            $.slot := FEES_SLOT
        }
    }

    /// @notice Initializes the fees with the given initial fee and token.
    /// @param initialFee The initial fee for the fees.
    /// @param token The address of the token.
    function __Fees_init(
        uint256 initialFee,
        address token
    ) internal onlyInitializing {
        __Fees_init_unchained(initialFee, token);
    }

    /// @notice Unchained initializer for the fees with the given initial fee and token.
    /// @param initialFee The initial fee for the fees.
    /// @param token The address of the token.
    function __Fees_init_unchained(
        uint256 initialFee,
        address token
    ) internal onlyInitializing {
        _setFees(initialFee, token);
    }

    /// @notice Modifier to ensure only supported tokens are used.
    /// @param token The address of the token to check.
    modifier onlySupportedToken(address token) {
        FeesStorage storage $ = _getFeesStorage();
        // fees == 0 is default for uint256.
        // address(0) is equivalent to native token if fees > 0
        if (!$._tokenSupported[token]) revert InvalidUnsupportedToken(token);
        _;
    }

    /// @notice Modifier to ensure only valid basis points are used.
    /// @param fees The fee amount to check.
    modifier onlyBasePointsAllowed(uint256 fees) {
        // if fees < 1 = 0.01% || fees basis > 10_000 = 100%
        if (fees < 1 || fees > C.BPS_MAX)
            revert InvalidBasisPointRange();
        _;
    }

    /// @notice Modifier to ensure only valid nominal fees are used.
    /// @param fees The fee amount to check.
    modifier onlyNominalAllowed(uint256 fees) {
        // if fees < 1% || fees > 100%
        if (fees < 1 || fees > C.SCALE_FACTOR)
            revert InvalidNominalRange();
        _;
    }

    /// @notice Function to receive native coin.
    receive() external payable {}

    /// @inheritdoc IFeesManager
    /// @notice Gets the fees fee for the specified token.
    /// @dev This method could return a basis points (bps) fee or a flat fee depending on the context of use.
    /// @param token The address of the token for which to retrieve the fees fee.
    /// @return uint256 The fees fee for the specified token.
    function getFees(
        address token
    ) public view override onlySupportedToken(token) returns (uint256) {
        FeesStorage storage $ = _getFeesStorage();
        return $._tokenFees[token];
    }

    /// @notice Sets a new fees fee.
    /// @dev Sets the fee for a specific token or native currency.
    /// Depending on the context, the fee could be in basis points (bps) or a flat fee.
    /// @param fee The new fees fee to set.
    /// @param token The token to associate fees with. Use address(0) for the native token.
    /// @notice Only the owner can call this function.
    function _setFees(uint256 fee, address token) internal {
        FeesStorage storage $ = _getFeesStorage();
        $._tokenFees[token] = fee;
        $._tokenSupported[token] = true;
    }
}
