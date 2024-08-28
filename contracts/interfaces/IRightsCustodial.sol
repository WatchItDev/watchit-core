// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRightsCustodial {
    /// @notice Assigns distribution rights over the content.
    /// @dev The distributor must be active.
    /// @param contentId The ID of the content to assign.
    /// @param distributor The address of the distributor to assign the content to.
    function grantCustody(
        uint256 contentId,
        address distributor,
    ) external;

    /// @notice Retrieves the custodial address for the given content ID and ensures it is active.
    /// @param contentId The ID of the content.
    /// @return The address of the active custodial.
    function getCustody(uint256 contentId) external view returns (address);

    /// @notice Retrieves the total number of content items in custody for a given distributor.
    /// @dev This function accesses the CustodyStorage to fetch the count of content associated with the specified distributor.
    /// @param distributor The address of the distributor whose custodial content count is being requested.
    /// @return The total number of content items that the specified distributor currently has in custody.
    function getCustodyCount(address distributor) external returns (uint256);

    /// @notice Retrieves the custody records associated with a specific distributor.
    /// @param distributor The address of the distributor whose custody records are to be retrieved.
    /// @return An array of unsigned integers representing the custody records associated with the given distributor.
    function getCustodyRegistry(
        address distributor
    ) external view returns (uint256[] memory);
}
