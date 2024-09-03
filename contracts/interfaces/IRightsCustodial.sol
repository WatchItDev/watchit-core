// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRightsCustodial {
    /// @notice Retrieves the custodial address for a given content holder.
    /// @param holder The address of the content rights holder whose custodial address is being retrieved.
    /// @return The address of the active custodian responsible for the content associated with the specified holder.
    function getCustody(address holder) external view returns (address);

    /// @notice Retrieves the total number of content items in custody for a given distributor.
    /// @param distributor The address of the distributor whose custodial content count is being requested.
    /// @return The total number of content items that the specified distributor currently has in custody.
    function getCustodyCount(address distributor) external returns (uint256);

    /// @notice Retrieves the custody records associated with a specific distributor.
    /// @param distributor The address of the distributor whose custody records are to be retrieved.
    /// @return An array of addresses representing the custody records associated with the given distributor.
    function getCustodyRegistry(
        address distributor
    ) external view returns (address[] memory);
}
