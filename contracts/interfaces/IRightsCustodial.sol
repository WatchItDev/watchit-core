// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRightsCustodial {
    /// @notice Assigns distribution rights over the content.
    /// @dev The distributor must be active.
    /// @param contentId The ID of the content to assign.
    /// @param distributor The address of the distributor to assign the content to.
    /// @param encryptedData Additional encrypted data to share access between authorized parties.
    function grantCustodial(
        uint256 contentId,
        address distributor,
        bytes calldata encryptedData
    ) external;

    /// @notice Retrieves the custodial address for the given content ID and ensures it is active.
    /// @param contentId The ID of the content.
    /// @return The address of the active custodial.
    function getCustodial(uint256 contentId) external view returns (address);
}
