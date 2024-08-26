// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "contracts/base/upgradeable/CurrencyManagerUpgradeable.sol";
import "contracts/base/upgradeable/FeesManagerUpgradeable.sol";
import "contracts/libraries/TreasuryHelper.sol";
import "contracts/libraries/FeesHelper.sol";
import "contracts/interfaces/IDistributor.sol";

/// @title Content Distributor contract.
/// @notice Use this contract to handle all needed logic for distributors.
/// @dev This contract inherits from Ownable and ERC165, and implements the IDistributor interface.
/// Extending upgradeable contracts in a non-upgradeable contract to extend ERC-7201: Namespaced Storage Layout
/// Same as below with __gap the issue could happen using this contract as implementation and receiving delegated calls.
/// This contract can be deployed without needing to upgrade.
contract Distributor is
    Initializable,
    ERC165Upgradeable,
    OwnableUpgradeable,
    FeesManagerUpgradeable,
    CurrencyManagerUpgradeable,
    IDistributor
{
    using Math for uint256;
    using TreasuryHelper for address;
    using FeesHelper for uint256;

    mapping(address => uint256) private floor;
    string private endpoint;
    uint256 flattenFactor; // To smooth or flatten the increase in fees as demand grows.

    /// @notice Event emitted when the endpoint is updated.
    /// @param oldEndpoint The old endpoint.
    /// @param newEndpoint The new endpoint.
    event EndpointUpdated(string oldEndpoint, string newEndpoint);
    /// @notice Error to be thrown when an invalid endpoint is provided.
    error InvalidEndpoint();

    /// @notice Constructor to initialize the Distributor contract.
    function initialize(
        string memory _endpoint,
        address _owner
    ) public initializer {
        __ERC165_init();
        __Ownable_init(_owner);
        __CurrencyManager_init();
        __Fees_init(0, address(0));

        if (bytes(_endpoint).length == 0) revert InvalidEndpoint();
        // balanced factors
        flattenFactor = 10;
        endpoint = _endpoint;
    }

    /// @inheritdoc IDistributor
    /// @notice Gets the manager of the distributor, which is the owner of the contract.
    /// @return The address of the manager (owner) of the contract.
    function getManager() external view returns (address) {
        return owner();
    }

    /// @inheritdoc IDistributor
    /// @notice Gets the current distribution endpoint URL.
    /// @return The endpoint URL as a string.
    function getEndpoint() external view returns (string memory) {
        return endpoint;
    }

    /// @inheritdoc IDistributor
    /// @notice Set the distribution endpoint URL.
    /// @param _endpoint The new endpoint URL to be set.
    /// @dev This function reverts if the provided endpoint is an empty string.
    /// @dev Emits an {EndpointUpdated} event.
    function setEndpoint(string calldata _endpoint) external onlyOwner {
        if (bytes(_endpoint).length == 0) revert InvalidEndpoint();
        string memory oldEndpoint = endpoint;
        endpoint = _endpoint;
        emit EndpointUpdated(oldEndpoint, _endpoint);
    }

    /// @inheritdoc IFeesManager
    /// @notice Sets a new treasury fee for a specific currency.
    /// @param newTreasuryFee The new fee expresed as base points to be set.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function setFees(
        uint256 newTreasuryFee,
        address currency
    )
        external
        onlyOwner
        onlyValidCurrency(currency)
        onlyBasePointsAllowed(newTreasuryFee)
    {
        _setFees(newTreasuryFee, currency);
        _addCurrency(currency);
    }

    /// @inheritdoc IFeesManager
    /// @notice Sets a new treasury fee for the native coin.
    /// @param newTreasuryFee The new fee expresed as base points to be set.
    function setFees(
        uint256 newTreasuryFee
    ) external onlyOwner onlyBasePointsAllowed(newTreasuryFee) {
        _setFees(newTreasuryFee, address(0));
        _addCurrency(address(0));
    }

    /// @notice Sets the scaling and flattening factors used to calculate fees.
    /// @dev This function allows the administrator to adjust how sensitive the fees are to changes in demand.
    /// @param flatten The flattening factor that controls how gradual or smooth the fee increase is.
    function setFactors(uint256 flatten) public onlyOwner {
        flattenFactor = flatten;
    }

    /// @inheritdoc IDistributor
    /// @notice Sets the minimum floor value for fees associated with a specific currency.
    /// @dev This function can only be called by the owner and for supported currencies.
    /// @param currency The address of the currency for which the floor value is being set.
    /// @param minimum The minimum fee that can be proposed for the given currency.
    function setFloor(
        address currency,
        uint256 minimum
    ) external onlyOwner onlySupportedCurrency(currency) {
        floor[currency] = minimum;
    }
    

    // flatten = flatten * (1-(1/ln(demanda))

    /// @notice Calculates an adjusted floor value based on the logarithm of custodials.
    /// @dev The function adjusts the base floor by adding a proportion
    /// that scales with the logarithm of the custodials.
    /// This ensures that the floor value increases gradually as custodials grow.
    /// @param baseFloor The initial base floor value to be adjusted.
    /// @param demand The number of custodials, which influences the adjustment.
    function _getAdjustedFloor(
        uint256 baseFloor,
        uint256 demand
    ) internal view returns (uint256) {
        if (baseFloor == 0) return 0;
        // Economies of scale.
        // Calculate the logarithm of custodials, adding 1 to avoid taking log(0)
        // fees + (fees * (log2(demand) / flatten))
        uint256 safeOp = (demand == 0 ? (demand + 1) : demand);
        return baseFloor + (baseFloor * (safeOp.log2() / flattenFactor));
    }

    /// @inheritdoc IDistributor
    /// @notice Adjusts the proposed fee amount for the distributor according to the custodial charge.
    /// @param fees The initial fee amount proposed by the distributor.
    /// @param currency The currency in which the fees are denominated.
    /// @param demand The amount of content under the distributor's custody.
    /// @return The final fee amount after adjustment, ensuring it meets or exceeds the minimum floor value.
    function negotiate(
        uint256 fees,
        address currency,
        uint256 demand
    ) external view returns (uint256) {
        uint256 bps = getFees(currency);
        uint256 proposedFees = fees.perOf(bps);
        uint256 adjustedFloor = _getAdjustedFloor(floor[currency], demand);
        return proposedFees < adjustedFloor ? adjustedFloor : proposedFees;
    }

    /// @inheritdoc IERC165
    /// @notice Checks if the contract supports a specific interface.
    /// @param interfaceId The interface identifier to check.
    /// @return True if the interface is supported, otherwise false.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IDistributor).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
