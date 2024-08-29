// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsDelegable {
    /// @notice Retrieves all content IDs for which rights have been delegated to a grantee.
    /// @param grantee The address of the account or contract whose delegated rights are being queried.
    /// @return An array of content IDs that have been delegated to the specified grantee.
    function getDelegatedRights(
        address grantee
    ) external view returns (uint256[] memory);
}
