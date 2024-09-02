// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "./IFeesManager.sol";
import "./ICurrencyManager.sol";
import "./IFundsManager.sol";

interface IDistributor is IFeesManager, ICurrencyManager, IFundsManager {
    /// @notice Set the endpoint of the distributor.
    /// @dev This function can only be called by the owner of the contract.
    /// @param _endpoint The new distributor's endpoint.
    function setEndpoint(string memory _endpoint) external;

    /// @notice Sets the minimum floor value for fees associated with a specific currency.
    /// @param currency The address of the token for which the floor value is being set.
    /// @param minimum The minimum fee that can be proposed for the given currency.
    function setFloor(address currency, uint256 minimum) external;

    /// @notice Sets the scaling and flattening factors used to calculate fees.
    /// @dev This function allows the administrator to adjust how sensitive the fees are to changes in demand.
    /// @param flatten The flattening factor that controls how gradual or smooth the fee increase is.
    function setFactors(uint256 flatten) external;

    /// @notice Retrieves the endpoint of the distributor.
    /// @dev This function allows users to view the current endpoint of the distributor.
    /// @return The current endpoint of the distributor.
    function getEndpoint() external view returns (string memory);

    /// @notice Retrieves the manager of the distributor.
    /// @dev This function allows users to view the current manager of the distributor.
    /// @return The address of the current manager of the distributor.
    function getManager() external view returns (address);

    /// @notice Proposes a fee to the distributor by adjusting it according to a predefined floor value.
    /// @param fees The initial fee amount proposed.
    /// @param currency The currency in which the fees are proposed.
    /// @param demand The amount of content under the distributor's custody.
    /// @return acceptedFees The final fee amount after adjustment, ensuring it meets the floor value.
    function negotiate(
        uint256 fees,
        address currency,
        uint256 demand
    ) external view returns (uint256);
}
