// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/constants/Types.sol";

interface IRightsAccessController {
    /// @notice Grants access to a specific watcher for a certain content ID for a given timeframe.
    /// @param account The address of the watcher.
    /// @param contentId The content ID to grant access to.
    /// @param condition The conditional function to validate access.
    function grantAccess(
        address account,
        uint256 contentId,
        T.AccessCondition calldata condition
    ) external;

    /// @notice Checks if access is allowed for a specific watcher and content.
    /// @param account The address of the watcher.
    /// @param contentId The content ID to check access.
    /// @return True if access is allowed, false otherwise.
    function hasAccess(
        address account,
        uint256 contentId
    ) external returns (bool);
}
