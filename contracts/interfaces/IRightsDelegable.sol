// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsDelegable {
    /// @notice Retrieves all grantees (policies) for which rights have been delegated to a content id.
    /// @dev This function returns an array of grantees' addresses that the specified content ID
    /// has been delegated rights for.
    /// @param contentId The content ID for which rights are being delegated.
    /// @return An array of grantee addresses that have been delegated rights for the specified content ID.
    function getDelegatedRights(
        uint256 contentId
    ) external view returns (address[] memory);
}
