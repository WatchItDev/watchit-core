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
        mapping(address => uint256) _currencyFees;
        mapping(address => bool) _currencySupported;
    }

    /// @notice Error to be thrown when an unsupported currency is used.
    /// @param currency The address of the unsupported currency.
    error InvalidUnsupportedCurrency(address currency);
    /// @notice Error to be thrown when basis point fees are invalid.
    error InvalidBasisPointRange();
    /// @notice Error to be thrown when nominal fees are invalid.
    error InvalidNominalRange();

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.fees.currencyfees")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FEES_SLOT =
         0x5575547e2bbff3f801051e8dc7ed5ba1cab8b335003bad8f456347ac015ff600;

    /**
     * @notice Internal function to get the fees storage.
     * @return $ The fees storage.
     */
    function _getFeesStorage() private pure returns (FeesStorage storage $) {
        assembly {
            $.slot := FEES_SLOT
        }
    }

    /// @notice Initializes the fees with the given initial fee and currency.
    /// @param initialFee The initial fee for the fees.
    /// @param currency The address of the currency.
    function __Fees_init(
        uint256 initialFee,
        address currency
    ) internal onlyInitializing {
        __Fees_init_unchained(initialFee, currency);
    }

    /// @notice Unchained initializer for the fees with the given initial fee and currency.
    /// @param initialFee The initial fee for the fees.
    /// @param currency The address of the currency.
    function __Fees_init_unchained(
        uint256 initialFee,
        address currency
    ) internal onlyInitializing {
        _setFees(initialFee, currency);
    }

    /// @notice Modifier to ensure only supported currency are used.
    /// @param currency The address of the currency to check.
    modifier onlySupportedCurrency(address currency) {
        FeesStorage storage $ = _getFeesStorage();
        if (!$._currencySupported[currency]) revert InvalidUnsupportedCurrency(currency);
        _;
    }

    /// @notice Modifier to ensure only valid basis points are used.
    /// @param fees The fee amount to check.
    modifier onlyBasePointsAllowed(uint256 fees) {
        // fees basis > 10_000 = 100%
        if (fees > C.BPS_MAX)
            revert InvalidBasisPointRange();
        _;
    }

    /// @notice Modifier to ensure only valid nominal fees are used.
    /// @param fees The fee amount to check.
    modifier onlyNominalAllowed(uint256 fees) {
        // fees > 100%
        if (fees > C.SCALE_FACTOR)
            revert InvalidNominalRange();
        _;
    }

    /// @notice Function to receive native coin.
    receive() external payable {}

    /// @inheritdoc IFeesManager
    /// @notice Gets the fees fee for the specified currency.
    /// @dev This method could return a basis points (bps) fee or a flat fee depending on the context of use.
    /// @param currency The address of the currency for which to retrieve the fees fee.
    /// @return uint256 The fees fee for the specified currency.
    function getFees(
        address currency
    ) public view override onlySupportedCurrency(currency) returns (uint256) {
        FeesStorage storage $ = _getFeesStorage();
        return $._currencyFees[currency];
    }

    /// @notice Sets a new fees fee.
    /// @dev Sets the fee for a specific currency or native currency.
    /// Depending on the context, the fee could be in basis points (bps) or a flat fee.
    /// @param fee The new fees fee to set.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    /// @notice Only the owner can call this function.
    function _setFees(uint256 fee, address currency) internal {
        FeesStorage storage $ = _getFeesStorage();
        $._currencyFees[currency] = fee;
        $._currencySupported[currency] = true;
    }
}
