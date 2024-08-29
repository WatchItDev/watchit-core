// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRightsCustodialManager {
    /// @notice Assigns distribution rights over the content.
    /// @dev The distributor must be active.
    /// @param contentId The ID of the content to assign.
    /// @param distributor The address of the distributor to assign the content to.
    function grantCustody(uint256 contentId, address distributor) external;

}
